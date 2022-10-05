$FOLDER = 'sfmta_gtfs'
$DATE = Get-Date -UFormat '%Y%m%d'

# q -H '-d,' -O -C read @"
#     SELECT
#         stop_code,
#         route_id,
#         direction_id
#     FROM "$FOLDER/stop_times.txt" st
#     JOIN "$FOLDER/stops.txt" USING (stop_id)
#     JOIN "$FOLDER/trips.txt" USING (trip_id)
#     JOIN "$FOLDER/routes.txt" USING (route_id)
#     JOIN "$FOLDER/calendar.txt" USING (service_id)
#     WHERE
#         start_date <= $DATE AND $DATE <= end_date
#         AND stop_code = 13161

#     GROUP BY stop_code, route_id, direction_id
#     ORDER BY stop_code, route_id, direction_id
# "@

q -H '-d,' -O -C read @"
    SELECT
        stop_code,
        COUNT(*) n
    FROM (
        SELECT
            stop_code,
            route_id,
            direction_id
        FROM "$FOLDER/stop_times.txt" st
        JOIN "$FOLDER/stops.txt" USING (stop_id)
        JOIN "$FOLDER/trips.txt" USING (trip_id)
        JOIN "$FOLDER/routes.txt" USING (route_id)
        JOIN "$FOLDER/calendar.txt" USING (service_id)
        WHERE
            start_date <= $DATE AND $DATE <= end_date

        GROUP BY stop_code, route_id, direction_id
        ORDER BY stop_code, route_id, direction_id
    )
    GROUP BY stop_code
    ORDER BY COUNT(*) DESC
"@
