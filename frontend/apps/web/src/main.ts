import { createApp } from 'vue'
import App from './App.vue'
import { setupAppPlugins } from '@/core/plugins'
import { initializeUiTheme } from '@kite/ui/theme'

initializeUiTheme()
const app = createApp(App)

setupAppPlugins(app)
app.mount('#app')
