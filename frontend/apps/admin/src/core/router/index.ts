import { createRouter, createWebHistory } from 'vue-router'
import { ensureAuthorization, hasPermission, isAuthenticated, onAuthChange } from '@kite/platform/auth'
import { ALL_ADMIN_MENU_ITEMS } from '@/modules/admin/constants/menu'
import adminRoutes from './modules/admin.routes'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/login', name: 'admin-login', component: () => import('@/modules/admin/pages/LoginPage.vue') },
    { path: '/forbidden', name: 'admin-forbidden', component: () => import('@/modules/admin/pages/ForbiddenPage.vue') },
    ...adminRoutes,
    { path: '/:pathMatch(.*)*', component: () => import('@/modules/admin/pages/NotFoundPage.vue'), meta: { requiresAuth: true } },
  ],
})

/** Only recognized admin business routes can be used as a login return target. */
export function loginDestination(value: unknown): string {
  if (typeof value !== 'string' || !value.startsWith('/admin/') || value.includes('\\')) return '/'
  const url = new URL(value, window.location.origin)
  if (url.origin !== window.location.origin) return '/'
  const internal = url.pathname.slice('/admin'.length) + url.search + url.hash
  const resolved = router.resolve(internal)
  if (!resolved.matched.some(record => record.meta.requiresAuth) || !resolved.name) return '/'
  if (resolved.matched.some(record => typeof record.meta.permission === 'string' && !hasPermission(record.meta.permission))) return '/'
  return internal
}

const firstAllowed = () => ALL_ADMIN_MENU_ITEMS.find(item => hasPermission(item.permission))?.path
const loginRedirect = (fullPath: string) => ({ name: 'admin-login', query: { redirect: '/admin' + fullPath } })

router.beforeEach(async to => {
  if (to.name === 'admin-login' || to.name === 'admin-forbidden') return true
  try { await ensureAuthorization() }
  catch { return loginRedirect(to.fullPath) }
  if (!isAuthenticated()) return loginRedirect(to.fullPath)
  if (!hasPermission('admin:access') || !firstAllowed()) return { name: 'admin-forbidden' }
  const denied = to.matched.some(record => typeof record.meta.permission === 'string' && !hasPermission(record.meta.permission))
  if (denied) {
    if (to.name === 'admin-home-dashboard') return firstAllowed()!
    return { name: 'admin-forbidden' }
  }
  return true
})

onAuthChange(() => {
  if (!isAuthenticated() && router.currentRoute.value.matched.some(record => record.meta.requiresAuth)) {
    void router.replace(loginRedirect(router.currentRoute.value.fullPath))
  }
})
export default router
