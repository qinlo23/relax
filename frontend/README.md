# Kite Studio

Vue 3 + TypeScript + Vite 前端，使用 pnpm workspace 管理前台、管理后台和共享包。

## 结构

```text
frontend/
├── apps/web/          # 前台：/，业务模块仍按 modules/core/shared/layouts 分层
├── apps/admin/        # 后台：/admin/，独立路由、登录页与构建
├── packages/contracts/ # 共享接口类型
├── packages/platform/ # HTTP、认证、权限、公共内容读取接口
├── packages/ui/       # 公共样式、主题、资源、登录表单
├── tests/            # 模拟 API 的跨应用权限检查
├── types/            # 共享资源类型声明
└── tsconfig.base.json
```

使用 Node.js 22.12+（推荐 24）、pnpm 11.25.0。首次使用可执行
`npm install --global pnpm@11.25.0` 安装包管理器。以下命令均在本目录执行。

## 开发与构建

```bash
pnpm install --frozen-lockfile
pnpm dev           # 同时启动两个应用
pnpm dev:web       # 仅前台 5173
pnpm dev:admin     # 仅后台 5174
pnpm type-check    # 检查所有应用和共享包
pnpm build         # 生成 dist/web 和 dist/admin
pnpm build:web     # 仅构建前台，保留后台产物
pnpm build:admin   # 仅构建后台，保留前台产物
pnpm preview       # 同时启动两个应用预览
```

日常统一访问 [前台](http://127.0.0.1:5173/) 和 [后台](http://127.0.0.1:5173/admin/)。
前台开发服务器将 /admin/（含 HMR WebSocket）代理到 5174；/api 代理到 127.0.0.1:8080。
统一入口仅方便本地开发。前后台使用独立登录存储，即使同域名部署也不共享登录态。
单独运行后台时直接访问 5174/admin/，不依赖前台运行。
预览统一入口为 127.0.0.1:5179，后台预览内部端口为 5180。

后台未登录跳转 /admin/login，认证后恢复有权限的目标页，或进入第一个有权限的页面。
前后台可共用 Java 后端账号和 /api，但分别登录并获得不同 token。
web 使用 kite_front_* 存储，admin 使用 kite_admin_* 存储；退出和 401 仅影响当前应用。
同一应用的多个标签页仍同步退出，不同应用互不影响。
没有后台权限显示无权限页。登录后保留在当前应用，不提供固定的前后台互跳入口。

## 依赖与边界

只维护根目录的 pnpm-lock.yaml；内部依赖使用 workspace:*。
给指定应用添加依赖，例如 `pnpm --filter @kite/web add <包名>`。
源码直接使用的依赖必须在所属包声明；Vue、Element Plus 由应用提供给共享包。
共享包只通过 package.json exports 暴露入口，不单独发布或预编译。
@/ 只指向当前应用；应用之间不相互引用，共享包不得反向引用 apps。
前台公共内容读取接口放 platform，后台管理增删改接口留在 admin。

## 验证

```bash
pnpm exec playwright install chromium
pnpm build
pnpm preview              # 保持运行
# 另一个终端：
pnpm test:permissions
```

检查使用模拟 API，无需运行后端，也不会修改真实账号。

## Nginx 部署

将 dist/web 和 dist/admin 分别放到 docker/nginx/dist/web、docker/nginx/dist/admin，
现有 Compose 将整个 dist 挂载到 /usr/share/nginx/html。
Nginx 配置将 / 指向 web、/admin/ 指向 admin，各自回退自己的 index.html；缺失构建资源返回 404。
只更新一个应用时仅替换对应子目录。修改配置后先执行 `nginx -t`，通过后再重载。
