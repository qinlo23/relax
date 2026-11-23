import request from '@kite/platform/http'
import type { HeroVideoDTO } from '@/modules/admin/types'
import type { HeroVideoItem, PageResult, Result } from '@kite/contracts'

const HERO_VIDEO_BASE_URL = '/admin/hero-video'

/** 构建 multipart 请求体，跳过空值 */
function toFormData(data: HeroVideoDTO): FormData {
  const formData = new FormData()
  Object.entries(data).forEach(([key, value]) => {
    if (value !== undefined && value !== null) {
      formData.append(key, value as string | Blob)
    }
  })
  return formData
}

/** Hero 视频：管理端接口要求 ADMIN，公开读接口免登录 */
export const heroVideoApi = {
  /** 分页获取全部 Hero 视频 — GET /admin/hero-video/page */
  page(pageNum = 1, pageSize = 10): Promise<Result<PageResult<HeroVideoItem>>> {
    return request.get(`${HERO_VIDEO_BASE_URL}/page`, { params: { pageNum, pageSize } })
  },

  /** 获取单条 Hero 视频 — GET /admin/hero-video/{id} */
  getById(id: number): Promise<Result<HeroVideoItem>> {
    return request.get(`${HERO_VIDEO_BASE_URL}/${id}`)
  },

  /** 新增 Hero 视频 — POST /admin/hero-video（multipart，video 必传） */
  create(data: HeroVideoDTO): Promise<Result<number>> {
    return request.post(HERO_VIDEO_BASE_URL, toFormData(data))
  },

  /** 更新 Hero 视频 — PUT /admin/hero-video/{id}（multipart，不传 video 表示保留原视频） */
  update(id: number, data: HeroVideoDTO): Promise<Result<null>> {
    return request.put(`${HERO_VIDEO_BASE_URL}/${id}`, toFormData(data))
  },

  /** 删除 Hero 视频 — DELETE /admin/hero-video/{id} */
  deleteById(id: number): Promise<Result<null>> {
    return request.delete(`${HERO_VIDEO_BASE_URL}/${id}`)
  },

  /** 启用/禁用 Hero 视频 — PUT /admin/hero-video/{id}/status */
  updateStatus(id: number, status: number): Promise<Result<null>> {
    return request.put(`${HERO_VIDEO_BASE_URL}/${id}/status`, null, { params: { status } })
  },
}
