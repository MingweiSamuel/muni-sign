<script lang="ts">
    import TileBlank from "./TileBlank.svelte";

    import TileBus from "./TileBus.svelte";
    import TileFooter from "./TileFooter.svelte";
    import TileMuni from "./TileMuni.svelte";
</script>

<svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 1250 3000" style="background: white;">
    <style>
        @import url("https://fonts.googleapis.com/css2?family=Noto+Sans&family=Noto+Sans+Arabic&family=Noto+Sans+KR&family=Noto+Sans+Thai&family=Open+Sans:wdth,wght@87.5,300;87.5,500;87.5,700;100,400;100,700&display=swap");

        text {
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
    <g transform="translate({0}, {0 * 262.5})">
        <TileMuni isRapid={true} />
    </g>
    <g transform="translate({0}, {1 * 262.5})">
        <TileBus
            lineNum={"49"}
            lineName={"Van Ness-Mission"}
            lineDest0={"Fisherman's Wharf"}
            lineDest1={"Van Ness & North Point"}
            lineTime={"Daily ~ 5:30am-12am"}
        />
    </g>
    <g transform="translate({0}, {2 * 262.5})">
        <TileBus
            lineNum={"90"}
            lineName={"San Bruno Owl"}
            lineDest0={"To Fort Mason/Aquatic Park"}
            lineDest1={"via Civic Center"}
            lineTime={"Late Night ~ 12am-5am"}
            isOwl={true}
        />
    </g>
    <g transform="translate({0}, {3 * 262.5})">
        <TileBus
            lineNum={"714"}
            lineName={"BART Early Bird"}
            lineDest0={"To Mission St & San Jose Ave"}
            lineDest1={"Daily City BART"}
            lineTime={"Weekdays 4am-5am"}
        />
    </g>
    <g transform="translate({0}, {4 * 262.5})">
        <TileBus lineNum={"5"} lineName={"Fulton"} />
    </g>
    <g transform="translate({0}, {5 * 262.5})">
        <TileBus lineNum={"38"} lineMod={"R"} lineName={"Geary"} isRapid={true} />
    </g>
    <g transform="translate({0}, {6 * 262.5})">
        <TileBus lineNum={"38"} lineMod={"AX"} lineName={"Geary"} />
    </g>
    <g transform="translate({0}, {7 * 262.5})">
        <TileBus lineNum={"5"} lineMod={"R"} lineName={"Fulton Rapid"}  isRapid={true} />
    </g>
    <g transform="translate({0}, {8 * 262.5})">
        <TileBus lineNum={"1"} lineMod={"BX"} lineName={"California B Express"} />
    </g>
    <g transform="translate({0}, {9 * 262.5})">
        <TileBlank />
    </g>
    <g transform="translate({0}, {10 * 262.5})">
        <TileFooter stopId={18088} stopLoc={"South Van Ness & Market"} />
    </g>
    <rect x="1100" y="0" width="150" height="1725" fill="#000" />
</svg>
