import { createApp } from 'vue'
import { createPinia } from 'pinia'
import ElementPlus from 'element-plus'
import { permissionDirective } from '@kite/platform/directive'
import { initializeUiTheme } from '@kite/ui/theme'
import '@kite/ui/styles/index.scss'
import App from './App.vue'
import router from './core/router'
initializeUiTheme()
createApp(App).use(createPinia()).use(ElementPlus).use(router).directive('permission', permissionDirective).mount('#app')
