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
            .w {
                fill: white;
            }

            .rapid {
                font-family: "Open Sans", sans-serif;
                font-size: 390px;
                font-stretch: 87.5%;
                font-weight: 300;
                text-transform: uppercase;
            }

            .line-number {
                font-family: "Open Sans", sans-serif;
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
                font-family: "Open Sans", sans-serif;
                font-size: 270px;
                font-stretch: 87.5%;
                font-weight: 500;
                letter-spacing: -0.05em;
                text-align: center;
            }

            .line-name {
                font-family: "Open Sans", sans-serif;
                font-size: 72px;
                font-stretch: 100%;
                font-weight: 700;
                text-transform: uppercase;
            }
            .line-name.narrow {
                font-stretch: 87.5%;
            }

            .line-info {
                font-family: "Open Sans", sans-serif;
                font-size: 54px;
                font-stretch: 100%;
                font-weight: 400;
            }

            .stop-id,
            .stop-loc {
                font-family: "Open Sans", sans-serif;
                font-size: 85px;
                font-stretch: 87.5%;
                font-weight: 500;
                text-transform: uppercase;
            }

            .sfmta {
                font-family: "Open Sans", sans-serif;
                font-size: 85px;
                font-weight: 700;
            }
            .i18n {
                font-family: "Noto Sans", "Noto Sans Arabic", "Noto Sans Thai",
                    "Noto Sans KR", sans-serif;
                font-size: 32px;
            }

            .footnote {
                font-family: "Open Sans", sans-serif;
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
            <SvgA href="https://muni-sign.safestreetrebel.com/#{stopId}">
                <text class="footnote" x="400" y="396.5">
                    muni-sign.safestreetrebel.com/#{stopId}
                </text>
            </SvgA>
            <SvgA
                href="https://github.com/MingweiSamuel/muni-sign/tree/{COMMIT_HASH}"
            >
                <text class="footnote" x="1370" y="396.5" text-anchor="end">
                    {COMMIT_HASH.toUpperCase()}
                </text>
            </SvgA>
            <text class="footnote" x="1575" y="396.5" text-anchor="end">
                {new Date().toISOString().slice(0, 10)}
            </text>
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
