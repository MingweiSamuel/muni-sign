function parseCsv(csvText: string): string[][] {
    const CELL_REGEX = /(,|\r?\n|^)("((?:[^"]|"")+)"|[^,\r\n]*)/g;

    csvText = csvText.trim();

    const grid = [];
    let row = null;

    let match: null | RegExpExecArray;
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

    if (line.start_time === line.end_time) {
        // Implies only one bus on some days. But maybe more than one on other days.
        return `${daysOfWeek} ~\u2009${roundTime(sh, sm, 5)}`;
    }

    // console.log([line.day_headway_min, line.day_headway, line.owl_headway_min, line.owl_headway].join(','));

    let hours: string;
    if (23 <= eh - sh) {
        hours = `24 Hours ${daysOfWeek}`;
    }
    else {
        hours = `${daysOfWeek} ~\u2009${roundTime(sh, sm)}-${roundTime(eh, em)}`;
    }

    let headway = '';
    if (line.day_headway || line.owl_headway) {
        headway = `, Every ~\u2009${Math.round(0.2 + Number(line.day_headway || line.owl_headway))}m`;
        if (line.day_headway && line.owl_headway) {
            headway += ` (Owl ${Math.round(0.15 + Number(line.owl_headway))}m)`;
        }
    }

    return hours + headway;
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

/// https://developers.google.com/transit/gtfs/reference#routestxt
export enum RouteType {
    /// 0 - Tram, Streetcar, Light rail. Any light rail or street level system within a metropolitan area.
    LightRail = 0,
    /// 1 - Subway, Metro. Any underground rail system within a metropolitan area.
    Subway = 1,
    /// 2 - Rail. Used for intercity or long-distance travel.
    Rail = 2,
    /// 3 - Bus. Used for short- and long-distance bus routes.
    Bus = 3,
    /// 4 - Ferry. Used for short- and long-distance boat service.
    Ferry = 4,
    /// 5 - Cable tram. Used for street-level rail cars where the cable runs beneath the vehicle, e.g., cable car in San Francisco.
    CableCar = 5,
    /// 6 - Aerial lift, suspended cable car (e.g., gondola lift, aerial tramway). Cable transport where cabins, cars, gondolas or open chairs are suspended by means of one or more cables.
    Aerial = 6,
    /// 7 - Funicular. Any rail system designed for steep inclines.
    Funicular = 7,
    /// 11 - Trolleybus. Electric buses that draw power from overhead wires using poles.
    Trolleybus = 11,
    /// 12 - Monorail. Railway in which the track consists of a single rail or a beam.
    Monorail = 12,
}

type RawStopTime = {
    stop_code: string,
    stop_name: string,

    route_short_name: string,
    route_long_name: string,
    route_type: string,
    route_color: string,
    route_text_color: string,

    direction_id: '0' | '1',
    trip_headsign: string,

    start_time: `${number}:${number}:${number}`,
    end_time: `${number}:${number}:${number}`,

    day_headway: `${number}`,
    owl_headway: `${number}`,
    day_headway_min: `${number}`,
    owl_headway_min: `${number}`,

    mon: '0' | '1', tue: '0' | '1', wed: '0' | '1', thu: '0' | '1', fri: '0' | '1', sat: '0' | '1', sun: '0' | '1',
};

const STOP_TIMES = (async () => {
    const response = await fetch('data/stop_times.csv');
    const bodyText = await response.text();
    const [header, ...rows] = parseCsv(bodyText);

    const data: Record<string, RawStopTime[]> = {};
    for (const row of rows) {
        const rowObj = Object.fromEntries(row.map((x, i) => [header[i], x])) as unknown as RawStopTime;
        (data[rowObj.stop_code] || (data[rowObj.stop_code] = [])).push(rowObj);
    }

    // Sort each stop's list of lines.
    // TODO(mingwei): Do more of `getStopTimes`'s processing here, not just sorting.
    for (const list of Object.values(data)) {
        list.sort((a, b) =>
            // Sort Historic -> Metro -> Rapid+Regular -> Owl.
            ((COLOR_GROUP_ORDER[`#${a.route_color.toUpperCase()}`] || 0) - (COLOR_GROUP_ORDER[`#${b.route_color.toUpperCase()}`] || 0)) ||
            // Sort lines numerically: 1 -> 5 -> 38.
            (parseInt(a.route_short_name) - parseInt(b.route_short_name)) ||
            // Sort rapid before anything else: 9R -> 9AX or 9BX or 9.
            (+(COLOR_RAPID != `#${a.route_color.toUpperCase()}`) - +(COLOR_RAPID != `#${b.route_color.toUpperCase()}`)) ||
            // Sort alphabetically: 8AX -> 8BX -> 8.
            (-a.route_short_name.localeCompare(b.route_short_name))
        );
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

    hasMetro: boolean;
    hasRapid: boolean;
    hasHistoric: boolean;
};
export type StopLine = {
    lineId: string;
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
    isMetro: boolean;
    isCableCar: boolean;
    isHistoricStreetcar: boolean;
};

export async function isValidStopId(stopId: string): Promise<boolean> {
    const stops = await STOP_TIMES;
    return Object.hasOwnProperty.call(stops, stopId);
}

export async function randomStopId(): Promise<string> {
    const stops = await STOP_TIMES;
    const keys = Object.keys(stops);
    return keys[0 | (Math.random() * keys.length)];
}

// Strips the trailing 'St, Rd' suffix unless the street is numbered.
function stripStreetSuffix(street: string): string {
    // Sometimes 3rd St is written out in letters.
    street = street.replaceAll(/\bThird St(?:reet)?\b/ig, '3rd St');

    // Too many Buena Vistas, handle separately.
    if (/^Buena Vista/i.test(street)) {
        street = street.replace(/^Buena Vista (?:Ave )?([EW])(?:[ea]st)?(?: Ave)?/i, 'Buena Vista $1');
    }
    // Remove rd/st/etc suffix if street is not numeric.
    // Ignore "Right Of Way", "Upper/Lower Ter".
    else if (!/\d/.test(street[0]) && !/^(Right Of|Upper|Lower)/i.test(street)) {
        // Space followed by suffix optionally followed by dot.
        const SUFFIX_REGEX = / (:?ST|RD|DR|AVE|WAY|TER|BLVD|STREET|AVENUE)\.?$/i;
        street = street.replace(SUFFIX_REGEX, '');
    }
    return street;
}

export async function getStopTimes(stopId: string): Promise<StopTimes> {
    const stops = await STOP_TIMES;
    const controlLocs = await CONTROL_LOCS;

    const stopLines = stops[stopId];
    if (null == stopLines) throw Error('Stop not found: ' + stopId);

    let stopLoc = stopLines[0].stop_name;
    // Remove weird trailing suffixes.
    stopLoc = stopLoc.replace(/[A-Z]{1,2}[-/][A-Z]{1,2} ?[-/] ?[A-Z]{1,2}$/i, '');
    stopLoc = stopLoc
        .split(/ ?\/ ?/)
        .map(seg => seg.split(/ ?& ?/).map(stripStreetSuffix).join(' & '))
        .join(' / ');

    const lines = stopLines
        // https://github.com/MingweiSamuel/muni-sign/issues/7
        .filter(line => !['JBUS', 'KBUS', 'MBUS', 'NBUS', 'TBUS'].includes(line.route_short_name))
        .map(line => {
            let lineNum = line.route_short_name;
            let lineMod = '';
            const match = lineNum.match(/^(\d+)([A-Za-z]+)$/);
            if (match) {
                ([lineNum, lineMod] = match.slice(1));
            }
            else {
                lineNum = lineNum.replace(/(BUS|-OWL)$/, '');
            }
            // Replace droopy J with Greek Yot (non-droopy).
            // Found here: https://github.com/codebox/homoglyph/blob/763c79a20ba054cc028b3336b5c7b1822db36dc8/raw_data/chars.txt#L48
            lineNum = lineNum.replaceAll('J', '\u037F');

            // Some basic cleanup for lineDest0/1
            let lineDest0 = line.trip_headsign.replace(/\s+\([^)]+\)$/, '');
            let lineDest1 = controlLocs[line.route_short_name][+line.direction_id];
            // Ensure neither line is subset of (or equal to) other.
            const l0 = lineDest0.toUpperCase();
            const l1 = lineDest1.toUpperCase();
            if (l0.includes(l1)) {
                lineDest1 = '';
            }
            else if (l1.includes(l0)) {
                lineDest0 = lineDest1;
                lineDest1 = '';
            }

            let lineTextColor = '#' + line.route_text_color;
            let lineColor = '#' + line.route_color.toUpperCase();
            if ('KT' === lineNum) {
                lineColor = 'url(#kt-fill)';
            }

            // Handle Muni Metro and Cable Car/Historic Streetcar lines.
            const routeType: RouteType = Number(line.route_type);
            const isOwl = COLOR_OWL === lineColor;
            const isMetro = RouteType.LightRail === routeType && COLOR_HISTORIC !== lineColor;
            const isRapid = !isMetro && COLOR_RAPID === lineColor;
            const isCableCar = RouteType.CableCar === routeType;
            const isHistoricStreetcar = RouteType.LightRail === routeType && COLOR_HISTORIC === lineColor;

            if (isCableCar || isHistoricStreetcar) {
                lineColor = COLOR_HISTORIC_REPLACEMENT;
                lineTextColor = '#FFFFFF';
            }


            // Line name, hardcoded adjustments
            // TODO: fix capitalization?
            const lineName = line.route_long_name.replace(/^California Street\b/ig, 'California');

            return {
                lineId: line.route_short_name,
                lineNum,
                lineMod,
                lineName,
                lineDest0,
                lineDest1,
                lineTime: getLineTime(line),

                lineTextColor,
                lineColor,

                isRapid,
                isOwl,
                isMetro,
                isCableCar,
                isHistoricStreetcar,
            };
        });
    const hasMetro = lines.some(line => line.isMetro);
    const hasRapid = lines.some(line => line.isRapid);
    const hasHistoric = lines.some(line => line.isCableCar || line.isHistoricStreetcar);

    return { stopId, stopLoc, lines, hasMetro, hasRapid, hasHistoric };
}

export const COLOR_RAPID = '#BF2B45';
export const COLOR_STD = '#005B95';
export const COLOR_OWL = '#666666';
export const COLOR_HISTORIC = '#B49A36';
export const COLOR_HISTORIC_REPLACEMENT = '#CF8B29';

const COLOR_GROUP_ORDER = {
    [COLOR_HISTORIC]: -100,
    [COLOR_RAPID]: 100,
    [COLOR_STD]: 100,
    [COLOR_OWL]: 200
}

export const COMMIT_HASH = __defines__.COMMIT_HASH as string;
