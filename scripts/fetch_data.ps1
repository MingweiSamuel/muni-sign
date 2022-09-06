$FOLDER = 'sfmta_gtfs'
$DATE = Get-Date -UFormat '%Y%m%d'

If (-Not (Test-Path $FOLDER)) {
    Write-Host 'Downloading SFMTA GTFS zip.'
    Invoke-WebRequest 'https://gtfs.sfmta.com/transitdata/google_transit.zip' -OutFile 'sfmta_gtfs.zip'
    Expand-Archive 'sfmta_gtfs.zip' -DestinationPath $FOLDER
}
Else {
    Write-Host 'SFMTA GTFS folder already exists, not downloading.'
}

# stop_times excluding last stop for a trip.
$STOP_TIMES_NON_LAST = @"
    SELECT
        *
    FROM
        "$FOLDER/stop_times.txt"
    JOIN (
        SELECT
            trip_id,
            MAX(stop_sequence) AS stop_sequence_max
        FROM
            "$FOLDER/stop_times.txt"
        GROUP BY
            trip_id
    ) USING (trip_id)
    WHERE
        stop_sequence < stop_sequence_max
"@

# Operating times but also grouped by headsign.
# stop_id, route_id, direction_id, service_id, trip_headsign => start_time, end_time
$OPERATING_TIMES_HEADSIGNS = @"
    SELECT
        stop_id,
        route_id,
        direction_id,
        service_id,
        TRIM(trip_headsign) as trip_headsign,

        MIN(departure_time) AS start_time,
        MAX(departure_time) AS end_time

    FROM "$FOLDER/stop_times.txt"
    JOIN "$FOLDER/trips.txt" USING (trip_id)
    GROUP BY
        stop_id, route_id, direction_id, service_id, TRIM(trip_headsign)
    ORDER BY
        stop_id, route_id, direction_id, service_id, TRIM(trip_headsign)
"@
# stop_id, route_id, direction_id, service_id => trip_headsigns, start_time, end_time
$OPERATING_TIMES = @"
    SELECT
        stop_id,
        route_id,
        direction_id,
        service_id,

        GROUP_CONCAT(trip_headsign, '###') AS trip_headsigns,
        start_time,
        end_time

    FROM ($OPERATING_TIMES_HEADSIGNS)
    GROUP BY
        stop_id, route_id, direction_id, service_id
    ORDER BY
        stop_id, route_id, direction_id, service_id
"@
# q -H '-d,' -O -C read $OPERATING_TIMES

# Average headways/frequencies (times between busses).
# stop_id, route_id, direction_id, service_id => is_day, is_owl, avg_headway
$HEADWAYS = @"
    SELECT
        stop_id,
        route_id,
        direction_id,
        service_id,

        is_day,
        is_owl,

        AVG(0
            +   60 * CAST(SUBSTR(departure_time, 1, 2) AS REAL)
            +    1 * CAST(SUBSTR(departure_time, 4, 2) AS REAL)
            + 1/60 * CAST(SUBSTR(departure_time, 7, 2) AS REAL)
            -   60 * CAST(SUBSTR(prev_departure_time, 1, 2) AS REAL)
            -    1 * CAST(SUBSTR(prev_departure_time, 4, 2) AS REAL)
            - 1/60 * CAST(SUBSTR(prev_departure_time, 7, 2) AS REAL)
        ) AS avg_headway

    FROM (
        SELECT
            *,
            LAG(departure_time, 1, NULL) OVER (
                PARTITION BY stop_id, route_id, direction_id, is_day, is_owl, service_id
                ORDER BY departure_time
            ) prev_departure_time
        FROM (
            SELECT
                *,
                departure_time BETWEEN '09:00:00' AND '16:00:00' AS is_day,
                departure_time BETWEEN '26:00:00' AND '48:00:00' AS is_owl
            FROM ($STOP_TIMES_NON_LAST)
            JOIN "$FOLDER/trips.txt" USING (trip_id)
        )
    )
    GROUP BY
        stop_id, route_id, direction_id, service_id, is_day, is_owl
    ORDER BY
        stop_id, route_id, direction_id, service_id, is_day, is_owl
"@
# q -H '-d,' -O -C read $HEADWAYS

# Stop temporal info (operating time range AND headway frequency).
# stop_id, route_id =>
#   start_time, end_time,
#   day_headway, owl_headway
#   mon, tue, wed, thu, fri, sat, sun
$STOP_TEMPORALITIES = @"
    SELECT
        stop_id,
        route_id,
        direction_id,

        trip_headsigns,

        MAX(start_time) AS start_time,
        MIN(end_time) AS end_time,

        MAX(CASE WHEN is_day THEN avg_headway END) AS day_headway,
        MAX(CASE WHEN is_owl THEN avg_headway END) AS owl_headway,
        MIN(CASE WHEN is_day THEN avg_headway END) AS day_headway_min,
        MIN(CASE WHEN is_owl THEN avg_headway END) AS owl_headway_min,

        MAX(monday) AS mon, MAX(tuesday) AS tue, MAX(wednesday) AS wed, MAX(thursday) AS thu, MAX(friday) AS fri,
        MAX(saturday) AS sat, MAX(sunday) AS sun

    FROM ($OPERATING_TIMES)
    JOIN ($HEADWAYS) USING (stop_id, route_id, direction_id, service_id)
    JOIN "$FOLDER/calendar.txt" USING (service_id)
    WHERE
        $DATE BETWEEN start_date AND end_date
    GROUP BY
        stop_id, route_id, direction_id
    ORDER BY
        stop_id, route_id, direction_id
"@
# q -H '-d,' -O -C read $STOP_TEMPORALITIES

$STOP_ALL_DATA = @"
    SELECT
        TRIM(stop_code) AS stop_code,
        TRIM(stop_name) AS stop_name,

        TRIM(route_short_name) AS route_short_name,
        TRIM(route_long_name) AS route_long_name,
        route_type,
        TRIM(route_color) AS route_color,
        TRIM(route_text_color) AS route_text_color,

        direction_id,
        trip_headsigns,

        start_time,
        end_time,

        day_headway,
        owl_headway,
        day_headway_min,
        owl_headway_min,

        mon, tue, wed, thu, fri, sat, sun

    FROM ($STOP_TEMPORALITIES)
    JOIN "$FOLDER/stops.txt" USING (stop_id)
    JOIN "$FOLDER/routes.txt" USING (route_id)
    ORDER BY
        stop_code, route_short_name, direction_id
"@
# q -H '-d,' -O -C read $STOP_ALL_DATA

q -H '-d,' -O -C read $STOP_ALL_DATA | Out-File 'public/data/stop_times.csv'
