import fs from 'fs/promises';
import { JSDOM } from 'jsdom';

function parseCsv(csvText) {
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

async function main() {
    const text = await fs.readFile('sfmta_gtfs/routes.txt', 'utf-8');
    const [header, ...rows] = parseCsv(text);
    const routes = new Set(rows
        .map(row => Object.fromEntries(row.map((x, i) => [header[i], x])))
        .map(route => route.route_short_name));

    const promises = Array.from(routes).map(async routeId => {
        try {
            const response = await fetch(`https://www.sfmta.com/${routeId}`);
            const htmlBody = await response.text();
            const dom = new JSDOM(htmlBody);

            const DEST_REGEX = /(?:In|Out|East|West|North|South)bound to (.+) stop list/;
            const outbound = dom.window.document.querySelector('#outboud a').textContent.match(DEST_REGEX)[1];
            const inbound = dom.window.document.querySelector('#inbound a').textContent.match(DEST_REGEX)[1];

            return [routeId, [outbound, inbound]];
        }
        catch (e) {
            console.error(routeId, e);
        }
    });
    const data = Object.fromEntries(await Promise.all(promises));

    // TODO: manual override here.
    data['43'][1] = '';

    await fs.writeFile('public/data/control_locs.json', JSON.stringify(data, null, 2), 'utf-8');
}

main().catch(console.error);
