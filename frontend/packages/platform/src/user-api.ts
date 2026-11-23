import request from './http/request'
import type { Result, UserInfoVO } from '@kite/contracts'

export const getUserInfoApi = async (): Promise<Result<UserInfoVO>> => {
  return request.get('/user/info')
}
