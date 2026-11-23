import assert from 'node:assert/strict'
import { chromium } from 'playwright'

// Run against a local Vite server; API responses are mocked so no account or business data is changed.
const origin = process.env.RBAC_UI_URL || 'http://127.0.0.1:5179'
const browser = await chromium.launch({ headless: true })
const user = {
  id: 2, userCode: 'test', userName: 'tester', nickname: '测试用户', email: 'test@example.com',
  phone: '', remark: '', avatarUrl: '', role: 'USER', roles: ['USER'], permissions: [], createTime: '',
}
const roleList = [
  { id: 1, roleCode: 'SUPER_ADMIN', roleName: '超级管理员', builtIn: true, enabled: true },
  { id: 2, roleCode: 'USER', roleName: '普通用户', builtIn: true, enabled: true },
  { id: 3, roleCode: 'EDITOR', roleName: '运营', builtIn: false, enabled: true },
]
const record = { ...user, username: 'tester', status: 0, roles: [roleList[1]] }
const feature = { id: 1, icon: 'star', title: '示例特性', description: '', sortOrder: 0 }
const pageResult = records => ({ records, total: records.length, currentPage: 1, pageSize: 10, totalPage: 1 })

async function session(access, { authenticated = true, forgedCache = false } = {}) {
  const context = await browser.newContext()
  const page = await context.newPage()
  const errors = []
  const requests = []
  let expire = false
  let loginCount = 0
  page.on('pageerror', error => { errors.push(error.message); console.error('Browser error:', error.message) })
  await context.addInitScript(({ authenticated, cached }) => {
    if (authenticated && !localStorage.getItem('__test_seeded')) {
      localStorage.setItem('__test_seeded', 'true')
      for (const scope of ['front', 'admin']) {
        localStorage.setItem('kite_' + scope + '_token', scope + '-test-session')
        localStorage.setItem('kite_' + scope + '_auth_session', JSON.stringify(cached))
      }
    }
  }, { authenticated, cached: forgedCache ? { ...user, roles: ['SUPER_ADMIN'], permissions: ['admin:access', 'feature:create'] } : access })
  await context.route(url => url.origin === new URL(origin).origin && url.pathname.startsWith('/api/'), async route => {
    const request = route.request()
    const path = new URL(request.url()).pathname
    requests.push({ path, method: request.method(), body: request.postDataJSON(), authorization: request.headers().authorization })
    if (expire && path.startsWith('/api/admin/feature/page')) {
      return route.fulfill({ status: 401, json: { code: 401002, message: '登录已失效', data: null } })
    }
    let data = []
    if (path === '/api/user/info') data = access
    else if (path.startsWith('/api/auth/login-')) data = 'test-session-' + (++loginCount)
    else if (path === '/api/public/hero-video/active') data = null
    else if (path === '/api/admin/feature/page') data = pageResult([feature])
    else if (path === '/api/admin/user-do') data = pageResult([record])
    else if (path === '/api/admin/role-do') data = roleList
    else if (path === '/api/admin/role-do/permissions') data = [
      { code: 'admin:access', name: '进入后台', module: '后台' },
      { code: 'feature:read', name: '查看', module: '特性管理' },
      { code: 'feature:update', name: '编辑', module: '特性管理' },
    ]
    else if (path === '/api/admin/role-do/3/permissions' && request.method() === 'GET') data = ['admin:access', 'feature:read']
    return route.fulfill({ json: { code: 200, message: '成功', data } })
  })
  return { context, page, errors, requests, expire: () => { expire = true } }
}

async function login(page) {
  const form = page.locator('.login-panel')
  await form.getByRole('tab', { name: '密码登录' }).click()
  await form.getByPlaceholder('请输入邮箱地址').fill('test@example.com')
  await form.getByPlaceholder('请输入密码', { exact: true }).fill('test-password')
  await form.getByRole('button', { name: '登录', exact: true }).click()
}

try {
  {
    const s = await session(user, { authenticated: false })
    await s.page.goto(`${origin}/admin/dashboard/users`)
    await s.page.waitForURL(url => url.pathname === '/admin/login')
    assert.equal(await s.page.locator('.admin-shell').count(), 0)
    assert(!s.requests.some(request => request.path === '/api/admin/user-do'))
    await s.context.close()
    console.log('PASS anonymous direct admin route is blocked')
  }
  {
    const s = await session(user, { forgedCache: true })
    await s.page.goto(`${origin}/admin/dashboard/features`)
    await s.page.waitForURL(`${origin}/admin/forbidden`)
    assert.equal(await s.page.locator('.admin-shell').count(), 0)
    assert(!s.requests.some(request => request.path === '/api/admin/feature/page'))
    await s.context.close()
    console.log('PASS local role/permission cache cannot grant admin access')
  }
  {
    const access = { ...user, roles: ['USER', 'EDITOR'], permissions: ['admin:access', 'feature:read'] }
    const s = await session(access)
    await s.page.goto(`${origin}/admin`)
    await s.page.waitForURL(`${origin}/admin/dashboard/features`)
    await s.page.getByText('示例特性', { exact: true }).waitFor()
    assert.equal(await s.page.getByRole('button', { name: '新增特性', exact: true }).isVisible(), false)
    assert.equal(await s.page.getByRole('button', { name: '编辑', exact: true }).isVisible(), false)
    assert.equal(await s.page.getByRole('button', { name: '删除', exact: true }).isVisible(), false)
    assert.equal(await s.page.locator('.admin-shell__nav a').count(), 1)
    await s.page.reload()
    await s.page.getByText('示例特性', { exact: true }).waitFor()
    assert.equal(s.errors.length, 0, s.errors.join('\n'))
    s.expire()
    await s.page.reload()
    await s.page.waitForURL(url => url.pathname === '/admin/login')
    assert.equal(await s.page.evaluate(() => localStorage.getItem('kite_admin_token')), null)
    await s.context.close()
    console.log('PASS read-only menu/buttons, first authorized page, refresh and 401 logout')
  }
  {
    const s = await session({ ...user, roles: ['SUPPORT'], permissions: ['admin:access', 'user:read'] })
    await s.page.goto(`${origin}/admin/dashboard/users`)
    await s.page.locator('.manage-panel__table').getByText('tester', { exact: true }).waitFor()
    for (const name of ['新增用户', '编辑', '删除', '重置密码', '分配角色']) {
      assert.equal(await s.page.getByRole('button', { name, exact: true }).isVisible(), false)
    }
    assert(!s.requests.some(request => request.path === '/api/admin/role-do'))
    await s.page.goto(`${origin}/admin/dashboard/roles`)
    await s.page.waitForURL(`${origin}/admin/forbidden`)
    assert(!s.requests.some(request => request.path === '/api/admin/role-do'))
    assert.equal(s.errors.length, 0, s.errors.join('\n'))
    await s.context.close()
    console.log('PASS read-only user management cannot read or change role configuration')
  }
  {
    const access = { ...user, roles: ['SUPER_ADMIN'], permissions: ['admin:access', 'dashboard:read', 'user:read', 'user:create', 'user:update', 'user:delete', 'user:status', 'user:reset-password', 'feature:read'] }
    const s = await session(access)
    await s.page.goto(`${origin}/admin/dashboard/users`)
    await s.page.getByRole('button', { name: '分配角色', exact: true }).click()
    const assignment = s.page.getByRole('dialog', { name: '分配角色' })
    await assignment.locator('.el-select').click()
    await s.page.getByRole('option', { name: '运营', exact: true }).click()
    await s.page.keyboard.press('Escape')
    await assignment.getByRole('button', { name: '保存', exact: true }).click()
    await assignment.waitFor({ state: 'hidden' })
    const grant = s.requests.find(request => request.path === '/api/admin/user-do/2/roles' && request.method === 'PUT')
    assert.deepEqual(grant?.body, { roleIds: [2, 3] })
    await s.page.locator('.admin-shell__nav').getByRole('link', { name: '角色管理', exact: true }).click()
    await s.page.getByRole('button', { name: '配置权限', exact: true }).click()
    const permissions = s.page.getByRole('dialog', { name: '配置权限：运营' })
    await permissions.locator('label.el-checkbox').filter({ hasText: '编辑' }).click()
    assert.equal(await permissions.getByRole('checkbox', { name: '编辑', exact: true }).isChecked(), true)
    await permissions.getByRole('button', { name: '保存', exact: true }).click()
    await permissions.waitFor({ state: 'hidden' })
    const configured = s.requests.find(request => request.path === '/api/admin/role-do/3/permissions' && request.method === 'PUT')
    assert(configured?.body.permissions.includes('feature:update'))
    assert.equal(await s.page.getByRole('button', { name: '配置权限', exact: true }).count(), 1)
    assert.equal(s.errors.length, 0, s.errors.join('\n'))
    await s.page.goto(`${origin}/`)
    await s.page.waitForURL(`${origin}/`)
    assert.equal(await s.page.locator('.admin-shell').count(), 0)
    await s.context.close()
    console.log('PASS multi-role assignment, grouped permissions, protected built-ins and admin access to front pages')
  }

  {
    const access = { ...user, roles: ['EDITOR'], permissions: ['admin:access', 'feature:read'] }
    const s = await session(access, { authenticated: false })
    await s.page.goto(origin + '/admin/dashboard/features')
    await s.page.waitForURL(url => url.pathname === '/admin/login')
    assert.equal(new URL(s.page.url()).searchParams.get('redirect'), '/admin/dashboard/features')
    await s.page.reload()
    await login(s.page)
    await s.page.waitForURL(origin + '/admin/dashboard/features')
    const otherAdmin = await s.context.newPage()
    await otherAdmin.goto(origin + '/admin/dashboard/features')
    await otherAdmin.waitForURL(origin + '/admin/dashboard/features')
    const front = await s.context.newPage()
    await front.goto(origin + '/profile')
    await front.waitForURL(origin + '/')
    assert.equal(await front.evaluate(() => localStorage.getItem('kite_front_token')), null)
    await s.page.locator('.admin-shell__profile').click()
    await s.page.getByText('退出登录', { exact: true }).click()
    await s.page.waitForURL(url => url.pathname === '/admin/login')
    await otherAdmin.waitForURL(url => url.pathname === '/admin/login')
    assert.equal(await front.evaluate(() => localStorage.getItem('kite_front_token')), null)
    assert.equal(s.errors.length, 0, s.errors.join('\n'))
    await s.context.close()
    console.log('PASS admin login does not log in web; logout synchronizes only admin tabs')
  }
  {
    const access = { ...user, roles: ['EDITOR'], permissions: ['admin:access', 'feature:read'] }
    const s = await session(access, { authenticated: false })
    await s.page.goto(origin + '/admin/login?redirect=' + encodeURIComponent('https://example.com/admin/dashboard/features'))
    await login(s.page)
    await s.page.waitForURL(origin + '/admin/dashboard/features')
    assert.equal(await s.page.getByRole('link', { name: '返回前台', exact: true }).count(), 0)
    assert.equal(s.errors.length, 0, s.errors.join('\n'))
    await s.context.close()
    console.log('PASS unsafe return URL rejected; admin does not depend on web navigation')
  }
  for (const target of ['/admin/login', '//example.com/admin/', '/admin/dashboard/users']) {
    const access = { ...user, permissions: ['admin:access', 'feature:read'] }
    const s = await session(access, { authenticated: false })
    await s.page.goto(origin + '/admin/login?redirect=' + encodeURIComponent(target))
    await login(s.page)
    await s.page.waitForURL(origin + '/admin/dashboard/features')
    await s.context.close()
  }
  console.log('PASS recursive, external and unauthorized login return targets use authorized fallback')
  {
    const s = await session(user, { authenticated: false })
    await s.page.goto(origin + '/admin/login')
    await login(s.page)
    await s.page.waitForURL(origin + '/admin/forbidden')
    assert(!s.requests.some(request => request.path.startsWith('/api/admin/')))
    await s.context.close()
    console.log('PASS authenticated users without admin access see the forbidden page')
  }
  {
    const access = { ...user, permissions: ['admin:access', 'settings:read'] }
    const s = await session(access)
    const front = await s.context.newPage()
    await front.goto(origin + '/')
    await s.page.goto(origin + '/admin/dashboard/settings')
    await s.page.getByRole('radio').nth(1).click()
    const selected = await s.page.evaluate(() => document.documentElement.dataset.uiTheme)
    assert.notEqual(await front.evaluate(() => document.documentElement.dataset.uiTheme), selected)
    const otherAdmin = await s.context.newPage()
    await otherAdmin.goto(origin + '/admin/dashboard/settings')
    await otherAdmin.waitForFunction(theme => document.documentElement.dataset.uiTheme === theme, selected)
    await front.reload()
    assert.notEqual(await front.evaluate(() => document.documentElement.dataset.uiTheme), selected)
    await s.page.setViewportSize({ width: 390, height: 844 })
    await s.page.goto(origin + '/admin/login')
    await s.page.getByRole('tab', { name: '密码登录' }).click()
    assert.equal(await s.page.getByPlaceholder('请输入密码', { exact: true }).isVisible(), true)
    assert.equal(await s.page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth), true)
    await s.context.close()
    console.log('PASS themes are app-local; admin tabs synchronize and mobile login renders')
  }
  {
    const access = { ...user, permissions: ['admin:access', 'feature:read'] }
    const s = await session(access, { authenticated: false })
    await s.page.goto(origin + '/')
    await s.page.getByRole('button', { name: '登录', exact: true }).click()
    await login(s.page)
    await s.page.getByRole('link', { name: '我的', exact: true }).waitFor()
    assert.equal(new URL(s.page.url()).pathname, '/')
    await s.page.goto(origin + '/profile')
    const admin = await s.context.newPage()
    await admin.goto(origin + '/admin/dashboard/features')
    await admin.waitForURL(url => url.pathname === '/admin/login')
    await login(admin)
    await admin.waitForURL(origin + '/admin/dashboard/features')
    const tokens = await admin.evaluate(() => [localStorage.getItem('kite_front_token'), localStorage.getItem('kite_admin_token')])
    assert(tokens[0] && tokens[1] && tokens[0] !== tokens[1])
    await s.page.getByRole('button', { name: '退出登录', exact: true }).click()
    await s.page.waitForURL(origin + '/')
    await admin.reload()
    await admin.getByText('示例特性', { exact: true }).waitFor()
    assert.equal(await admin.evaluate(() => localStorage.getItem('kite_admin_token')), tokens[1])
    // Log web back in, then verify admin logout leaves web authenticated.
    await s.page.getByRole('button', { name: '登录', exact: true }).click()
    await login(s.page)
    await s.page.getByRole('link', { name: '我的', exact: true }).waitFor()
    await s.page.goto(origin + '/profile')
    const webToken = await s.page.evaluate(() => localStorage.getItem('kite_front_token'))
    await admin.locator('.admin-shell__profile').click()
    await admin.getByText('退出登录', { exact: true }).click()
    await admin.waitForURL(url => url.pathname === '/admin/login')
    await s.page.reload()
    await s.page.waitForURL(origin + '/profile')
    assert.equal(await s.page.evaluate(() => localStorage.getItem('kite_front_token')), webToken)
    const logouts = s.requests.filter(request => request.path === '/api/auth/logout')
    assert.deepEqual(logouts.map(request => request.authorization), ['Bearer ' + tokens[0], 'Bearer ' + tokens[1]])
    await s.context.close()
    console.log('PASS independent tokens and Authorization headers; logout in either app preserves the other')
  }
} finally {
  await browser.close()
}
