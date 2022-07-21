function parseCsv(csvText: string): string[][] {
    const CELL_REGEX = /(,|\r?\n|^)("((?:[^"]|"")+)"|[^,\r\n]*)/g;

    csvText = csvText.trim();

    const grid = [];
    let row = null;

    let match;
    while ((match = CELL_REGEX.exec(csvText))) {
        const sep = match[1];
        const val = match[3] ? match[3].replace(/""/g, '"') : match[2];

        // Handle newlines (new rows).
        if (',' !== sep) grid.push((row = []));

        row.push(val);
    }

    return grid;
}

function getLineTime(line: RawStopTime): string {
    let daysOfWeek = line.mon + line.tue + line.wed + line.thu + line.fri + line.sat + line.sun;
    switch (daysOfWeek) {
        case '1111111':
            daysOfWeek = 'Daily';
            break;
        case '1111100':
            daysOfWeek = 'Weekdays';
            break;
        case '0000011':
            daysOfWeek = 'Weekends';
            break;
        default:
            console.warn('UNKNOWN DAYS OF WEEK ' + daysOfWeek);
            break;
    }

    const [sh, sm, _ss] = parseTime(line.start_time);
    const [eh, em, _es] = parseTime(line.end_time);

    if (23 <= eh - sh) {
        return `24 Hours ${daysOfWeek}`;
    }
    if (line.start_time === line.end_time) {
        return `${daysOfWeek} ~ ${roundTime(sh, sm, 5)} only`;
    }
    else {
        return `${daysOfWeek} ~ ${roundTime(sh, sm)}-${roundTime(eh, em)}`;
    }
}

function parseTime(time: string): [number, number, number] {
    return time.split(':').map(Number) as any;
}

function roundTime(h: number, m: number, res = 15, fn = Math.floor): string {
    m = res * fn(m / res);
    if (60 <= m) {
        m -= 60;
        h += 1;
    }

    let suf = (1 <= (h / 12) % 2) ? 'pm' : 'am';
    h = (h - 1) % 12 + 1;

    if (12 === h && 0 === m) {
        suf = {
            'pm': ' noon',
            'am': ' midnight',
        }[suf];
    }

    const M = 0 === m ? '' : ':' + `${m}`.padStart(2, '0');
    return `${h}${M}${suf}`;
}

type RawStopTime = {
    stop_code: string,
    stop_name: string,
    route_short_name: string,
    route_long_name: string,
    direction_id: '0' | '1',
    trip_headsign: string,
    route_text_color: string,
    route_color: string,
    start_time: string,
    end_time: string,
    mon: '0' | '1', tue: '0' | '1', wed: '0' | '1', thu: '0' | '1', fri: '0' | '1', sat: '0' | '1', sun: '0' | '1',
};

const STOP_TIMES = (async () => {
    const response = await fetch('data/stop_times.csv');
    const bodyText = await response.text();
    const [header, ...rows] = parseCsv(bodyText);

    const data: Record<string, RawStopTime[]> = {};
    for (const row of rows) {
        const rowObj = Object.fromEntries(row.map((x, i) => [header[i], x])) as RawStopTime;
        (data[rowObj.stop_code] || (data[rowObj.stop_code] = [])).push(rowObj);
    }

    // Sort each stop's list of lines.
    for (const list of Object.values(data)) {
        list.sort((a, b) => {
            return (parseInt(a.route_short_name) - parseInt(b.route_short_name))
                || (-a.route_short_name.localeCompare(b.route_short_name))
                || ((COLOR_ORDER['#' + a.route_color] || 0) - (COLOR_ORDER['#' + b.route_color] || 0));
        });
    }

    return data;
})();

const CONTROL_LOCS: Promise<Record<string, { inbound: string, outbound: string }>> = (async () => {
    const response = await fetch('data/control_locs.json');
    const json = await response.json();
    return json;
})();


export type StopTimes = {
    stopId: string;
    stopLoc: string;
    lines: StopLine[];
    hasRapid: boolean;
};
export type StopLine = {
    lineNum: string;
    lineMod: string;
    lineName: string;
    lineDest0: string;
    lineDest1: any;
    lineTime: string;
    lineTextColor: string;
    lineColor: string;
    isRapid: boolean;
    isOwl: boolean;
};

export async function randomStopId(): Promise<string> {
    const stops = await STOP_TIMES;
    const keys = Object.keys(stops);
    return keys[0 | (Math.random() * keys.length)];
}

// Strips the trailing 'St, Rd' suffix unless the street is numbered.
function stripStreetSuffix(street: string): string {
    if (/\D/.test(street[0])) {
        const supper = street.toUpperCase();
        // Do not strip CT do to ambiguities.
        if (supper.endsWith(' ST') || supper.endsWith(' RD') || supper.endsWith(' DR')) {
            street = street.slice(0, -3);
        }
        else if (supper.endsWith(' AVE') || supper.endsWith(' WAY') || supper.endsWith(' TER')) {
            street = street.slice(0, -4);
        }
        else if (supper.endsWith(' BLVD')) {
            street = street.slice(0, -5);
        }
        else if (supper.endsWith(' STREET') || supper.endsWith(' AVENUE')) {
            street = street.slice(0, -7)
        }
    }
    return street;
}

export async function getStopTimes(stopId: string): Promise<StopTimes> {
    const stops = await STOP_TIMES;
    const controlLocs = await CONTROL_LOCS;

    const stopLines = stops[stopId];
    if (null == stopLines) throw Error('Stop not found: ' + stopId);

    let stopLoc = stopLines[0].stop_name;
    if (stopLoc.includes(' & ')) {
        let [a, b] = stopLoc.split(' & ', 2);
        a = stripStreetSuffix(a);
        b = stripStreetSuffix(b);
        stopLoc = `${a} & ${b}`;
    }

    const lines = stopLines.map(line => {
        let lineNum = line.route_short_name;
        let lineMod = '';
        const match = lineNum.match(/^(\d+)([A-Za-z]+)$/);
        if (match) {
            ([lineNum, lineMod] = match.slice(1));
        }
        else {
            lineNum = lineNum.replace(/(BUS|-OWL)$/, '');
        }

        // Some basic cleanup for lineDest0/1
        let lineDest0 = line.trip_headsign;
        let lineDest1 = controlLocs[line.route_short_name][+line.direction_id];
        // Ensure neither line is subset of (or equal to) other.
        if (lineDest0.includes(lineDest1)) {
            lineDest1 = '';
        }
        else if (lineDest1.includes(lineDest0)) {
            lineDest0 = lineDest1;
            lineDest1 = '';
        }

        const lineTextColor = '#' + line.route_text_color;
        const lineColor = '#' + line.route_color;
        return {
            lineNum,
            lineMod,
            lineName: line.route_long_name, // TODO: fix capitalization?
            lineDest0,
            lineDest1,
            lineTime: getLineTime(line),

            lineTextColor,
            lineColor,

            isRapid: COLOR_RAPID === lineColor,
            isOwl: COLOR_OWL === lineColor,
        };
    });
    const hasRapid = lines.some(line => line.isRapid);

    return { stopId, stopLoc, lines, hasRapid };
}

export const COLOR_RAPID = '#BF2B45';
export const COLOR_STD = '#005B95';
export const COLOR_OWL = '#666666';

const COLOR_ORDER = {
    [COLOR_RAPID]: -100,
    [COLOR_STD]: 100,
    [COLOR_OWL]: 200,
};
