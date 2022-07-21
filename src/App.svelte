<script lang="ts">
  // import svelteLogo from "./assets/svelte.svg";
  import Sign from "./lib/Sign.svelte";

  let stopId = "16371";
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
  <div class="sign">
    <Sign {stopId} />
  </div>

  <p class="read-the-docs">
    You scrolled all the way to the bottom! Well, you can follow me <a
      href="https://twitter.com/MingweiSamuel"
      target="_blank">@MingweiSamuel</a
    >
    on Twitter if you want. Or poke around the
    <a href="https://github.com/MingweiSamuel/muni-sign/" target="_blank"
      >GitHub repository</a
    >, maybe
    <a href="https://github.com/MingweiSamuel/muni-sign/issues/new"
      >submit a bug report</a
    >.
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
  .sign {
    width: calc(300px + 40vw);
    height: calc(750px + 100vw);
    margin: auto;
  }
  .read-the-docs {
    color: #888;
  }
</style>
