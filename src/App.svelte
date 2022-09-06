<script lang="ts" context="module">
  import Sign, { FooterType, FOOTER_DESC } from "./lib/Sign.svelte";
  import "./css/print.css";
  import { saveSvg, savePng, savePdf } from "./js/save";
  import { isValidStopId, randomStopId } from "./js/dataLayer";

  const SEARCH_FOOTERTYPE = "foot";
  const SEARCH_NUMBLANKS = "blank";
</script>

<script lang="ts">
  let footerType: FooterType | null = FooterType.I2;
  let numBlanks = 0;
  let stopId = "";

  /// Update the svelte state based on the `window.location.hash`.
  /// Or randomize if `random` is `true`.
  function updateState(random = false) {
    if (!random && window.location.hash) {
      const [id, search] = window.location.hash.slice(1).split("?", 2);
      stopId = id;
      if (search) {
        const searchParams = new URLSearchParams(search);
        footerType = +searchParams.get(SEARCH_FOOTERTYPE) || 0;
        numBlanks = +searchParams.get(SEARCH_NUMBLANKS) || 0;
      }
    } else {
      randomStopId().then((id) => (stopId = id));
    }
  }
  updateState();

  // Maintain URL and history stack:
  $: {
    isValidStopId(stopId).then((isValid) => {
      if (!isValid) return;

      const searchParams = new URLSearchParams();
      if (footerType) searchParams.append(SEARCH_FOOTERTYPE, "" + footerType);
      if (numBlanks) searchParams.append(SEARCH_NUMBLANKS, "" + numBlanks);
      const search = searchParams.toString();

      let hash = "#" + stopId + (search ? "?" + search : "");
      if (window.location.hash !== hash) {
        window.history.pushState(null, null, hash);
      }
    });
  }

  // Disable png/svg/pdf/etc. buttons when exporting.
  let disabled = false;
  let exportPromise = Promise.resolve();
  $: {
    disabled = true;
    exportPromise.then(() => {
      disabled = false;
    });
  }

  // Set by <Sign bind:height={signHeight} />
  let signHeight = 0;

  // Current URL for github issue report
  let currentUrl = null;
  $: currentUrl = stopId, footerType, numBlanks, window.location.href;
</script>

<svelte:window on:hashchange={() => updateState()} />
<main>
  <h1 class="no-print">Muni Sign</h1>

  <div class="card no-print">
    <label>
      Stop ID:
      <input bind:value={stopId} type="text" />
    </label>
    <input
      disabled={disabled || null}
      type="button"
      value="🔀"
      title="Use random stop ID."
      on:click={() => updateState(true)}
    />
  </div>
  <div class="card no-print">
    <label>
      Footer Type:
      <select bind:value={footerType}>
        {#each Object.values(FooterType).filter((x) => !isNaN(+x)) as footerTypeOption}
          <option value={footerTypeOption}>
            {FOOTER_DESC[footerTypeOption]}
          </option>
        {/each}
      </select>
    </label>
  </div>
  <div class="card no-print">
    <label>
      Blank Tiles:
      <select bind:value={numBlanks}>
        {#each [0, 1, 2, 3, 4, 5] as numBlanksOption}
          <option value={numBlanksOption}>{numBlanksOption}</option>
        {/each}
      </select>
    </label>
  </div>
  <div class="card no-print">
    <input
      disabled={disabled || null}
      type="button"
      value="Save PDF"
      title="Save the sign as a PDF."
      on:click={() => (exportPromise = savePdf(stopId))}
    />
    <input
      disabled={disabled || null}
      type="button"
      value="Save PNG"
      title="Save the sign as a PNG image."
      on:click={() => (exportPromise = savePng(stopId))}
    />
    <input
      disabled={disabled || null}
      type="button"
      value="Save SVG"
      title="Save the sign as a vector graphic. Requires internet access to correctly render fonts."
      on:click={() => (exportPromise = saveSvg(stopId))}
    />
    <input
      disabled={disabled || null}
      type="button"
      value="Print"
      title="Print using the system dialog."
      on:click={() => window.print()}
    />
  </div>
  <div class="card no-print">
    Standard Size (w x h): 16in x {signHeight / 100}in
  </div>
  <div class="sign">
    <Sign {stopId} {footerType} {numBlanks} bind:height={signHeight} />
  </div>

  <p class="footer no-print">
    Follow us at <a href="https://twitter.com/SafeStreetRebel" target="_blank"
      >@SafeStreetRebel</a
    >
    on Twitter if you want. Or poke around the
    <a href="https://github.com/MingweiSamuel/muni-sign/" target="_blank"
      >GitHub repository</a
    >. And maybe
    <a
      href="https://github.com/MingweiSamuel/muni-sign/issues/new?body={encodeURIComponent(
        'URL: ' + currentUrl
      )}"
      target="_blank">submit a bug report</a
    >!
  </p>
</main>

<style>
  @media print {
    .sign {
      width: 11in;
      height: auto;
    }
  }

  .footer {
    color: #888;
  }
</style>
