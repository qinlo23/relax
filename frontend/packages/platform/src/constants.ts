/** Each application injects its fixed identity at build time, independent of domain or URL. */
declare const __KITE_APP_ID__: 'web' | 'admin'
const scope = __KITE_APP_ID__ === 'admin' ? 'admin' : 'front'

export const AUTH_STORAGE_KEY = `kite_${scope}_auth_session`
export const TOKEN_STORAGE_KEY = `kite_${scope}_token`
export const UI_THEME_STORAGE_KEY = `kite_${scope}_ui_theme`
export const AUTH_CHANGE_EVENT = `kite-${scope}-auth-change`
