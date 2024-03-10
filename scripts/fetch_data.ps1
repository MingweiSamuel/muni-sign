$FOLDER = 'sfmta_gtfs'

If (-Not (Test-Path $FOLDER)) {
    Write-Host 'Downloading SFMTA GTFS zip.'

    if ($null -Eq $env:_511_KEY) {
        $env:_511_KEY = Get-Content 511.key -Raw
    }

    Invoke-WebRequest "https://api.511.org/transit/datafeeds?operator_id=SF&api_key=$env:_511_KEY" -OutFile 'sfmta_gtfs.zip'
    Expand-Archive 'sfmta_gtfs.zip' -DestinationPath $FOLDER
}
Else {
    Write-Host 'SFMTA GTFS folder already exists, not downloading.'
}

# Find the closest calendar range in case they upload one early.
# Actually finds the top three, one for weekdays, one for Saturday, and one for Sunday.
$DATE = Get-Date -UFormat '%Y%m%d'
$CALENDAR_CLOSEST = @"
    SELECT *
    FROM $FOLDER/calendar.txt
    ORDER BY
        MAX(start_date - $DATE, $DATE - end_date) ASC
    LIMIT 3
"@
# q -H '-d,' -O -C read $CALENDAR_CLOSEST

# `departure_time`s with leading zero for AM times.
$STOP_TIMES_FIXED = @"
    SELECT
        trip_id,
        stop_id,
        stop_sequence,
        SUBSTR('0' || departure_time, -8) AS departure_time
    FROM $FOLDER/stop_times.txt
"@
q -H '-d,' -O -C read $STOP_TIMES_FIXED | Out-File $FOLDER/stop_times_fixed.txt

# stop_times excluding last stop for a trip.
$STOP_TIMES_NON_LAST = @"
    SELECT
        *
    FROM
        $FOLDER/stop_times_fixed.txt
    JOIN (
        SELECT
            trip_id,
            MAX(stop_sequence) AS stop_sequence_max
        FROM
            $FOLDER/stop_times_fixed.txt
        GROUP BY
            trip_id
    ) USING (trip_id)
    WHERE
        stop_sequence < stop_sequence_max
"@
# q -H '-d,' -O -C read $STOP_TIMES_NON_LAST

# stop_id, route_id, direction_id, service_id => start_time, end_time
$OPERATING_TIMES = @"
    SELECT
        stop_id,
        route_id,
        direction_id,
        service_id,

        MIN(departure_time) AS start_time,
        MAX(departure_time) AS end_time

    FROM $FOLDER/stop_times_fixed.txt
    JOIN $FOLDER/trips.txt USING (trip_id)
    GROUP BY
        stop_id, route_id, direction_id, service_id
    ORDER BY
        stop_id, route_id, direction_id, service_id
"@
# q -H '-d,' -O -C read $OPERATING_TIMES

# EVERY service_id, route_id, direction_id, trip_id, eol_stop_name
$TRIP_EOLS = @"
    SELECT
        service_id,
        route_id,
        direction_id,
        trip_id,
        stop_name AS eol_stop_name

    FROM $FOLDER/stop_times_fixed.txt
    JOIN (
        SELECT
            trip_id,
            MAX(stop_sequence) AS stop_sequence
        FROM $FOLDER/stop_times_fixed.txt
        GROUP BY
            trip_id
    ) USING (trip_id, stop_sequence)
    JOIN $FOLDER/trips.txt USING (trip_id)
    JOIN $FOLDER/routes.txt USING (route_id)
    JOIN $FOLDER/stops.txt USING (stop_id)
    ORDER BY
        trip_id,
        route_id, direction_id, service_id, eol_stop_name
"@
# q -H '-d,' -O -C read $TRIP_EOLS

# stop_id, route_id, direction_id, eol_stop_name => count_all, count_day, count_owl
# FILTER calendar service_id early so we can aggregate the dictionary.
$STOP_EOLS = @"
    SELECT
        stop_id,
        route_id,
        direction_id,
        eol_stop_name,

        COUNT(*) AS count_all,
        COUNT(
            CASE WHEN departure_time BETWEEN '09:00:00' AND '16:00:00' THEN 1 END
        ) AS count_day,
        COUNT(
            CASE WHEN departure_time BETWEEN '26:00:00' AND '48:00:00' THEN 1 END
        ) AS count_owl


    FROM $FOLDER/stops.txt
    JOIN $FOLDER/stop_times_fixed.txt USING (stop_id)
    JOIN ($TRIP_EOLS) USING (trip_id)
    JOIN ($CALENDAR_CLOSEST) USING (service_id)

    GROUP BY
        stop_id, route_id, direction_id, eol_stop_name
    ORDER BY
        stop_id, route_id, direction_id, eol_stop_name
"@
# q -H '-d,' -O -C read $STOP_EOLS

# stop_id, route_id, direction_id => eol_stop_names_all/day/owl (dicts)
$STOP_EOLS_FLAT = @"
    SELECT
        stop_id,
        route_id,
        direction_id,

        GROUP_CONCAT(
            CASE WHEN 0 < count_all THEN
                eol_stop_name || '@@@' || count_all
            END,
            '###'
        ) AS eol_stop_names_all,
        GROUP_CONCAT(
            CASE WHEN 0 < count_day THEN
                eol_stop_name || '@@@' || count_day
            END,
            '###'
        ) AS eol_stop_names_day,
        GROUP_CONCAT(
            CASE WHEN 0 < count_owl THEN
                eol_stop_name || '@@@' || count_owl
            END,
            '###'
        ) AS eol_stop_names_owl

    FROM ($STOP_EOLS)
    GROUP BY
        stop_id, route_id, direction_id
    ORDER BY
        stop_id, route_id, direction_id
"@
# q -H '-d,' -O -C read $STOP_EOLS_FLAT

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
            JOIN $FOLDER/trips.txt USING (trip_id)
        )
    )
    GROUP BY
        stop_id, route_id, direction_id, service_id, is_day, is_owl
    ORDER BY
        stop_id, route_id, direction_id, service_id, is_day, is_owl
"@
# q -H '-d,' -O -C read $HEADWAYS

# Stop temporal info (operating time range AND headway frequency).
# stop_id, route_id, direction_id =>
#   eol_stop_names_all, eol_stop_names_day, eol_stop_names_owl
#   start_time, end_time,
#   day_headway, owl_headway
#   day_headway_min, owl_headway_min
#   mon, tue, wed, thu, fri, sat, sun
$STOP_TEMPORALITIES = @"
    SELECT
        stop_id,
        route_id,
        direction_id,

        eol_stop_names_all,
        eol_stop_names_day,
        eol_stop_names_owl,

        MAX(start_time) AS start_time,
        MIN(end_time) AS end_time,

        MAX(CASE WHEN is_day THEN avg_headway END) AS day_headway,
        MAX(CASE WHEN is_owl THEN avg_headway END) AS owl_headway,
        MIN(CASE WHEN is_day THEN avg_headway END) AS day_headway_min,
        MIN(CASE WHEN is_owl THEN avg_headway END) AS owl_headway_min,

        MAX(monday) AS mon, MAX(tuesday) AS tue, MAX(wednesday) AS wed, MAX(thursday) AS thu, MAX(friday) AS fri,
        MAX(saturday) AS sat, MAX(sunday) AS sun

    FROM ($OPERATING_TIMES)
    JOIN ($STOP_EOLS_FLAT) USING (stop_id, route_id, direction_id)
    JOIN ($HEADWAYS) USING (stop_id, route_id, direction_id, service_id)
    JOIN ($CALENDAR_CLOSEST) USING (service_id)

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

        eol_stop_names_all,
        eol_stop_names_day,
        eol_stop_names_owl,

        start_time,
        end_time,

        day_headway,
        owl_headway,
        day_headway_min,
        owl_headway_min,

        mon, tue, wed, thu, fri, sat, sun

    FROM ($STOP_TEMPORALITIES)
    JOIN $FOLDER/stops.txt USING (stop_id)
    JOIN $FOLDER/routes.txt USING (route_id)
    ORDER BY
        stop_code, route_short_name, direction_id
"@
# q -H '-d,' -O -C read $STOP_ALL_DATA

q -H '-d,' -O -C read $STOP_ALL_DATA | Out-File 'public/data/stop_times.csv'
