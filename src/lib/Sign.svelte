<script lang="ts">
    import TileLine from "./TileLine.svelte";
    import TileFooter from "./TileFooter.svelte";
    import TileMuni from "./TileMuni.svelte";

    const SPACING = 262.5;

    import {
        getStopTimes,
        COLOR_RAPID,
        COLOR_STD,
        type StopTimes,
    } from "../js/dataLayer";

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
        viewBox="0 0 1100 {150 + (1 + data.lines.length) * SPACING}"
        style="background: white;"
    >
        <style type="text/css">
            .w {
                fill: white;
            }

            .rapid {
                font-family: "Open Sans", sans-serif;
                font-size: 260px;
                font-stretch: 87.5%;
                font-weight: 300;
                text-transform: uppercase;
            }

            .line-number {
                font-family: "Open Sans", sans-serif;
                font-size: 280px;
                font-stretch: 87.5%;
                font-weight: 500;
                letter-spacing: -0.05em;
                text-align: center;
            }
            .line-number.metro {
                font-size: 200px;
                /* font-stretch: 100%; */
            }
            .line-modifier {
                font-family: "Open Sans", sans-serif;
                font-size: 180px;
                font-stretch: 87.5%;
                font-weight: 500;
                letter-spacing: -0.05em;
                text-align: center;
            }

            .line-name {
                font-family: "Open Sans", sans-serif;
                font-size: 48px;
                font-stretch: 100%;
                font-weight: 700;
                text-transform: uppercase;
            }
            .line-name.narrow {
                font-stretch: 87.5%;
            }

            .line-info {
                font-family: "Open Sans", sans-serif;
                font-size: 36px;
                font-stretch: 100%;
                font-weight: 400;
            }

            .stop-id,
            .stop-loc {
                font-family: "Open Sans", sans-serif;
                font-size: 48px;
                font-stretch: 87.5%;
                font-weight: 500;
                text-transform: uppercase;
            }

            .stop-loc {
                text-anchor: end;
            }

            .sfmta {
                font-family: "Open Sans", sans-serif;
                font-size: 54px;
                font-weight: 700;
            }

            .i18n {
                font-family: "Noto Sans", "Noto Sans Arabic", "Noto Sans Thai",
                    "Noto Sans KR", sans-serif;
                font-size: 21px;
            }
        </style>
        <defs>
            <pattern
                id="kt-fill"
                width="1100"
                height="250"
                patternUnits="userSpaceOnUse"
            >
                <rect width="1100" height="250" fill="#BF2B45" />
                <path fill="#437C93" d="M 0,0 L 850,0 L 250,250 L 0,250 Z" />
            </pattern>
        </defs>
        <g transform="translate({0}, {0 * SPACING})">
            <TileMuni
                hasMetro={data.hasMetro}
                hasRapid={data.hasRapid}
                lineColor={data.hasMetro || data.hasRapid
                    ? COLOR_RAPID
                    : COLOR_STD}
            />
        </g>
        {#each data.lines as line, i}
            <g transform="translate({0}, {(1 + i) * SPACING})">
                <TileLine {line} />
            </g>
        {/each}
        <g transform="translate({0}, {(1 + data.lines.length) * SPACING})">
            <TileFooter stopId={data.stopId} stopLoc={data.stopLoc} />
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
