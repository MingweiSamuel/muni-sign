$FOLDER = 'sfmta_gtfs'
$DATE = Get-Date -UFormat '%Y%m%d'

$NON_LAST_STOPS = @"
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
# q -H '-d,' -O -C read $NON_LAST_STOPS

$BIDI_STOPS = @"
    SELECT
        stop_code,
        stop_name,
        route_short_name,
        route_long_name,
        route_text_color,
        route_color,

        trip_id,
        direction_id,
        trip_headsign,

        departure_time,
        MAX(monday) mon, MAX(tuesday) tue, MAX(wednesday) wed, MAX(thursday) thu, MAX(friday) fri, MAX(saturday) sat, MAX(sunday) sun,

        MAX(t.direction_id) AS direction_id_max,
        MIN(t.direction_id) AS direction_id_min
    FROM ($NON_LAST_STOPS) st
    JOIN "$FOLDER/stops.txt" s USING (stop_id)
    JOIN "$FOLDER/trips.txt" t USING (trip_id)
    JOIN "$FOLDER/routes.txt" r USING (route_id)
    JOIN "$FOLDER/calendar.txt" c USING (service_id)
    WHERE
        c.start_date <= $DATE AND $DATE <= c.end_date
    GROUP BY
        stop_id, route_id, service_id
    HAVING
        direction_id_max <> direction_id_min
    ORDER BY
        stop_id
"@
q -H '-d,' -O -C read $BIDI_STOPS
