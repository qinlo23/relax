import type { UserInfoVO } from '@kite/contracts'
import projectImageOne from '@kite/ui/assets/ui/default-avatar.png'

// 默认用户信息，用于未登录状态下的展示
export const EXAMPLE_PUBLIC_PROFILE_DEFAULTS: UserInfoVO = {
  id: 0,
  userCode: '',
  userName: '默认用户A',
  nickname: '默认昵称A',
  email: '123@qq.comA',
  phone: '110A',
  remark: '默认备注A',
  role: 'UserA',
  roles: [],
  permissions: [],
  avatarUrl: projectImageOne as string,
  createTime: '',
}