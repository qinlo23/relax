import { createRouter, createWebHistory } from 'vue-router'
import { ElMessage } from 'element-plus'
import { isAuthenticated, ensureAuthorization, onAuthChange } from '@kite/platform/auth'
import frontRoutes from './modules/front.routes'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [...frontRoutes, { path: '/:pathMatch(.*)*', component: () => import('@/modules/home/pages/NotFoundPage.vue') }],
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) return savedPosition
    if (to.hash) return { el: to.hash, behavior: 'smooth' }
    return { top: 0 }
  },
})
router.beforeEach(async to => {
  const protectedPage = to.matched.some(record => record.meta.requiresAuth)
  try { await ensureAuthorization() }
  catch { if (protectedPage) return { name: 'front-home' } }
  if (protectedPage && !isAuthenticated()) {
    ElMessage.warning('请先登录以访问此页面')
    return { name: 'front-home' }
  }
  return true
})
onAuthChange(() => {
  if (!isAuthenticated() && router.currentRoute.value.matched.some(record => record.meta.requiresAuth)) {
    void router.replace({ name: 'front-home' })
  }
})
export default router
