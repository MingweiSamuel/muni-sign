<script lang="ts">
    import TileLine from "./TileLine.svelte";
    import TileFooter from "./TileFooter.svelte";
    import TileMuni from "./TileMuni.svelte";

    const SPACING = 400;

    import { getStopTimes, type StopTimes, COMMIT_HASH } from "../js/dataLayer";
    import SvgA from "./SvgA.svelte";

    export let stopId = "16371";
    let dataPromise: Promise<StopTimes> = new Promise(() => {});
    $: {
        dataPromise = getStopTimes(stopId);
    }
</script>

{#await dataPromise}
    <p>Loading...</p>
{:then data}
    <svg
        id="sign"
        xmlns="http://www.w3.org/2000/svg"
        version="1.1"
        viewBox="0 0 1600 {400 + (1 + data.lines.length) * SPACING}"
        style="background: white;"
    >
        <style type="text/css">
            text {
                font-family: "Open Sans", sans-serif;
            }
            .w {
                fill: white;
            }

            .rapid {
                font-size: 390px;
                font-stretch: 87.5%;
                font-weight: 300;
                text-transform: uppercase;
            }

            .line-number {
                font-size: 420px;
                font-stretch: 87.5%;
                font-weight: 500;
                letter-spacing: -0.05em;
                text-align: center;
            }
            .line-number.metro {
                font-size: 300px;
                /* font-stretch: 100%; */
            }
            .line-modifier {
                font-size: 270px;
                font-stretch: 87.5%;
                font-weight: 500;
                letter-spacing: -0.05em;
                text-align: center;
            }

            .line-name {
                font-size: 72px;
                font-stretch: 100%;
                font-weight: 700;
                text-transform: uppercase;
            }
            .line-name.narrow {
                font-stretch: 87.5%;
            }

            .line-info {
                font-size: 54px;
                font-stretch: 100%;
                font-weight: 400;
            }

            .stop-id,
            .stop-loc {
                font-size: 85px;
                font-stretch: 87.5%;
                font-weight: 500;
                text-transform: uppercase;
            }

            .nextmuni,
            .t511 {
                font-size: 56px;
            }
            .t511 {
                font-weight: 700;
            }
            .t311 {
                font-size: 56px;
                font-weight: 700;
            }
            .i18n {
                font-family: "Noto Sans", "Noto Sans Arabic", "Noto Sans Thai",
                    "Noto Sans KR", sans-serif;
                font-size: 42px;
            }

            .footnote {
                font-size: 25px;
                font-stretch: 87.5%;
                font-weight: 700;
                fill: #000;
                text-transform: uppercase;
            }
        </style>
        <defs>
            <pattern
                id="kt-fill"
                width="1600"
                height="375"
                patternUnits="userSpaceOnUse"
            >
                <rect width="1600" height="375" fill="#BF2B45" />
                <path fill="#437C93" d="M 0,0 L 1240,0 L 360,375 L 0,375 Z" />
            </pattern>
        </defs>
        <clipPath id="clip-tile">
            <rect x="0" y="0" width="1600" height="375" />
        </clipPath>
        <g clip-path="url(#clip-tile)">
            <TileMuni
                hasMetro={data.hasMetro}
                hasRapid={data.hasRapid}
                hasHistoric={data.hasHistoric}
            />
        </g>
        {#each data.lines as line, i}
            <g
                clip-path="url(#clip-tile)"
                transform="translate({0}, {(1 + i) * SPACING})"
            >
                <TileLine {line} />
            </g>
        {/each}
        <g transform="translate({0}, {(1 + data.lines.length) * SPACING})">
            <TileFooter stopId={data.stopId} stopLoc={data.stopLoc} />
            <SvgA href="https://twitter.com/SafeStreetRebel">
                <path
                    transform="translate(1170, 378) scale(0.1)"
                    d="M221.95 51.29c.15 2.17.15 4.34.15 6.53 0 66.73-50.8 143.69-143.69 143.69v-.04c-27.44.04-54.31-7.82-77.41-22.64 3.99.48 8 .72 12.02.73 22.74.02 44.83-7.61 62.72-21.66-21.61-.41-40.56-14.5-47.18-35.07 7.57 1.46 15.37 1.16 22.8-.87-23.56-4.76-40.51-25.46-40.51-49.5v-.64c7.02 3.91 14.88 6.08 22.92 6.32C11.58 63.31 4.74 33.79 18.14 10.71c25.64 31.55 63.47 50.73 104.08 52.76-4.07-17.54 1.49-35.92 14.61-48.25 20.34-19.12 52.33-18.14 71.45 2.19 11.31-2.23 22.15-6.38 32.07-12.26-3.77 11.69-11.66 21.62-22.2 27.93 10.01-1.18 19.79-3.86 29-7.95-6.78 10.16-15.32 19.01-25.2 26.16z"
                />
                <text class="footnote" x="1200" y="396.5">
                    safe&hairsp;street&hairsp;rebel
                </text>
            </SvgA>
            <SvgA
                href="https://github.com/MingweiSamuel/muni-sign/tree/{COMMIT_HASH}"
            >
                <text class="footnote" x="1575" y="396.5" text-anchor="end">
                    {new Date().toISOString().slice(0, 10).replaceAll("-", " ")}
                </text>
            </SvgA>
        </g>
    </svg>
{:catch error}
    <p style="color: red">{error.message}</p>
{/await}

<style>
    @media screen {
        #sign {
            box-shadow: 0 0.1vw 1.2vw #000;
        }
    }
</style>
