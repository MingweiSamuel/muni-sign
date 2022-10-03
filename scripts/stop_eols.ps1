$FOLDER = 'sfmta_gtfs'

# EVERY service_id, route_id, direction_id, trip_id, eol_stop_name
$TRIP_EOLS = @"
    SELECT
        service_id,
        route_id,
        direction_id,
        trip_id,
        stop_name AS eol_stop_name

    FROM "$FOLDER/stop_times.txt"
    JOIN (
        SELECT
            trip_id,
            MAX(stop_sequence) AS stop_sequence
        FROM "$FOLDER/stop_times.txt"
        GROUP BY
            trip_id
    ) USING (trip_id, stop_sequence)
    JOIN "$FOLDER/trips.txt" USING (trip_id)
    JOIN "$FOLDER/routes.txt" USING (route_id)
    JOIN "$FOLDER/stops.txt" USING (stop_id)
    ORDER BY
        trip_id,
        route_id, direction_id, service_id, eol_stop_name
"@
# q -H '-d,' -O -C read $TRIP_EOLS

# stop_id, route_id, direction_id, service_id, eol_stop_name => count_all, count_day, count_owl
$STOP_EOLS = @"
    SELECT
        stop_id,
        route_id,
        direction_id,
        service_id,
        eol_stop_name,

        COUNT(*) AS count_all,
        COUNT(
            CASE WHEN departure_time BETWEEN '09:00:00' AND '16:00:00' THEN 1 END
        ) AS count_day,
        COUNT(
            CASE WHEN departure_time BETWEEN '26:00:00' AND '48:00:00' THEN 1 END
        ) AS count_owl


    FROM "$FOLDER/stops.txt"
    JOIN "$FOLDER/stop_times.txt" USING (stop_id)
    JOIN ($TRIP_EOLS) USING (trip_id)

    GROUP BY
        stop_id, route_id, direction_id, service_id, eol_stop_name
    ORDER BY
        stop_id, route_id, direction_id, service_id, eol_stop_name
"@
# q -H '-d,' -O -C read $STOP_EOLS

# stop_id, route_id, direction_id, service_id => eol_stop_names_all/day/owl (dicts)
$STOP_EOLS_FLAT = @"
    SELECT
        stop_id,
        route_id,
        direction_id,
        service_id,

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
        stop_id, route_id, direction_id, service_id
    ORDER BY
        stop_id, route_id, direction_id, service_id
"@
q -H '-d,' -O -C read $STOP_EOLS_FLAT
