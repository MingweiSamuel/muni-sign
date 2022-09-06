<script lang="ts" context="module">
    import TileLine from "./TileLine.svelte";
    import TileFooter4InQr from "./TileFooter4InQr.svelte";
    import TileMuni from "./TileMuni.svelte";

    import { COLOR_STD, getStopTimes, type StopTimes } from "../js/dataLayer";
    import TileFooter2In from "./TileFooter2In.svelte";
    import TileBlank from "./TileBlank.svelte";

    export enum FooterType {
        I2 = 0,
        I4QR = 1,
    }
    export const FOOTER_DESC = {
        [FooterType.I2]: "Standard 2in",
        [FooterType.I4QR]: "QR 4in",
    };

    const SPACING = 400;
    const SHOW_I150_BORDER = false;
</script>

<script lang="ts">
    export let stopId = "16371";
    export let footerType: FooterType | null = FooterType.I2;
    export let numBlanks = 0;

    let dataPromise: Promise<StopTimes> = new Promise(() => {});
    $: {
        dataPromise = getStopTimes(stopId);
    }

    let footerComponent;
    let footerHeight = 0;
    $: {
        switch (footerType) {
            case FooterType.I2:
                footerComponent = TileFooter2In;
                footerHeight = 200;
                break;
            case FooterType.I4QR:
                footerComponent = TileFooter4InQr;
                footerHeight = 400;
                break;
            default:
                console.error("Unknown footer type: " + footerType);
                footerComponent = null;
                footerHeight = 0;
                break;
        }
    }

    export let height = 0;
    $: {
        dataPromise.then((data) => {
            height =
                (1 + data.lines.length + numBlanks) * SPACING + footerHeight;
        });
    }
</script>

{#await dataPromise}
    <p>Loading...</p>
{:then data}
    <svg
        id="sign"
        xmlns="http://www.w3.org/2000/svg"
        version="1.1"
        viewBox="0 0 1600 {height}"
        style="background: white;"
    >
        <!--
            font-stretch:
            ultra-condensed 50%
            extra-condensed 62.5%
            condensed       75%
            semi-condensed  87.5%
            normal          100%
            semi-expanded   112.5%
            expanded        125%
            extra-expanded  150%
            ultra-expanded  200%
        -->
        <style type="text/css">
            text {
                font-family: "Open Sans", sans-serif;
            }
            .w {
                fill: white;
            }
            .stretch-sc {
                font-stretch: semi-condensed;
            }

            .rapid {
                font-size: 390px;
                font-stretch: semi-condensed;
                font-weight: 300;
            }

            .line-number {
                font-size: 420px;
                font-stretch: semi-condensed;
                font-weight: 500;
                letter-spacing: -0.05em;
                text-align: center;
            }
            .line-number.metro {
                font-size: 300px;
            }
            .line-modifier {
                font-size: 270px;
                font-stretch: semi-condensed;
                font-weight: 500;
                letter-spacing: -0.05em;
                text-align: center;
            }

            .line-name {
                font-size: 76px;
                font-weight: 700;
            }
            .line-name.narrow {
                font-stretch: semi-condensed;
            }
            .line-info {
                font-size: 58px;
                font-weight: 400;
            }

            .I4QR .stop-loc {
                font-size: 85px;
                font-stretch: semi-condensed;
                font-weight: 500;
            }
            .I4QR .nextmuni {
                font-size: 64px;
                font-weight: 500;
                font-stretch: semi-condensed;
            }
            .I4QR .t511 {
                font-size: 64px;
                font-weight: 700;
            }
            .I4QR .t311 {
                font-size: 48px;
                font-weight: 700;
            }
            .I4QR .i18n {
                font-family: "Noto Sans", "Noto Sans Arabic", "Noto Sans Thai",
                    "Noto Sans KR", sans-serif;
                font-size: 40px;
            }

            .I2 .stop-loc {
                font-size: 68px;
                font-stretch: semi-condensed;
                font-weight: 500;
            }
            .I2 .t511,
            .I2 .t311 {
                font-size: 78px;
                font-weight: 700;
            }
            .I2 .i18n {
                font-family: "Noto Sans", "Noto Sans Arabic", "Noto Sans Thai",
                    "Noto Sans KR", sans-serif;
                font-size: 29px;
            }

            .footnote {
                font-size: 26.5px;
                font-stretch: semi-condensed;
                font-weight: 700;
                fill: #000;
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
        {#each Array(numBlanks).fill(null) as _, i}
            <g
                clip-path="url(#clip-tile)"
                transform="translate({0}, {(1 + data.lines.length + i) *
                    SPACING})"
            >
                <TileBlank lineColor={COLOR_STD} />
            </g>
        {/each}
        <g
            class={FooterType[footerType]}
            transform="translate({0}, {(1 + data.lines.length + numBlanks) *
                SPACING})"
        >
            <svelte:component
                this={footerComponent}
                stopId={data.stopId}
                stopLoc={data.stopLoc}
            />
        </g>
        {#if SHOW_I150_BORDER}
            <rect
                x="1"
                y="1"
                width="1598"
                height={height - 2}
                rx="150"
                fill="none"
                stroke="#f0f"
                stroke-width="2"
            />
        {/if}
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
