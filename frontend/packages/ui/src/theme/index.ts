import { readonly, ref } from 'vue'
import { UI_THEME_STORAGE_KEY } from '@kite/platform/constants'
import { DEFAULT_UI_THEME_ID, isUiThemeId, UI_THEMES, type UiThemeId } from './registry'

let listening = false
const activeTheme = ref<UiThemeId>(DEFAULT_UI_THEME_ID)

function applyTheme(themeId: UiThemeId, persist: boolean) {
  activeTheme.value = themeId

  if (typeof document !== 'undefined') {
    document.documentElement.dataset.uiTheme = themeId
  }

  if (persist && typeof window !== 'undefined') {
    window.localStorage.setItem(UI_THEME_STORAGE_KEY, themeId)
  }
}

export function initializeUiTheme() {
  if (typeof window !== 'undefined' && !listening) {
    listening = true
    window.addEventListener('storage', event => {
      if (event.key === UI_THEME_STORAGE_KEY) {
        applyTheme(isUiThemeId(event.newValue) ? event.newValue : DEFAULT_UI_THEME_ID, false)
      }
    })
  }
  const savedTheme = typeof window === 'undefined' ? null : window.localStorage.getItem(UI_THEME_STORAGE_KEY)
  applyTheme(isUiThemeId(savedTheme) ? savedTheme : DEFAULT_UI_THEME_ID, false)
}

export function useUiTheme() {
  return {
    activeTheme: readonly(activeTheme),
    themes: UI_THEMES,
    setTheme: (themeId: UiThemeId) => applyTheme(themeId, true),
  }
}

export * from './registry'
export type * from './types'
