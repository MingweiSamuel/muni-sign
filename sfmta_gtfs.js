import fs from 'node:fs';
import { Transform } from 'node:stream';

import fetch from 'node-fetch'; // Used so `response.body` is a `node:stream.Readable`.
import unzip from 'unzip-stream';
import * as csv from 'csv-parse';

async function main() {
    const response = await fetch('https://gtfs.sfmta.com/transitdata/google_transit.zip');

    // This should really be a SQL join but... oh well.
    const stopId2StopCode = {};
    const stopCode2Name = {};

    const stopId2TimeTop = {};
    const stopId2TimeBot = {};

    await response.body
        .pipe(unzip.Parse())
        .forEach(async entry => {
            console.log(`${entry.type}: ${entry.path} ${entry.size}`);
            if ('File' !== entry.type) {
                entry.autodrain();
            }
            else if ('stops.txt' === entry.path) {
                // stop_lat,stop_code,stop_lon,stop_url,stop_id,stop_desc,stop_name,location_type,zone_id
                // 37.792357,14026,-122.42101,https://SFMTA.com/14026,4026,,Clay St & Polk St,0,
                let header = null;
                await entry
                    .pipe(csv.parse())
                    .filter(row => !(null == header && (header = row)))
                    .map(row => Object.fromEntries(row.map((x, i) => [header[i], x])))
                    .forEach(row => {
                        stopId2StopCode[row.stop_id] = row.stop_code;
                        stopCode2Name[row.stop_code] = row.stop_name;
                    });
            }
            else if ('trips.txt' === entry.path) {
                // block_id,bikes_allowed,route_id,wheelchair_accessible,direction_id,trip_headsign,shape_id,service_id,trip_id
                // a_4408,1,18658,1,0,Bayview District - Hudson & Newhall,202418,2_merged_11035752,11000705
                entry.autodrain();
            }
            else if ('stop_times.txt' === entry.path) {
                // trip_id,arrival_time,departure_time,stop_id,stop_sequence,stop_headsign,pickup_type,drop_off_type,shape_dist_traveled,timepoint
                // 11000705,07:48:00,07:48:00,7844,1,,,,,
                let header = null;
                await entry
                    .pipe(csv.parse())
                    .filter(row => !(null == header && (header = row)))
                    .filter(() => Math.random() < 0.000005)
                    .map(row => Object.fromEntries(row.map((x, i) => [header[i], x])))
                    .forEach(row => {
                        console.log(row);
                        stopId2TimeTop[row.stop_id] = row.departure_time;
                        stopId2TimeBot[row.stop_id] = row.departure_time;
                    });
                console.log(header);
            }
            else {
                entry.autodrain();
            }
        });
}

main().catch(console.error);
