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


# TODO: exclude line if it is the last stop?
q -H '-d,' -O -C read @"
    SELECT
        stop_code,
        stop_name,
        route_short_name,
        route_long_name,
        direction_id,
        trip_headsign,
        route_text_color,
        route_color,
        MAX(dt_min) start_time,
        MIN(dt_max) end_time,
        MAX(monday) mon, MAX(tuesday) tue, MAX(wednesday) wed, MAX(thursday) thu, MAX(friday) fri, MAX(saturday) sat, MAX(sunday) sun
    FROM (
        SELECT
            *,
            MIN(st.departure_time) AS dt_min,
            MAX(st.departure_time) AS dt_max
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
"@ | Out-File 'public/data/stop_times.csv'

node 'control_locs.js'
