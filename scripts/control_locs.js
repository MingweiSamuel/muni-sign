import fs from 'fs/promises';
import { JSDOM } from 'jsdom';
import fetch from 'node-fetch';

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

    const routesSorted = Array.from(routes);
    routesSorted.sort((a, b) => a.localeCompare(b));
    const promises = Array.from(routesSorted).map(async routeId => {
        try {
            const response = await fetch(`https://www.sfmta.com/${routeId}`);
            const htmlBody = await response.text();
            const dom = new JSDOM(htmlBody);

            const outboundA = dom.window.document.querySelector('details#outbound > summary > span');
            const inboundA = dom.window.document.querySelector('details#inbound > summary > span');
            if (!outboundA || !inboundA) {
                console.warn(`No inbound/outbound data for ${response.url}`);
                return null;
            }
            const pair = [outboundA.textContent, inboundA.textContent];
            console.log(`${routeId}:`.padEnd(8) + JSON.stringify(pair));
            return [routeId, pair];
        }
        catch (e) {
            console.error(`Unexpected error finding inbound/outbound data for ${routeId}`, e);
            return null;
        }
    });
    const data = Object.fromEntries((await Promise.all(promises)).filter(pair => null != pair));

    await fs.writeFile('public/data/control_locs.json', JSON.stringify(data, null, 2), 'utf-8');
}

main().catch(console.error);
