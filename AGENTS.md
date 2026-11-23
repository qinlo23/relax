# 仓库贡献指南

## 开发阶段与协作原则

- 当前项目处于持续探索和尝试阶段，允许破坏性变更。发现更清晰、更合适的设计时，可以围绕当前任务直接尝试、重构或替换现有方案。
- 默认不要求兼容旧接口、旧数据结构或旧实现，不为保留历史行为额外引入兼容层、双轨逻辑或迁移测试体系；明确提出兼容要求时再按需处理。
- 调整方案时同步更新相关调用方、配置和文档，清理被替代的代码，使当前实现保持一致。
- 验证以当前功能是否正确为目标，按改动影响选择检查方式，避免为简单、可逆的修改堆积测试和流程。

## 项目结构与模块划分

- `backend/`：Java 25、Spring Boot 4.1、Maven 多模块后端。`start/` 组装应用，`common/` 提供公共基础设施，`business/` 包含 `user`、`admin`、`ai`、`price`、`caishen` 等业务模块；废弃代码放在 `.rubbish/`。
- 后端各模块使用 `src/main/java`、`src/main/resources` 和 `src/test/java` 存放源码、资源和测试；补充文档位于 `backend/.docs/`。
- `frontend/`：Vue 3、TypeScript、Vite、pnpm workspace。`apps/web` 和 `apps/admin` 分别提供前台与后台，应用内部按 `core/modules/shared/layouts` 分层；`packages/contracts`、`packages/platform`、`packages/ui` 提供共享类型、认证请求和 UI，`tests/` 存放跨应用浏览器检查。
- `backend/database/` 存放数据库脚本，`docker/` 存放各服务的 Compose 配置。

## 构建、测试与本地开发

在 `backend/` 中执行：

- `mvn -pl start -am test`：编译应用依赖模块并运行测试。
- `mvn clean package -DskipTests`：跳过测试，生成构建产物。
- `java -jar start/target/start-0.0.1.jar`：启动后端；提前配置 MySQL、Redis、Nacos、MinIO 等依赖。

在 `frontend/` 中执行：

- `pnpm install --frozen-lockfile`：按锁文件安装依赖；`pnpm dev` 同时启动前后台，统一入口为 `127.0.0.1:5173`，`/api` 默认代理到 `127.0.0.1:8080`。
- `pnpm type-check`：检查类型；`pnpm build` 检查类型并构建生产资源。
- `pnpm preview`：启动两个应用预览，统一入口为 `127.0.0.1:5179`。
- 首次运行 `pnpm exec playwright install chromium`，再运行 `pnpm test:permissions`，对预览服务执行模拟 API 的权限检查。

## 编码风格与命名

Java 使用四空格缩进，Vue、TypeScript 使用两空格缩进；引号和分号沿用周围代码风格。当前未配置统一格式化或 lint 命令。

类名和 Vue 组件使用 PascalCase，方法及变量使用 camelCase；后端沿用 `DO`、`DTO`、`VO`、`Mapper`、`ServiceImpl` 等命名。公共模块通过接口与业务实现解耦，权限校验必须落实到后端接口。

## 测试约定

后端使用 JUnit Jupiter 和 Mockito，测试类命名为 `*Test`；前端权限检查使用 Playwright。没有强制覆盖率门槛。对权限边界、关键行为变化补充有意义的验证；纯文档或路径调整检查引用即可。

## 数据库约定

遵循 `backend/database/AGENTS.md`：`backend/database/modules/` 是固定基线，后续变更统一新增到 `backend/database/version/YYYYMMDD_NN_description.sql`。探索性开发允许调整方案，但仍保留该目录约定；默认不重建历史数据库快照或迁移回归测试设施。

## 提交与合并请求

近期提交多为简短中文说明，常用 `1.` 前缀，未强制采用 Conventional Commits。每次提交围绕一个明确改动。

合并请求说明最终行为、验证结果、配置或 SQL 变化，并关联相关问题；可见的界面改动附截图。凭据使用环境配置或 Nacos 管理，避免提交到仓库。
