<!-- Monorepo：跨应用复用进入 packages/contracts、platform、ui；应用内保留 core/modules/shared/layouts。统一命令与部署见 README.md。 -->
# Kite — AI Agent 项目指令

## 项目概述

Kite 是一个 **Vue 3 + TypeScript + Element Plus** 全栈前端项目，采用 **Hybrid（按业务模块 + 公共层）** 架构。项目包含 blog、admin、user、home、price、ai、meditation、story 等业务模块。

## 技术栈

| 类别     | 技术                                          |
| -------- | --------------------------------------------- |
| 框架     | Vue 3.5（Composition API + `<script setup>`） |
| 语言     | TypeScript 6.x（strict 模式）                 |
| 构建     | Vite 7.x                                      |
| UI 库    | Element Plus 2.x                              |
| 状态管理 | Pinia 3.x                                     |
| 路由     | Vue Router 5.x                                |
| HTTP     | Axios                                         |
| 样式     | SCSS + BEM                                    |
| 图表     | ECharts 6.x + vue-echarts                     |
| Markdown | marked                                        |

## 项目架构

```
src/
├── core/          # 框架级能力（Axios、Router、权限、配置）
├── shared/        # 跨模块复用（组件、样式、类型、常量）
├── modules/       # 业务模块（home、blog、admin、user、price、ai 等）
│   └── <feature>/
│       ├── pages/        # 页面组件
│       ├── components/   # 模块私有组件
│       ├── api/          # API 接口
│       ├── store/        # Pinia store
│       ├── composables/  # 业务逻辑
│       ├── constants/    # 模块常量
│       ├── types/        # 类型定义
│       ├── services/     # 业务服务
│       └── index.ts      # 模块对外入口
└── layouts/       # 布局骨架（FrontLayout、AdminLayout）
```

## 知识库

本项目的领域规范以 **SKILL** 形式组织在 `.docs/` 目录下。遇到以下场景时，请主动查阅对应 SKILL：

| 场景                                        | SKILL                                                         |
| ------------------------------------------- | ------------------------------------------------------------- |
| 创建组件、设计 Props/Emits、抽取 Composable | [component-guide](.docs/component-guide/SKILL.md)             |
| 定义类型、接口、泛型、配置 tsconfig         | [typescript-guide](.docs/typescript-guide/SKILL.md)           |
| 创建 API 模块、封装请求、处理错误           | [api-guide](.docs/api-guide/SKILL.md)                         |
| 命名文件/变量/组件/CSS 类名                 | [naming-convention](.docs/naming-convention/SKILL.md)         |
| 创建业务模块、组织目录结构                  | [project-structure](.docs/project-structure/SKILL.md)         |
| 配置 ESLint/Prettier/Stylelint              | [code-style](.docs/code-style/SKILL.md)                       |
| Git 提交、分支策略、commit message          | [git-workflow](.docs/git-workflow/SKILL.md)                   |
| 构建配置、环境变量、依赖管理                | [engineering-toolchain](.docs/engineering-toolchain/SKILL.md) |
| 项目整体架构与编码规范                      | [开发规范](.docs/spec/开发规范.md)                            |

## 核心行为准则

### 1. 代码放置规则（强制）

- **新增业务代码** → 只能放在 `apps/<app>/src/modules/<feature>/` 下
- **框架级能力** → 只能放在 `apps/<app>/src/core/`（Axios、Router、权限、配置）
- **跨模块复用** → 只能放在 `apps/<app>/src/shared/`（至少被两个模块使用）
- **禁止** 新增全局 `views/`、`components/`、`api/`、`types/`、`constants/` 等按层目录

### 2. 页面与逻辑分离（强制）

- 页面组件只做展示与协调，**禁止堆积业务代码**
- 业务逻辑放入 `composables/`、`services/` 或 `store/`
- 网络请求必须通过 `api/` 层，**禁止在组件中直接调用 Axios**

### 3. 代码风格

- 使用 `<script setup lang="ts">` 语法
- SCSS 必须 `scoped`，使用 BEM 命名
- 使用 `@/` 别名导入，禁止相对路径回溯（`../../../`）
- 优先从模块 `index.ts` 入口导入
- 禁止使用 `any`，优先 `unknown` 或具体类型
- 禁止在代码中保留 mock 数据

### 4. 命名速查

| 对象          | 风格                     | 示例                              |
| ------------- | ------------------------ | --------------------------------- |
| Vue 页面      | PascalCase + `Page` 后缀 | `BlogListPage.vue`                |
| Vue 组件      | PascalCase               | `BlogCard.vue`                    |
| Composable    | camelCase + `use` 前缀   | `useBlogDetail.ts`                |
| Store         | dot.case + `.store` 后缀 | `article.store.ts`                |
| 目录/普通文件 | kebab-case               | `user-profile/`、`format-date.ts` |
| 变量/函数     | camelCase                | `getUserInfo`、`isLoading`        |
| 常量          | UPPER_SNAKE_CASE         | `MAX_PAGE_SIZE`                   |
| 类型/接口     | PascalCase               | `UserInfo`、`ArticleVO`           |

### 5. 导入顺序

```typescript
// 1. Vue 核心
import { ref, computed, onMounted } from 'vue';

// 2. 第三方库
import { ElMessage } from 'element-plus';

// 3. 类型导入
import type { ArticleVO } from '@/modules/blog';

// 4. 项目内模块
import { useBlogList } from '@/modules/blog';
import { formatDate } from '@/shared/utils/formatDate';
```

### 6. 验证命令

```bash
pnpm type-check   # 提交前必做：TypeScript 类型检查
pnpm build        # 涉及构建配置或新增依赖时执行
pnpm dev          # 启动开发服务器
```

## 禁止事项

- ❌ 在 `apps/<app>/src/core/` 中放业务代码
- ❌ 在组件中直接调用 Axios
- ❌ 使用 `any` 类型
- ❌ 使用 `@ts-ignore`（用 `@ts-expect-error` 替代）
- ❌ 使用拼音命名
- ❌ 使用相对路径回溯（`../../../`）
- ❌ 硬编码颜色值（使用 `_tokens.scss`）
- ❌ 保留 mock 数据或注释中的 mock 数据块
- ❌ 在页面组件中堆积业务逻辑
- ❌ 新增全局按层目录（`views/`、`components/` 等）

## 文件生成规则

- 创建新文件前，先确认它属于哪个模块 / 层级
- 创建新组件时，遵循 [component-guide](.docs/component-guide/SKILL.md) 中的模板结构
- 创建新 API 模块时，遵循 [api-guide](.docs/api-guide/SKILL.md) 中的命名和封装规范
- 创建新类型时，遵循 [typescript-guide](.docs/typescript-guide/SKILL.md) 中的 DTO/VO 模式
- 不主动创建文档文件（`.md`），除非用户明确要求
