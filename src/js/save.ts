import { saveSvgAsPng } from "save-svg-as-png";

export async function savePng(stopId: string): Promise<void> {
    const svg = document.getElementById("sign") as unknown as SVGElement;
    await saveSvgAsPng(svg, stopId + ".png", {
        backgroundColor: "white",
        scale: 1.44 / (window.devicePixelRatio || 1),
    });
    // For some reason the second time an image is saved it gets messed up,
    // seems something stateful gets messed up in `saveSvgAsPng`.
    // So we refresh to prevent that.
    window.location.reload();
};

export async function saveSvg(stopId: string): Promise<void> {
    const svg = document.getElementById("sign") as unknown as SVGElement;
    const styleImport = document.createElement("style");
    styleImport.setAttribute("type", "text/css");
    const gsheetUrl =
        document.querySelector<HTMLLinkElement>("link#link-gfonts").sheet
            .href;
    styleImport.innerHTML = `@import url('${gsheetUrl}');`;
    svg.appendChild(styleImport);

    const svgString = new XMLSerializer().serializeToString(svg);
    const svgDataUrl =
        "data:image/svg+xml;base64," +
        btoa(unescape(encodeURIComponent(svgString)));
    const name = stopId + ".svg";

    const a = document.createElement("a");
    a.setAttribute("href", svgDataUrl);
    a.setAttribute("download", name);
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);

    svg.removeChild(styleImport);
};
