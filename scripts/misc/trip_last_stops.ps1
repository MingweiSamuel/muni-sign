$FOLDER = 'sfmta_gtfs'
$DATE = Get-Date -UFormat '%Y%m%d'

$STOP_TIMES_LAST = @"
    SELECT
        *
    FROM "$FOLDER/stop_times.txt"
    JOIN (
        SELECT
            trip_id,
            MAX(stop_sequence) AS stop_sequence
        FROM "$FOLDER/stop_times.txt"
        GROUP BY
            trip_id
    ) USING (trip_id, stop_sequence)
"@

$LINE_ENDS = @"
    SELECT
        route_id,
        stop_id,

        service_id,
        direction_id,

        COUNT(*) AS num_trips

    FROM ($STOP_TIMES_LAST)
    JOIN "$FOLDER/trips.txt" USING (trip_id)
    GROUP BY
        route_id, stop_id
"@

$EOL_DATA = @"
    SELECT
        route_short_name,
        direction_id,
        num_trips,

        stop_code,
        stop_name

    FROM ($LINE_ENDS)
    JOIN "$FOLDER/stops.txt" USING (stop_id)
    JOIN "$FOLDER/routes.txt" USING (route_id)
    JOIN "$FOLDER/calendar.txt" USING (service_id)
    WHERE
        start_date <= $DATE AND $DATE <= end_date
    ORDER BY
        route_short_name,
        direction_id,
        num_trips DESC
"@

q -H '-d,' -O -C read $EOL_DATA
