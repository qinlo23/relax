---
name: 'git-workflow'
description: 'Kite 项目 Git 工作流与提交规范：Husky + lint-staged + commitlint + Conventional Commits。Use when setting up Git hooks, asking about commit message format, configuring pre-commit checks, or setting up branch strategy.'
version: '1.0.0'
tags: ['git', 'commit', 'husky', 'lint-staged', 'commitlint', 'conventional-commits', 'workflow']
---

# Git Workflow — Git 工作流与提交规范

定义 Kite 项目的 Git 分支策略、Commit Message 规范、提交前自动检查流程。参考 Angular Convention、Conventional Commits 规范、Vue.js/Ant Design 等知名项目的 Git 工作流。

## 何时使用

- 初始化 Git Hooks 配置
- 提交代码时确认 commit message 格式
- 配置 pre-commit 自动检查
- 制定分支策略
- 新成员了解 Git 工作流

## 前置条件

- Git 已安装并初始化
- Node.js 项目环境中安装相关依赖

---

## 1. 分支策略

采用 **GitHub Flow**（简化版），适合中小团队：

```text
main                  # 生产分支，始终保持可发布状态
├── feature/xxx       # 功能分支，从 main 拉出
├── fix/xxx           # 修复分支
├── hotfix/xxx        # 紧急修复分支，从 main 拉出
└── release/x.x.x     # 发布分支（可选）
```

### 分支命名

| 分支类型 | 格式               | 示例                                         |
| -------- | ------------------ | -------------------------------------------- |
| 功能     | `feature/<描述>`   | `feature/blog-editor`、`feature/user-auth`   |
| 修复     | `fix/<描述>`       | `fix/login-redirect`、`fix/table-pagination` |
| 紧急修复 | `hotfix/<描述>`    | `hotfix/security-patch`                      |
| 发布     | `release/<版本号>` | `release/1.2.0`                              |

### 分支操作流程

```bash
# 1. 从 main 拉取最新代码
git checkout main
git pull origin main

# 2. 创建功能分支
git checkout -b feature/my-feature

# 3. 开发 + 提交
git add .
git commit -m "feat(module): description"

# 4. 推送并创建 PR
git push origin feature/my-feature

# 5. 代码审查通过后合并到 main
```

## 2. Commit Message 规范

遵循 **Conventional Commits** 规范：

```
<type>(<scope>): <subject>

[body]

[footer]
```

### 2.1 Type（类型）

| Type       | 说明                   | 示例                                         |
| ---------- | ---------------------- | -------------------------------------------- |
| `feat`     | 新功能                 | `feat(blog): 新增文章列表页`                 |
| `fix`      | 修复 Bug               | `fix(auth): 修复登录 token 过期后无限重定向` |
| `refactor` | 重构（不改变功能）     | `refactor(api): 重构请求拦截器`              |
| `style`    | 样式调整（不影响逻辑） | `style(button): 调整按钮间距和圆角`          |
| `docs`     | 文档更新               | `docs(readme): 更新部署文档`                 |
| `test`     | 测试相关               | `test(blog): 新增文章列表单元测试`           |
| `chore`    | 构建/工具/依赖         | `chore(deps): 升级 vite 到 5.x`              |
| `perf`     | 性能优化               | `perf(table): 优化表格大数据量渲染`          |
| `ci`       | CI/CD 配置             | `ci: 新增 GitHub Actions 自动部署`           |
| `build`    | 构建系统变更           | `build: 修改 vite 构建配置`                  |

### 2.2 Scope（范围）

使用模块名或功能名：

```text
blog, auth, dashboard, api, router, store, core, shared, layout, deps, config
```

### 2.3 Subject（标题）

- 使用中文描述（Kite 项目约定）
- 不超过 50 个字符
- 不以句号结尾
- 使用祈使句（"新增"而非"新增了"）

### 2.4 完整示例

```text
# 简单提交
feat(blog): 新增文章列表页面

# 带详细说明
fix(auth): 修复登录 token 过期后无限重定向

当 token 过期时，axios 拦截器会触发 refreshToken，
但 refreshToken 也过期时会陷入死循环。现在增加重试
次数限制，超过 3 次后跳转登录页。

Closes #123

# 破坏性变更
feat(api)!: 重构 API 请求层，不兼容旧版本

BREAKING CHANGE: 请求方法从 `get/post/put/delete` 改为
`request.get/post/put/delete`，需要全局替换。
```

## 3. 工具链配置

### 3.1 安装依赖

```bash
npm install -D husky lint-staged @commitlint/cli @commitlint/config-conventional
```

### 3.2 Husky 初始化

```bash
npx husky init
```

### 3.3 commitlint 配置

```javascript
// commitlint.config.js
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [2, 'always', ['feat', 'fix', 'refactor', 'style', 'docs', 'test', 'chore', 'perf', 'ci', 'build', 'revert']],
    'subject-max-length': [2, 'always', 50],
    'scope-empty': [1, 'never'],
  },
};
```

### 3.4 lint-staged 配置

```json
// package.json
{
  "lint-staged": {
    "*.{ts,vue}": ["eslint --fix", "prettier --write"],
    "*.{css,scss,vue}": ["stylelint --fix"],
    "*.{json,md}": ["prettier --write"]
  }
}
```

### 3.5 pre-commit Hook

```bash
# .husky/pre-commit
npx lint-staged
```

### 3.6 commit-msg Hook

```bash
# .husky/commit-msg
npx --no -- commitlint --edit "$1"
```

## 4. 提交前检查流程

```text
git commit
    ↓
Husky pre-commit hook
    ↓
lint-staged（只检查 staged 文件）
    ├── ESLint（TS/Vue 代码质量）
    ├── Prettier（格式化）
    └── Stylelint（样式检查）
    ↓
Husky commit-msg hook
    ↓
commitlint（校验 commit message 格式）
    ↓
提交成功 / 拦截并提示错误
```

## 5. 常见场景

### 5.1 跳过 Hook（紧急情况）

```bash
git commit --no-verify -m "hotfix: 紧急修复生产问题"
```

> ⚠️ 仅在紧急情况下使用，事后必须补上 lint 修复。

### 5.2 修改最近一次提交

```bash
git commit --amend
```

### 5.3 合并多个提交

```bash
git rebase -i HEAD~3
```

## 边界与限制

- commit message 必须通过 commitlint 校验
- 不允许直接推送到 main 分支
- 所有合并必须通过 Pull Request + Code Review
- CI 流水线失败时不允许合并

## 参考

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Angular Commit Message Guidelines](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit)
- [Vue.js Contributing Guide](https://github.com/vuejs/core/blob/main/.github/contributing.md)
