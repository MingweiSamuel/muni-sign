<script lang="ts">
    import TileBus from "./TileBus.svelte";
    import TileFooter from "./TileFooter.svelte";
    import TileMuni from "./TileMuni.svelte";

    const SPACING = 262.5;

    import {
        getStopTimes,
        COLOR_RAPID,
        COLOR_STD,
        type StopTimes,
    } from "../js/dataLayer";

    export let stopId = "18088";
    let dataPromise: Promise<StopTimes> = new Promise(() => {});
    $: {
        dataPromise = getStopTimes(stopId);
    }
</script>

{#await dataPromise}
    <p>Loading...</p>
{:then data}
    <svg
        xmlns="http://www.w3.org/2000/svg"
        version="1.1"
        viewBox="0 0 1100 {150 + (1 + data.lines.length) * SPACING}"
        style="background: white;"
    >
        <style>
            @import url("https://fonts.googleapis.com/css2?family=Noto+Sans&family=Noto+Sans+Arabic&family=Noto+Sans+KR&family=Noto+Sans+Thai&family=Open+Sans:wdth,wght@87.5,300;87.5,500;87.5,700;100,400;100,700&display=swap");

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
        <g transform="translate({0}, {0 * SPACING})">
            <TileMuni
                hasRapid={data.hasRapid}
                lineColor={data.hasRapid ? COLOR_RAPID : COLOR_STD}
            />
        </g>
        {#each data.lines as line, i}
            <g transform="translate({0}, {(1 + i) * SPACING})">
                <TileBus
                    lineNum={line.lineNum}
                    lineMod={line.lineMod}
                    lineName={line.lineName}
                    lineDest0={line.lineDest0}
                    lineDest1={line.lineDest1}
                    lineTime={line.lineTime}
                    lineTextColor={line.lineTextColor}
                    lineColor={line.lineColor}
                    isOwl={line.isOwl}
                />
            </g>
        {/each}
        <g transform="translate({0}, {(1 + data.lines.length) * SPACING})">
            <TileFooter stopId={data.stopId} stopLoc={data.stopLoc} />
        </g>
    </svg>
{:catch error}
    <p style="color: red">{error.message}</p>
{/await}
