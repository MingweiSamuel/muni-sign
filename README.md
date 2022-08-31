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

Then run the dev server:

```bash
npm run dev
```

### Updating stop data

Stop data is stored in the `public/data` folder. The [gh-pages](https://github.com/MingweiSamuel/muni-sign/tree/gh-pages/data)
version of this data is kept up-to-date by gh-actions, however the versions
committed to main may become out-of-date.

To update them you will need Powershell 7 (AKA "Powershell Core") and the
["q" command-line SQL tool](https://harelba.github.io/q/).
* [Install Powershell](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7)
* [Install q](https://harelba.github.io/q/#installation)

Then run the build to fetch and process the GTFS data:
```bash
npm run build
```

If you want to update the stop data again you should delete the `sfmta_gtfs`
folder first to trigger a re-download.
