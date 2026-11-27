---
name: 'project-structure'
description: 'Kite 项目目录结构与模块架构规范：Hybrid 架构、业务模块组织、强制边界。Use when creating new business modules, organizing project files, refactoring code structure, or asking about project architecture.'
version: '1.0.0'
tags: ['architecture', 'structure', 'module', 'feature-based', 'hybrid', 'organization']
---

# Project Structure — 目录结构与模块架构

定义 Kite 项目的目录结构、模块划分和强制边界。采用 **Hybrid（按业务 + 公共层）** 架构，参考了 Vue.js core 的 Monorepo 分包、Ant Design 的组件独立目录、字节跳动 Feature-based 模块化等业界实践。

## 何时使用

- 创建新的业务模块
- 决定文件应该放在哪个目录
- 重构现有代码结构
- 新成员了解项目架构
- 代码审查时检查架构边界

## 前置条件

- 理解 `src/core/`、`src/shared/`、`src/modules/` 三层架构的职责
- 了解 Vue 3 + TypeScript 项目结构

---

## 1. 顶层目录结构

```text
Kite/
├── .docs/                    # 项目文档与 SKILL
├── .vscode/                  # VS Code 编辑器配置
├── public/                   # 静态资源（不经过构建）
├── src/
│   ├── core/                 # 框架级能力（与业务无关）
│   ├── shared/               # 跨模块共享代码
│   ├── modules/              # 业务模块
│   ├── layouts/              # 门户布局骨架
│   ├── App.vue               # 根组件
│   └── main.ts               # 入口文件
├── index.html                # HTML 入口
├── package.json
├── tsconfig.json
├── vite.config.ts
└── .prettierrc
```

## 2. 三层架构

### 2.1 `src/core/` — 框架级能力

与业务无关的底层能力，类比 "操作系统内核"。

```text
src/core/
├── api/
│   └── request.ts            # Axios 实例 + 拦截器
├── router/
│   └── index.ts              # 路由配置
├── permission/
│   └── index.ts              # 权限控制
├── plugins/
│   └── index.ts              # 插件注册
├── config/
│   └── index.ts              # 全局配置
└── types/
    └── auto-imports.d.ts     # 自动生成类型声明
```

**规则**：

- 只放框架级能力：Axios、Router、Permission、Plugin、Config
- 不允许放业务代码
- 不允许放 UI 组件
- 不允许放业务常量或类型

### 2.2 `src/shared/` — 跨模块共享

被 **两个及以上** 业务模块复用的代码。

```text
src/shared/
├── components/               # 共享组件
│   ├── CommonHeader.vue
│   └── CommonFooter.vue
├── constants/                # 全局共享常量
│   └── status.ts
├── types/                    # 全局共享类型
│   └── common.ts
├── styles/                   # 全局样式
│   ├── _tokens.scss          # 设计令牌
│   ├── _reset.scss           # 重置样式
│   └── index.scss            # 全局样式入口
├── composables/              # 共享 Composable
│   └── useClipboard.ts
└── utils/                    # 共享工具函数
    └── formatDate.ts
```

**规则**：

- 至少被两个业务模块复用才能放入
- 只有一个模块使用时，应放在模块内部
- 定期清理不再被多处使用的代码

### 2.3 `src/modules/<feature>/` — 业务模块

每个业务模块内部自包含，保持高内聚。

```text
src/modules/blog/
├── pages/                    # 页面组件
│   ├── BlogListPage.vue
│   └── BlogDetailPage.vue
├── components/               # 模块私有组件
│   ├── BlogCard.vue
│   └── BlogEditor.vue
├── api/                      # API 接口
│   ├── article.ts
│   └── comment.ts
├── store/                    # 状态管理
│   └── article.store.ts
├── composables/              # 业务逻辑
│   ├── useBlogList.ts
│   └── useBlogDetail.ts
├── constants/                # 模块常量
│   └── status.ts
├── types/                    # 模块类型
│   ├── article.ts
│   ├── dto.ts
│   └── vo.ts
├── services/                 # 业务服务层
│   └── articleService.ts
└── index.ts                  # 模块对外入口
```

### 2.4 `src/layouts/` — 布局骨架

```text
src/layouts/
├── DefaultLayout.vue         # 默认布局（Header + Sidebar + Main）
├── BlankLayout.vue           # 空白布局（登录页等）
└── AdminLayout.vue           # 管理后台布局
```

## 3. 强制边界（不可逾越）

| 规则                                      | 说明                                                        |
| ----------------------------------------- | ----------------------------------------------------------- |
| 新增业务代码只在 `src/modules/<feature>/` | 不允许在 core/shared 中新增业务代码                         |
| `src/core/` 只放框架级能力                | 不允许放业务代码、UI 组件                                   |
| `src/shared/` 只放被多处复用的代码        | 单一模块使用的代码放模块内部                                |
| 禁止新增全局按层目录                      | 不允许新增全局 `views/`、`components/`、`api/`、`types/` 等 |
| 页面只做展示与协调                        | 业务逻辑进入 composables/services/store                     |
| 网络请求进入 `api/`                       | 不允许在组件中直接调用 Axios                                |

## 4. 模块 index.ts 规范

每个模块的 `index.ts` 是对外入口，统一导出：

```typescript
// src/modules/blog/index.ts

// 页面
export { default as BlogListPage } from './pages/BlogListPage.vue';
export { default as BlogDetailPage } from './pages/BlogDetailPage.vue';

// API
export * from './api/article';
export * from './api/comment';

// 类型
export type * from './types/article';
export type * from './types/dto';

// 常量
export * from './constants/status';

// Composable
export { useBlogList } from './composables/useBlogList';
export { useBlogDetail } from './composables/useBlogDetail';
```

## 5. 目录深度与宽度

| 约束         | 值             | 说明                         |
| ------------ | -------------- | ---------------------------- |
| 最大目录深度 | 4~6 层         | 超过则重新拆分模块           |
| 同级最大子项 | 15~20 个       | 超过则分子目录               |
| 核心原则     | 横向跳转最小化 | 开发一个功能在对应模块内完成 |

## 6. 导入路径规范

```typescript
// ✅ 使用 @/ 别名
import { BlogCard } from '@/modules/blog/components/BlogCard.vue';
import { useBlogList } from '@/modules/blog';

// ✅ 从模块入口导入（推荐）
import { BlogListPage, useBlogList } from '@/modules/blog';

// ✅ 跨模块使用共享代码
import { formatDate } from '@/shared/utils/formatDate';
import { useClipboard } from '@/shared/composables/useClipboard';

// ❌ 禁止相对路径回溯
import { BlogCard } from '../../../components/BlogCard.vue';

// ❌ 禁止模块间直接引用内部文件
import { ArticleVO } from '@/modules/blog/types/article';
// ➡️ 改为：
import type { ArticleVO } from '@/modules/blog';
```

## 边界与限制

- 此架构为 Kite 项目强制规范，所有新增代码必须遵守
- 历史代码中的全局 `components/`、`views/` 等目录逐步迁移到模块内
- 模块间不允许循环依赖
- 模块间共享数据通过 `src/shared/` 或 Pinia store 实现

## 参考

- [Kite 开发规范 - 架构模型](../spec/开发规范.md#1-架构模型)
- [Kite 开发规范 - 强制边界](../spec/开发规范.md#3-强制边界)
- [Vue.js core 仓库结构](https://github.com/vuejs/core)
- [Ant Design 组件目录结构](https://github.com/ant-design/ant-design)
