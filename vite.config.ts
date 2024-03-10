import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'
import { execSync } from 'child_process';

// https://vitejs.dev/config/
export default defineConfig({
  define: {
    '__defines__.COMMIT_HASH': JSON.stringify(execSync('git rev-parse --short HEAD').toString().trim()),
  },
  build: {
    sourcemap: true,
  },
  plugins: [svelte()],
  base: '',
})
