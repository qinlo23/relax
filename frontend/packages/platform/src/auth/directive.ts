import { shallowRef, watchEffect } from 'vue'
import type { ObjectDirective, ShallowRef } from 'vue'
import { hasPermission } from './auth'

type PermissionState = { permission: ShallowRef<string>; display: string; stop: () => void }
const states = new WeakMap<HTMLElement, PermissionState>()
const updateVisibility = (el: HTMLElement, state: PermissionState) => {
  el.style.display = hasPermission(state.permission.value) ? state.display : 'none'
}

// Updates immediately for session changes and for dynamic permission bindings.
export const permissionDirective: ObjectDirective<HTMLElement, string> = {
  mounted(el, binding) {
    const state = { permission: shallowRef(binding.value), display: el.style.display, stop: () => {} }
    state.stop = watchEffect(() => updateVisibility(el, state))
    states.set(el, state)
  },
  updated(el, binding) {
    const state = states.get(el)
    if (state) { state.permission.value = binding.value; updateVisibility(el, state) }
  },
  unmounted(el) { states.get(el)?.stop(); states.delete(el) },
}
