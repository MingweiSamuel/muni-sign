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

q -H '-d,' -O -C read @"
    SELECT
        stop_code,
        stop_name,
        route_short_name,
        route_long_name,
        trip_headsign,
        route_id,
        MAX(start) start,
        MIN(end) end,
        MAX(monday) mon, MAX(tuesday) tue, MAX(wednesday) wed, MAX(thursday) thu, MAX(friday) fri, MAX(saturday) sat, MAX(sunday) sun
    FROM (
        SELECT
            s.stop_code,
            s.stop_name,
            r.route_short_name,
            r.route_long_name,
            r.route_id,
            t.trip_headsign,
            t.route_id,
            MIN(st.departure_time) AS start,
            MAX(st.departure_time) AS end,
            c.monday, c.tuesday, c.wednesday, c.thursday, c.friday, c.saturday, c.sunday
        FROM "$FOLDER/stop_times.txt" st
        JOIN "$FOLDER/stops.txt" s ON st.stop_id = s.stop_id
        JOIN "$FOLDER/trips.txt" t ON st.trip_id = t.trip_id
        JOIN "$FOLDER/routes.txt" r ON t.route_id = r.route_id
        JOIN "$FOLDER/calendar.txt" c on t.service_id = c.service_id
        WHERE
            c.start_date <= $DATE AND $DATE <= c.end_date
        GROUP BY st.stop_id, t.route_id, c.service_id
    )
    GROUP BY stop_code, route_id
    ORDER BY stop_code
"@ | Out-File 'public/stop_times.csv'

# q -H '-d,' -C read @"
#     SELECT
#         s.stop_code,
#         s.stop_name,
#         r.route_short_name,
#         r.route_long_name,
#         t.trip_headsign,
#         t.route_id,
#         st.departure_time,
#         c.monday, c.tuesday, c.wednesday, c.thursday, c.friday, c.saturday, c.sunday
#     FROM "$FOLDER/stop_times.txt" st
#     JOIN "$FOLDER/stops.txt" s ON st.stop_id = s.stop_id
#     JOIN "$FOLDER/trips.txt" t ON st.trip_id = t.trip_id
#     JOIN "$FOLDER/routes.txt" r ON t.route_id = r.route_id
#     JOIN "$FOLDER/calendar.txt" c on t.service_id = c.service_id
#     WHERE
#         c.start_date <= $DATE AND $DATE <= c.end_date
#         AND '5' = r.route_short_name
#         AND 14732 = s.stop_code
#         AND c.monday
#     ORDER BY st.departure_time
# "@ | Out-File '5.csv'

# q -H '-d,' -C read @"
#     SELECT
#         s.stop_code,
#         s.stop_name,
#         r.route_short_name,
#         r.route_long_name,
#         t.trip_headsign,
#         t.route_id,
#         MIN(st.departure_time),
#         MAX(st.departure_time),
#         c.monday, c.tuesday, c.wednesday, c.thursday, c.friday, c.saturday, c.sunday
#     FROM "$FOLDER/stop_times.txt" st
#     JOIN "$FOLDER/stops.txt" s ON st.stop_id = s.stop_id
#     JOIN "$FOLDER/trips.txt" t ON st.trip_id = t.trip_id
#     JOIN "$FOLDER/routes.txt" r ON t.route_id = r.route_id
#     JOIN "$FOLDER/calendar.txt" c on t.service_id = c.service_id
#     WHERE
#         c.start_date <= $DATE AND $DATE <= c.end_date
#     GROUP BY st.stop_id, t.route_id, c.service_id
#     ORDER BY s.stop_code
# "@ | Out-File 'public/stops.csv'

