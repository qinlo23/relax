---
name: 'backend-git-workflow'
description: 'Git workflow standards covering branch strategy (Git Flow), commit message conventions (Conventional Commits/Angular), and PR review process. Use when branching, committing, merging, or setting up Git hooks.'
version: '1.0.0'
tags: ['backend', 'git', 'branch', 'commit', 'conventional-commits', 'workflow']
---

# Backend Git Workflow Standards

Git 工作流规范，涵盖分支策略(Git Flow)、Commit Message 规范(Conventional Commits / Angular 规范)和 PR 审查流程。参考 Angular 团队、Conventional Commits 社区标准及大厂实践。

## 何时使用

- 创建新分支时
- 编写 Git Commit Message 时
- 发起 Pull Request / Merge Request 时
- 配置 Git Hooks (commitlint + husky) 时
- 询问"分支怎么命名"或"commit message 怎么写"

## 分支策略（Git Flow）

### 核心分支

| 分支              | 用途       | 说明                             |
| ----------------- | ---------- | -------------------------------- |
| `master` / `main` | 生产环境   | 只接受 merge，不直接 commit      |
| `develop`         | 开发主分支 | 功能分支从这切出，完成后合并回这 |

### 临时分支

| 分支     | 命名格式           | 从哪切出  | 合并到哪             |
| -------- | ------------------ | --------- | -------------------- |
| 功能分支 | `feature/功能描述` | `develop` | `develop`            |
| 修复分支 | `hotfix/问题描述`  | `master`  | `master` + `develop` |
| 发布分支 | `release/v版本号`  | `develop` | `master` + `develop` |

### 命名示例

```
feature/user-login           # 用户登录功能
feature/order-refund         # 订单退款功能
hotfix/npe-order-create      # 修复下单空指针异常
hotfix/fix-sql-injection     # 修复SQL注入漏洞
release/v1.2.0               # 1.2.0 版本发布
```

### 分支合并规则

- 功能分支 → `develop`：确保通过 CI 检查 + Code Review 后合并
- `develop` → `release`：功能冻结，只修 Bug
- `release` → `master`：发布上线，打 Tag
- `hotfix` → `master` + `develop`：紧急修复，双向合并

## Commit Message 规范

采用 **Conventional Commits** 规范（基于 Angular 规范）。

### 格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### type 类型

| type       | 说明      | 示例                                     |
| ---------- | --------- | ---------------------------------------- |
| `feat`     | 新功能    | `feat(order): 添加订单退款功能`          |
| `fix`      | 修复 Bug  | `fix(order): 修复金额计算精度丢失`       |
| `refactor` | 重构      | `refactor(user): 重构用户模块为策略模式` |
| `docs`     | 文档      | `docs(api): 更新接口文档`                |
| `style`    | 代码格式  | `style(order): 统一缩进为4空格`          |
| `test`     | 测试      | `test(order): 补充订单退款单元测试`      |
| `chore`    | 构建/工具 | `chore(deps): 升级Spring Boot至3.2.0`    |
| `perf`     | 性能优化  | `perf(order): 优化订单列表查询性能`      |
| `ci`       | CI/CD     | `ci: 添加自动化测试流水线`               |

### scope 范围

推荐使用模块名作为 scope：`user`, `order`, `product`, `payment`, `auth`, `common`, `security`, `deps`

### 完整示例

```
feat(order): 添加订单退款功能

支持原路退回和余额退回两种退款方式。
- 原路退回：微信/支付宝退款到原支付账户
- 余额退回：退款到用户平台余额

Closes #123
Refs: #456
```

### 自动校验

使用 **commitlint + husky** 在提交时自动校验：

```bash
npm install --save-dev @commitlint/cli @commitlint/config-conventional husky
npx husky add .husky/commit-msg 'npx --no -- commitlint --edit $1'
```

`commitlint.config.js` 配置：

```js
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [2, 'always', ['feat', 'fix', 'refactor', 'docs', 'style', 'test', 'chore', 'perf', 'ci']],
    'subject-max-length': [2, 'always', 72],
  },
};
```

## PR / MR 规范

### 提交前自检

- [ ] 代码已通过本地编译
- [ ] 单元测试已通过
- [ ] 代码风格检查通过（Checkstyle/Spotless）
- [ ] Commit Message 符合规范
- [ ] 无遗留的调试代码（`System.out`、注释掉的代码）

### PR 描述模板

```markdown
## 变更类型

- [ ] 新功能
- [ ] Bug修复
- [ ] 重构
- [ ] 其他

## 变更说明

简要描述本次变更内容

## 关联 Issue

Closes #xxx

## 测试说明

- [ ] 单元测试已通过
- [ ] 自测场景已覆盖
```

### 审查要求

- 至少 1 人 Code Review 通过后才能合并
- 核心模块（支付、安全）至少 2 人 Review
- Review 关注：逻辑正确性、安全漏洞、性能问题、代码规范

## Tag 规范

发布到生产环境时，在 `master` 分支打 Tag：

```
v1.0.0    # 正式版本
v1.0.0-rc1  # 候选版本
v1.0.0-beta1 # 测试版本
```

遵循语义化版本：`主版本号.次版本号.修订号`

## 边界与限制

- 本规范适用于团队协作项目，个人项目可简化
- 禁止在 `master`/`develop` 分支直接 commit
- 禁止 force push 到共享分支（`master`/`develop`/`release`）
- 所有合并必须通过 PR/MR，禁止直接 merge 到 master

## 验证清单

- [ ] 分支命名符合规范
- [ ] Commit Message 包含 type 和 scope
- [ ] commitlint + husky 已配置
- [ ] PR 有描述说明和关联 Issue
- [ ] 发布版本已打 Tag
- [ ] 无直接 commit 到 master 分支
