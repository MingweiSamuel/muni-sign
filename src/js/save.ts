import { saveSvg as saveSvgAsSvg, saveSvgAsPng, svgAsPngUri, type Options } from "save-svg-as-png";
import { jsPDF } from "jspdf";

const SVG_AS_PNG_OPTIONS: Options = {
    backgroundColor: "white",
    scale: 2 / (window.devicePixelRatio || 1),
};


// For some reason the second time an image is saved it is messed up, seems
// something stateful gets messed up in `saveSvgAsPng`. So we refresh to
// prevent that.
//
// Wait until focus is regained to let download dialog appear.
let reloadOnFocus = false;
window.addEventListener('focus', () => {
    if (reloadOnFocus) {
        window.location.reload();
    }
});

export async function savePng(stopId: string): Promise<void> {
    const svg = document.getElementById("sign") as unknown as SVGSVGElement;
    await saveSvgAsPng(svg, stopId + ".png", SVG_AS_PNG_OPTIONS);

    // See note above.
    reloadOnFocus = true;
};

export async function savePdf(stopId: string): Promise<void> {
    const svg = document.getElementById("sign") as unknown as SVGSVGElement;
    const pngUri = await svgAsPngUri(svg, SVG_AS_PNG_OPTIONS);
    const box = svg.viewBox.baseVal;

    const w = 16;
    const h = 16 * box.height / box.width;

    const doc = new jsPDF({
        orientation: "landscape",
        unit: "in",
        format: [w, h]
    });
    doc.addImage(pngUri, 'PNG', 0, 0, w, h);
    doc.save(stopId + ".pdf");

    // See note above.
    reloadOnFocus = true;
}

export async function saveSvg(stopId: string): Promise<void> {
    const svg = document.getElementById("sign") as unknown as SVGSVGElement;
    const box = svg.viewBox.baseVal;
    const styleImport = document.createElement("style");
    styleImport.setAttribute("type", "text/css");
    const gsheetUrl =
        document.querySelector<HTMLLinkElement>("link#link-gfonts").sheet
            .href;
    styleImport.innerHTML = `@import url('${gsheetUrl}');`;
    svg.appendChild(styleImport);
    svg.setAttribute("width", `${16}in`);
    svg.setAttribute("height", `${16 * box.height / box.width}in`);

    const svgString = new XMLSerializer().serializeToString(svg);
    const svgDataUrl =
        "data:image/svg+xml;base64," +
        // TODO(mingwei): Do this in a better way, avoid using unescape.
        window.btoa(unescape(encodeURIComponent(svgString)));
    const name = stopId + ".svg";

    const a = document.createElement("a");
    a.setAttribute("href", svgDataUrl);
    a.setAttribute("download", name);
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);

    svg.removeChild(styleImport);
    svg.removeAttribute("width");
    svg.removeAttribute("height");
};
