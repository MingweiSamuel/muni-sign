<script lang="ts" context="module">
  import Sign, { FooterType, FOOTER_DESC } from "./lib/Sign.svelte";
  import "./css/print.css";
  import { saveSvg, savePng, savePdf } from "./js/save";
  import { isValidStopId, randomStopId } from "./js/dataLayer";

  const SEARCH_FOOTERTYPE = "foot";
  const SEARCH_NUMBLANKS = "blank";

  // Redirect to munisign.org.
  if (
    window.location.hostname.toUpperCase() === "MUNI-SIGN.SAFESTREETREBEL.COM"
  ) {
    window.location.replace(
      "https://munisign.org/" + window.location.hash.slice(1)
    );
  }

  const USE_SPA =
    window.location.hostname.toUpperCase() === "LOCALHOST" ||
    window.location.hostname.toUpperCase().endsWith(".PAGES.DEV") ||
    window.location.hostname.toUpperCase() === "MUNISIGN.ORG";
</script>

<script lang="ts">
  let footerType: FooterType | null = FooterType.I2;
  let numBlanks = 0;
  let stopId = "";

  /// Update the svelte state.
  /// - Based on the path and search params if `USE_SPA`.
  /// - Based on the `window.location.hash` if `!USE_SPA`.
  /// Or randomize if `random` is `true`.
  function updateState(random = false) {
    // Use SPA, base state off of query params if set.
    if (!random && USE_SPA && 1 < window.location.pathname.length) {
      stopId = window.location.pathname.slice(1);
      const searchParams = new URLSearchParams(window.location.search);

      footerType = +searchParams.get(SEARCH_FOOTERTYPE) || 0;
      numBlanks = +searchParams.get(SEARCH_NUMBLANKS) || 0;
    }
    // Not SPA, base state off of hash if set.
    else if (!random && !USE_SPA && window.location.hash) {
      const [id, search] = window.location.hash.slice(1).split("?", 2);
      stopId = id;

      // If `undefined === search` then `searchParams` will be empty, vals set
      // to zero as desired.
      const searchParams = new URLSearchParams(search);
      footerType = +searchParams.get(SEARCH_FOOTERTYPE) || 0;
      numBlanks = +searchParams.get(SEARCH_NUMBLANKS) || 0;
    }
    // If we're a search indexing bot, don't default to random.
    else if (!random && /bot|crawl|spider/i.test(navigator.userAgent)) {
      stopId = "";
    }
    // If random or no query/hash state was found, go to a random stop.
    else {
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
      const searchWithQ = search ? "?" + search : "";

      if (USE_SPA) {
        const pathname = "/" + stopId + searchWithQ;
        if (window.location.pathname + window.location.search !== pathname) {
          window.history.pushState(null, "", pathname);
        }
      } else {
        const hash = "#" + stopId + searchWithQ;
        if (window.location.hash !== hash) {
          window.history.pushState(null, "", hash);
        }
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

  type X = svelte.JSX.MouseEventHandler<HTMLAnchorElement>;
  function updateReportUrl(
    event: MouseEvent & { currentTarget: EventTarget & HTMLAnchorElement }
  ) {
    const url = new URL(event.currentTarget.href);
    url.searchParams.set("body", "URL: " + window.location.href);
    event.currentTarget.href = url.toString();
  }

  // Set by <Sign bind:* />
  let signHeight = 0;
  let stopLoc = "";
  $: {
    window.document.title = stopLoc
      ? `${stopLoc} #${stopId}`
      : "Muni Sign Generator";
  }
</script>

<svelte:window
  on:hashchange={() => updateState()}
  on:popstate={() => updateState()}
/>
<main>
  <h1 class="no-print">Muni Sign</h1>
  <p class="no-print" style="padding-bottom: 1em;">
    <a href="https://www.safestreetrebel.com/muni-signs/">Make a sign!</a>
  </p>

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
  <div class="card sign">
    <Sign
      {stopId}
      {footerType}
      {numBlanks}
      bind:height={signHeight}
      bind:stopLoc
    />
  </div>

  <div class="card no-print">
    <label>
      Footer:
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
      Blank tiles:
      <select bind:value={numBlanks}>
        {#each [0, 1, 2, 3, 4, 5] as numBlanksOption}
          <option value={numBlanksOption}>{numBlanksOption}</option>
        {/each}
      </select>
    </label>
  </div>
  <div class="card no-print">
    Ref size: 16in &times; {signHeight / 100}in (w &times; h)
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
      on:mouseenter={updateReportUrl}
      on:click={updateReportUrl}
      href="https://github.com/MingweiSamuel/muni-sign/issues/new"
      target="_blank">submit a bug report</a
    >!
    <br />
    <span class="footer copyright no-print">
      Generated signs are public domain excluding the Muni Worm, Muni Owl, and
      SF Municipal Railway symbols which belong to the SFMTA.
    </span>
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
  .copyright {
    font-size: 0.8rem;
  }
</style>
