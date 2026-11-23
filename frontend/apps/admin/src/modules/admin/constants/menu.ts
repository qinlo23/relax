import { DataAnalysis, Folder, Grid, House, Menu, Monitor, Picture, User, VideoCamera } from '@element-plus/icons-vue'

export interface AdminMenuItem {
  path: string
  label: string
  icon: unknown
  permission: string
}

export const ADMIN_MENU_ITEMS: AdminMenuItem[] = [
  { path: '/dashboard/overview', label: '控制台', permission: 'dashboard:read', icon: Monitor },
  { path: '/dashboard/content', label: '内容管理', permission: 'content:read', icon: Folder },
  { path: '/dashboard/users', label: '用户管理', permission: 'user:read', icon: User },
  { path: '/dashboard/roles', label: '角色管理', permission: 'role:manage', icon: DataAnalysis },
]

export const ADMIN_HOME_MENU_GROUP = {
  label: '首页展示',
  icon: House,
  items: [
    { path: '/dashboard/spotlight', label: '焦点项目', permission: 'spotlight:read', icon: Picture },
    { path: '/dashboard/features', label: '特性管理', permission: 'feature:read', icon: Grid },
    { path: '/dashboard/hero-video', label: 'Hero 视频', permission: 'hero-video:read', icon: VideoCamera },
    { path: '/dashboard/menu-item', label: '菜单管理', permission: 'menu-item:read', icon: Menu },
  ] satisfies AdminMenuItem[],
}

export const ALL_ADMIN_MENU_ITEMS = [
  ...ADMIN_MENU_ITEMS,
  ...ADMIN_HOME_MENU_GROUP.items,
  { path: '/dashboard/settings', label: '系统设置', permission: 'settings:read', icon: null },
]
