import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import AutoImport from 'unplugin-auto-import/vite'
import Components from 'unplugin-vue-components/vite'
import { ElementPlusResolver } from 'unplugin-vue-components/resolvers'
import { fileURLToPath, URL } from 'node:url'

export default defineConfig({
  define: { __KITE_APP_ID__: JSON.stringify('admin') },
  base: '/admin/',
  plugins: [
    vue(),
    AutoImport({ resolvers: [ElementPlusResolver()], dts: 'auto-imports.d.ts' }),
    Components({ resolvers: [ElementPlusResolver()], dirs: ['src/modules', 'src/shared/components'], dts: 'components.d.ts' }),
  ],
  resolve: {
    alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) },
    dedupe: ['vue', 'vue-router', 'pinia', 'element-plus'],
  },
  server: {
    host: '127.0.0.1', port: 5174, strictPort: true,
    hmr: { path: 'hmr' },
    proxy: {
      '/api': { target: 'http://127.0.0.1:8080', changeOrigin: true },
      
    },
  },
  preview: {
    host: '127.0.0.1', port: 5180, strictPort: true,
    proxy: {
      '/api': { target: 'http://127.0.0.1:8080', changeOrigin: true },
      
    },
  },
  build: {
    outDir: '../../dist/admin', emptyOutDir: true,
    rollupOptions: { output: { manualChunks: {
      vue: ['vue', 'vue-router', 'pinia'],
      element: ['element-plus'],
      
    } } },
  },
})
