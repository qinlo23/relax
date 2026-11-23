import request from './http/request'
import type { Result, FeatureItem, SpotlightItem, HeroVideoItem, MenuItemVO } from '@kite/contracts'

export const featureApi = { list: (): Promise<Result<FeatureItem[]>> => request.get('/admin/feature') }
export const spotlightApi = { list: (): Promise<Result<SpotlightItem[]>> => request.get('/admin/spotlight') }
export const heroVideoApi = { active: (): Promise<Result<HeroVideoItem | null>> => request.get('/public/hero-video/active') }
export const menuItemApi = { listEnabled: (): Promise<Result<MenuItemVO[]>> => request.get('/public/menu-item/list') }
