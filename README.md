# Muni Sign

Generate SFMTA Muni signs from their stop IDs for fun!

This website is built with [Svelte](https://svelte.dev/).

## Development

First, clone the repository:

```bash
git clone git@github.com:MingweiSamuel/muni-sign.git
cd muni-sign
```

Install dependencies:

```bash
npm ci
```

Run the build to fetch and process the GTFS data. You only need to do this
once, or whenever you delete the `sfmta_gtfs` folder.

```bash
npm run build
```

Then run the dev server:

```bash
npm run dev
```
