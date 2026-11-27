---
name: 'code-style'
description: 'Kite 项目代码风格规范：ESLint + Prettier + Stylelint 配置与规则。Use when configuring ESLint/Prettier/Stylelint, writing code formatting rules, asking about code style, or setting up linting tools.'
version: '1.0.0'
tags: ['code-style', 'eslint', 'prettier', 'stylelint', 'linting', 'formatting']
---

# Code Style — 代码风格规范

定义 Kite 项目的代码风格与格式化规则，覆盖 JavaScript/TypeScript、Vue SFC、SCSS 三大领域。参考 Airbnb JavaScript Style Guide、Vue 官方 Style Guide、Google TS Style Guide 等业界标准。

## 何时使用

- 初始化或更新 ESLint / Prettier / Stylelint 配置
- 团队成员询问代码风格规则
- 代码审查时遇到风格争议
- 新增文件时确认格式化规则

## 前置条件

- 项目使用 Vue 3 + TypeScript + SCSS
- 已安装 ESLint、Prettier、Stylelint 相关依赖

---

## 1. Prettier 格式化规则

Prettier 是 Kite 项目的唯一格式化工具，ESLint 不再做格式化，只做代码质量检查。

```json
{
  "printWidth": 150,
  "tabWidth": 2,
  "singleQuote": true,
  "semi": true,
  "trailingComma": "es5",
  "bracketSpacing": true,
  "arrowParens": "always"
}
```

### 规则说明

| 规则             | 值     | 说明                              |
| ---------------- | ------ | --------------------------------- |
| `printWidth`     | 150    | 单行最大字符数，超出自动换行      |
| `tabWidth`       | 2      | 缩进 2 个空格                     |
| `singleQuote`    | true   | 使用单引号                        |
| `semi`           | true   | 语句结尾加分号                    |
| `trailingComma`  | es5    | 多行结构尾部加逗号（ES5 兼容）    |
| `bracketSpacing` | true   | 对象花括号内加空格 `{ foo: bar }` |
| `arrowParens`    | always | 箭头函数参数始终加括号            |

## 2. ESLint 规则（建议配置）

### 基础配置

```javascript
// eslint.config.js
import pluginVue from 'eslint-plugin-vue';
import tsParser from '@typescript-eslint/parser';
import tsPlugin from '@typescript-eslint/eslint-plugin';

export default [
  // 忽略目录
  { ignores: ['dist/**', 'node_modules/**', '*.d.ts'] },

  // TypeScript 文件
  {
    files: ['**/*.ts', '**/*.tsx'],
    languageOptions: { parser: tsParser },
    plugins: { '@typescript-eslint': tsPlugin },
    rules: {
      // 禁止 any
      '@typescript-eslint/no-explicit-any': 'warn',
      // 未使用变量
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      // 优先使用 const
      'prefer-const': 'error',
      // 禁止 console（生产环境）
      'no-console': 'warn',
      // 禁止 debugger
      'no-debugger': 'error',
    },
  },

  // Vue 文件
  ...pluginVue.configs['flat/essential'],
  {
    files: ['**/*.vue'],
    languageOptions: {
      parserOptions: { parser: tsParser },
    },
    rules: {
      // Vue 官方 Priority A 规则
      'vue/multi-word-component-names': 'error',
      'vue/require-v-for-key': 'error',
      'vue/no-use-v-if-with-v-for': 'error',
      'vue/component-name-in-template-casing': ['error', 'PascalCase'],
      'vue/component-definition-name-casing': ['error', 'PascalCase'],
      'vue/prop-name-casing': ['error', 'camelCase'],
    },
  },
];
```

### 核心规则清单

| 规则                         | 级别  | 说明                           |
| ---------------------------- | ----- | ------------------------------ |
| `no-explicit-any`            | warn  | 避免使用 `any`，优先 `unknown` |
| `no-unused-vars`             | error | 未使用变量报错（`_` 前缀忽略） |
| `prefer-const`               | error | 不重新赋值的变量用 `const`     |
| `no-console`                 | warn  | 生产代码避免 console           |
| `no-debugger`                | error | 禁止提交 debugger              |
| `multi-word-component-names` | error | 组件名必须多词                 |
| `require-v-for-key`          | error | v-for 必须有 key               |
| `no-use-v-if-with-v-for`     | error | 禁止 v-if 与 v-for 同时使用    |

## 3. Stylelint 规则（建议配置）

```javascript
// stylelint.config.js
export default {
  extends: ['stylelint-config-standard-scss', 'stylelint-config-recommended-vue'],
  rules: {
    // 禁止 !important
    'declaration-no-important': true,
    // 禁止未知单位
    'unit-no-unknown': true,
    // 禁止重复选择器
    'no-duplicate-selectors': true,
    // 颜色函数使用现代语法
    'color-function-notation': 'modern',
    // 最大嵌套深度
    'max-nesting-depth': 4,
    // 选择器最大层级
    'selector-max-compound-selectors': 4,
    // 禁止空块
    'block-no-empty': true,
    // 禁止未知属性
    'property-no-unknown': true,
  },
};
```

## 4. 编辑器配置

`.vscode/settings.json`（建议）：

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  },
  "eslint.validate": ["javascript", "typescript", "vue"],
  "stylelint.validate": ["css", "scss", "vue"]
}
```

## 5. package.json scripts

```json
{
  "scripts": {
    "lint": "eslint . --ext .ts,.vue --fix",
    "lint:style": "stylelint \"src/**/*.{css,scss,vue}\" --fix",
    "format": "prettier --write \"src/**/*.{ts,vue,scss,json}\"",
    "lint:all": "npm run lint && npm run lint:style && npm run format"
  }
}
```

## 边界与限制

- Prettier 负责格式化，ESLint 负责代码质量，互不僭越
- 不使用 `eslint-plugin-prettier`（避免冲突）
- 不使用 TSLint（已废弃）
- 规则调整需团队讨论，不允许个人随意修改

## 参考

- [Airbnb JavaScript Style Guide](https://github.com/airbnb/javascript)
- [Vue 官方 Style Guide](https://vuejs.org/style-guide/)
- [Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html)
- [Kite 开发规范](../spec/开发规范.md)
