<script lang="ts">
    export let href = "#";

    let mouseDownTime = 0;
    function anchorMouseDown() {
        mouseDownTime = Date.now();
    }
    function anchorClick(e: MouseEvent) {
        if (200 < Date.now() - mouseDownTime) {
            e.preventDefault();
        }
    }
</script>

<g>
    <a
        {href}
        target="_blank"
        on:mousedown={anchorMouseDown}
        on:click={anchorClick}
    >
        <slot />
    </a>
</g>
