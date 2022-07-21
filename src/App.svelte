<script lang="ts">
  // import svelteLogo from "./assets/svelte.svg";
  import Sign from "./lib/Sign.svelte";

  let stopId = "13772";
</script>

<main>
  <!-- <div>
    <a href="https://vitejs.dev" target="_blank">
      <img src="/vite.svg" class="logo" alt="Vite Logo" />
    </a>
    <a href="https://svelte.dev" target="_blank">
      <img src={svelteLogo} class="logo svelte" alt="Svelte Logo" />
    </a>
  </div> -->
  <h1>MUNI Sign</h1>

  <div class="card">
    <input bind:value={stopId} type="text" />
  </div>
  <div style="width: 800px; height: 2400px">
    <Sign {stopId} />
  </div>

  <p class="read-the-docs">
    Did you expect there to be something down here? Well, you can follow me <a
      href="https://twitter.com/MingweiSamuel" target="_blank">@MingweiSamuel</a
    > on Twitter if you want.
  </p>
</main>

<style>
  /* .logo {
    height: 6em;
    padding: 1.5em;
    will-change: filter;
  }
  .logo:hover {
    filter: drop-shadow(0 0 2em #646cffaa);
  }
  .logo.svelte:hover {
    filter: drop-shadow(0 0 2em #ff3e00aa);
  } */
  .read-the-docs {
    color: #888;
  }
</style>
