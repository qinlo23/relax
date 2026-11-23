import request from '@kite/platform/http'
import type { Result } from '@kite/contracts'

/** 价格中心分类接口 */
export const categoryApi = {
  /** 获取分类树 — GET /category/tree（后端当前为空实现，返回 null） */
  getTree(): Promise<Result<null>> {
    return request.get('/category/tree')
  },

  /** 删除分类 — DELETE /category/{id}（后端当前为空实现） */
  deleteById(id: number): Promise<Result<null>> {
    return request.delete(`/category/${id}`)
  },
}
