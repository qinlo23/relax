import { permissionDirective } from '@kite/platform/directive'
import type { App } from 'vue'
import ElementPlus from 'element-plus'
import '@kite/ui/styles/index.scss'
import { createPinia } from 'pinia'
import router from '@/core/router/index.js'
import { setupEcharts } from './echarts'

export function setupAppPlugins(app: App) {
  const pinia = createPinia()

  app.directive('permission', permissionDirective)
  app.use(pinia)
  app.use(router)
  app.use(ElementPlus)
  setupEcharts(app)
}
