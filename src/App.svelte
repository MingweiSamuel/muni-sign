<script lang="ts">
  import Sign from "./lib/Sign.svelte";
  import "./css/print.css";
  import { saveSvg, savePng, savePdf } from "./js/save";
  import { randomStopId } from "./js/dataLayer";

  let stopId = "";
  if (window.location.hash) {
    stopId = window.location.hash.slice(1);
  } else {
    randomStopId().then((id) => (location.hash = "#" + id));
  }

  let timer;
  $: {
    clearTimeout(timer);
    timer = setTimeout(() => {
      window.history.pushState(null, null, "#" + stopId);
    }, 3000);
  }

  let disabled = false;
  let exportPromise = Promise.resolve();
  $: {
    disabled = true;
    exportPromise.then(() => {
      disabled = false;
    });
  }
</script>

<svelte:window
  on:hashchange={() =>
    window.location.hash && (stopId = window.location.hash.slice(1))}
/>
<main>
  <!-- <div>
    <a href="https://vitejs.dev" target="_blank">
      <img src="/vite.svg" class="logo" alt="Vite Logo" />
    </a>
    <a href="https://svelte.dev" target="_blank">
      <img src={svelteLogo} class="logo svelte" alt="Svelte Logo" />
    </a>
  </div> -->
  <h1 class="no-print">MUNI Sign</h1>

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
      on:click={() => randomStopId().then((id) => (location.hash = "#" + id))}
    />
    &nbsp; &nbsp;
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
  <div class="sign">
    <Sign {stopId} />
  </div>

  <p class="footer no-print">
    You scrolled all the way to the bottom! You can follow me <a
      href="https://twitter.com/MingweiSamuel"
      target="_blank">@MingweiSamuel</a
    >
    on Twitter if you want. Or poke around the
    <a href="https://github.com/MingweiSamuel/muni-sign/" target="_blank"
      >GitHub repository</a
    >. And maybe
    <a href="https://github.com/MingweiSamuel/muni-sign/issues/new"
      >submit a bug report</a
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
