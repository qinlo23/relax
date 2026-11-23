import request from '@kite/platform/http'
import type { Result } from '@kite/contracts'

/** 价格中心来源接口 */
export const sourceApi = {
  /** 删除来源 — DELETE /source/{id}（后端当前为空实现） */
  deleteById(id: number): Promise<Result<null>> {
    return request.delete(`/source/${id}`)
  },
}
