---
name: 'engineering-toolchain'
description: 'Kite 项目工程化工具链规范：Vite 构建、环境变量、包管理、CI/CD、Node 版本管理。Use when configuring build tools, setting up environment variables, managing dependencies, configuring CI/CD pipelines, or troubleshooting build issues.'
version: '1.0.0'
tags: ['engineering', 'vite', 'build', 'env', 'ci-cd', 'dependencies', 'node', 'toolchain']
---

# Engineering Toolchain — 工程化工具链规范

定义 Kite 项目的工程化工具链配置规范，包括 Vite 构建配置、环境变量管理、依赖管理、Node 版本控制、CI/CD 流水线。参考 Vue 3 官方脚手架、Vite 官方文档、各大厂前端工程化实践。

## 何时使用

- 配置或修改 Vite 构建参数
- 新增环境变量
- 管理项目依赖（安装/升级/删除）
- 配置 CI/CD 流水线
- 统一团队 Node 版本
- 排查构建问题

## 前置条件

- Node.js >= 18
- 使用 pnpm 作为包管理器（推荐）
- 项目基于 Vite 构建

---

## 1. Node 版本管理

### 1.1 .nvmrc

```text
# .nvmrc
18.20.0
```

### 1.2 package.json engines

```json
{
  "engines": {
    "node": ">=18.0.0",
    "pnpm": ">=8.0.0"
  }
}
```

### 1.3 使用方式

```bash
# 自动切换到项目指定 Node 版本
nvm use

# 检查版本
node -v
pnpm -v
```

## 2. 包管理器规范

### 2.1 推荐 pnpm

| 特性          | pnpm                 | npm             | yarn            |
| ------------- | -------------------- | --------------- | --------------- |
| 磁盘空间      | 硬链接共享，最省空间 | 每个项目独立    | 每个项目独立    |
| 安装速度      | 快                   | 慢              | 中等            |
| Monorepo 支持 | 原生支持             | 需要 workspaces | 需要 workspaces |
| 幽灵依赖      | 严格隔离             | 存在            | 存在            |

### 2.2 依赖管理规则

```bash
# 安装生产依赖
pnpm add <package>

# 安装开发依赖
pnpm add -D <package>

# 全局安装（不推荐，除非 CLI 工具）
pnpm add -g <package>

# 升级依赖
pnpm update <package>
pnpm update <package>@latest

# 删除依赖
pnpm remove <package>

# 清理缓存
pnpm store prune
```

### 2.3 版本锁定

- `pnpm-lock.yaml` 必须提交到 Git
- 禁止手动修改 lock 文件
- 依赖版本使用 `^` 前缀（允许补丁和次版本更新）
- 关键依赖使用精确版本（如 `vite: "5.4.0"`）

### 2.4 依赖分类

```json
{
  "dependencies": {
    "vue": "^3.4.0",
    "vue-router": "^4.3.0",
    "pinia": "^2.1.0",
    "axios": "^1.7.0",
    "element-plus": "^2.8.0"
  },
  "devDependencies": {
    "typescript": "^5.5.0",
    "vite": "^5.4.0",
    "@vitejs/plugin-vue": "^5.1.0",
    "vue-tsc": "^2.0.0",
    "sass": "^1.77.0",
    "eslint": "^9.0.0",
    "prettier": "^3.3.0",
    "husky": "^9.0.0",
    "lint-staged": "^15.0.0",
    "@commitlint/cli": "^19.0.0",
    "@commitlint/config-conventional": "^19.0.0"
  }
}
```

## 3. Vite 配置规范

### 3.1 基础配置

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import { resolve } from 'path';
import AutoImport from 'unplugin-auto-import/vite';
import Components from 'unplugin-vue-components/vite';
import { ElementPlusResolver } from 'unplugin-vue-components/resolvers';

export default defineConfig(({ mode }) => ({
  plugins: [
    vue(),
    AutoImport({
      resolvers: [ElementPlusResolver()],
      imports: ['vue', 'vue-router', 'pinia'],
      dts: 'auto-imports.d.ts',
    }),
    Components({
      resolvers: [ElementPlusResolver()],
      dts: 'components.d.ts',
    }),
  ],

  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
    },
  },

  css: {
    preprocessorOptions: {
      scss: {
        // 全局注入 SCSS 变量和 mixin
        additionalData: `@use "@/shared/styles/_tokens.scss" as *;`,
      },
    },
  },

  server: {
    port: 3000,
    open: true,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },

  build: {
    outDir: 'dist',
    sourcemap: mode === 'development',
    rollupOptions: {
      output: {
        manualChunks: {
          // 按依赖分包
          'element-plus': ['element-plus'],
          'vue-vendor': ['vue', 'vue-router', 'pinia'],
          echarts: ['echarts'],
        },
      },
    },
  },
}));
```

### 3.2 构建优化检查清单

- [ ] 按依赖分包（`manualChunks`）减少单文件体积
- [ ] 生产环境关闭 sourcemap
- [ ] 启用 gzip 压缩（`vite-plugin-compression`）
- [ ] 图片资源使用 `assetsInlineLimit` 控制内联阈值
- [ ] 路由懒加载（`() => import()`）

## 4. 环境变量管理

### 4.1 文件组织

```text
.env                    # 所有环境通用
.env.development        # 开发环境
.env.production         # 生产环境
.env.staging            # 预发布环境（可选）
.env.local              # 本地覆盖（不提交 Git）
```

### 4.2 变量命名规范

```bash
# .env
VITE_APP_TITLE=Kite Admin

# .env.development
VITE_API_BASE_URL=http://localhost:8080/api
VITE_APP_DEBUG=true

# .env.production
VITE_API_BASE_URL=https://api.example.com
VITE_APP_DEBUG=false
```

### 4.3 使用方式

```typescript
// 代码中使用
const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;
const isDebug = import.meta.env.VITE_APP_DEBUG === 'true';

// ❌ 禁止
const apiBaseUrl = process.env.VITE_API_BASE_URL; // Vite 中无效
```

### 4.4 类型声明

```typescript
// src/core/types/env.d.ts
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_APP_TITLE: string;
  readonly VITE_API_BASE_URL: string;
  readonly VITE_APP_DEBUG: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
```

## 5. package.json scripts

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vue-tsc --noEmit && vite build",
    "preview": "vite preview",
    "type-check": "vue-tsc --noEmit",
    "lint": "eslint . --ext .ts,.vue --fix",
    "lint:style": "stylelint \"src/**/*.{css,scss,vue}\" --fix",
    "format": "prettier --write \"src/**/*.{ts,vue,scss,json}\"",
    "lint:all": "npm run lint && npm run lint:style && npm run format",
    "prepare": "husky",
    "clean": "rm -rf dist node_modules"
  }
}
```

### scripts 说明

| 命令         | 用途                | 执行时机                  |
| ------------ | ------------------- | ------------------------- |
| `dev`        | 启动开发服务器      | 日常开发                  |
| `build`      | 类型检查 + 生产构建 | 提交前 / 部署前           |
| `preview`    | 预览构建产物        | 部署前验证                |
| `type-check` | 仅类型检查          | 提交前（快速验证）        |
| `lint`       | ESLint 检查         | 提交前                    |
| `lint:style` | Stylelint 检查      | 提交前                    |
| `format`     | Prettier 格式化     | 提交前 / 手动             |
| `lint:all`   | 全部检查            | CI / 手动                 |
| `prepare`    | Husky 初始化        | `pnpm install` 后自动执行 |
| `clean`      | 清理构建产物和依赖  | 遇到奇怪问题时            |

## 6. CI/CD 建议

### 6.1 GitHub Actions 示例

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint-and-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
      - uses: actions/setup-node@v4
        with:
          node-version: 18
          cache: 'pnpm'

      - run: pnpm install --frozen-lockfile
      - run: pnpm run type-check
      - run: pnpm run lint:all
      - run: pnpm run build
```

### 6.2 CI 检查清单

- [ ] `pnpm install --frozen-lockfile`（严格按 lock 文件安装）
- [ ] `type-check`（类型检查）
- [ ] `lint:all`（ESLint + Stylelint + Prettier）
- [ ] `build`（生产构建）
- [ ] 单元测试（如有）
- [ ] E2E 测试（如有）

## 7. 项目初始化清单

新成员加入或新机器搭建项目时按此顺序执行：

```bash
# 1. 确认 Node 版本
node -v  # >= 18

# 2. 安装 pnpm
npm install -g pnpm

# 3. 克隆项目
git clone <repo-url>
cd Kite

# 4. 安装依赖
pnpm install

# 5. 配置环境变量
cp .env.development .env.local
# 编辑 .env.local 填入本地配置

# 6. 启动开发服务器
pnpm run dev

# 7. 验证构建
pnpm run build
```

## 边界与限制

- 环境变量必须以 `VITE_` 为前缀
- 敏感信息（密钥、Token）不允许放在 `.env` 文件中，使用 `.env.local`（已加入 `.gitignore`）
- 不允许在 `vite.config.ts` 中硬编码环境特定的值
- 构建失败时不允许合并到 main 分支

## 参考

- [Vite 官方文档](https://vitejs.dev/)
- [pnpm 官方文档](https://pnpm.io/)
- [Vue 3 官方脚手架 create-vue](https://github.com/vuejs/create-vue)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
