import { defineConfig, type ViteDevServer } from 'vite'
import vue from '@vitejs/plugin-vue'
import AutoImport from 'unplugin-auto-import/vite'
import Components from 'unplugin-vue-components/vite'
import { ElementPlusResolver } from 'unplugin-vue-components/resolvers'
import { fileURLToPath, URL } from 'node:url'

function redirectAdminRoot(server: Pick<ViteDevServer, 'middlewares'>) {
  server.middlewares.use((request, response, next) => {
    if (request.url?.split('?')[0] !== '/admin') return next()
    response.writeHead(302, { Location: '/admin/' + request.url.slice('/admin'.length) })
    response.end()
  })
}

export default defineConfig({
  define: { __KITE_APP_ID__: JSON.stringify('web') },
  base: '/',
  plugins: [
    { name: 'admin-root-redirect', configureServer: redirectAdminRoot, configurePreviewServer: redirectAdminRoot },
    vue(),
    AutoImport({ resolvers: [ElementPlusResolver()], dts: 'auto-imports.d.ts' }),
    Components({ resolvers: [ElementPlusResolver()], dirs: ['src/modules', 'src/shared/components'], dts: 'components.d.ts' }),
  ],
  resolve: {
    alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) },
    dedupe: ['vue', 'vue-router', 'pinia', 'element-plus'],
  },
  server: {
    host: '127.0.0.1', port: 5173, strictPort: true,
    
    proxy: {
      '/api': { target: 'http://127.0.0.1:8080', changeOrigin: true },
      '^/admin(?:/|$)': { target: 'http://127.0.0.1:5174', ws: true },
    },
  },
  preview: {
    host: '127.0.0.1', port: 5179, strictPort: true,
    proxy: {
      '/api': { target: 'http://127.0.0.1:8080', changeOrigin: true },
      '^/admin(?:/|$)': { target: 'http://127.0.0.1:5180' },
    },
  },
  build: {
    outDir: '../../dist/web', emptyOutDir: true,
    rollupOptions: { output: { manualChunks: {
      vue: ['vue', 'vue-router', 'pinia'],
      element: ['element-plus'],
      echarts: ['echarts', 'vue-echarts'],
    } } },
  },
})
