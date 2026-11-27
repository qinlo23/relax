---
name: 'typescript-guide'
description: 'Kite 项目 TypeScript 类型规范：类型定义、严格模式、接口设计、泛型使用。Use when defining TypeScript types/interfaces, asking about TS best practices, configuring tsconfig, or writing type-safe code.'
version: '1.0.0'
tags: ['typescript', 'types', 'interface', 'generic', 'strict', 'type-safety']
---

# TypeScript Guide — TypeScript 类型规范

定义 Kite 项目中 TypeScript 的使用规范，包括类型定义、接口设计、泛型使用、严格模式配置。参考 Google TypeScript Style Guide、Vue 3 源码类型实践、Deno Style Guide。

## 何时使用

- 定义新的类型/接口
- 配置 `tsconfig.json`
- 选择 `interface` vs `type`
- 编写泛型代码
- 代码审查时检查类型安全性
- 解决 TypeScript 类型错误

## 前置条件

- 项目已启用 TypeScript
- 理解 TypeScript 基础类型系统

---

## 1. tsconfig 严格模式

```json
{
  "compilerOptions": {
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true
  }
}
```

| 选项                         | 说明                           |
| ---------------------------- | ------------------------------ |
| `strict: true`               | 启用所有严格类型检查（核心）   |
| `noUnusedLocals`             | 禁止未使用的局部变量           |
| `noUnusedParameters`         | 禁止未使用的函数参数           |
| `noFallthroughCasesInSwitch` | 禁止 switch 穿透               |
| `noUncheckedIndexedAccess`   | 索引访问必须处理 undefined     |
| `exactOptionalPropertyTypes` | 可选属性不允许显式赋 undefined |

## 2. Interface vs Type

### 选择原则

```typescript
// ✅ 对象类型：优先使用 interface
interface UserInfo {
  id: number;
  name: string;
  email: string;
}

// ✅ 联合类型：使用 type
type BlogStatus = 'draft' | 'published' | 'archived';

// ✅ 工具类型：使用 type
type PartialUser = Partial<UserInfo>;
type ReadonlyBlog = Readonly<Blog>;

// ✅ 函数签名：使用 type
type EventHandler = (event: Event) => void;
```

### 决策矩阵

| 场景         | 使用        | 原因                           |
| ------------ | ----------- | ------------------------------ |
| 对象形状定义 | `interface` | 可扩展、合并声明、IDE 提示更好 |
| 联合类型     | `type`      | interface 不支持               |
| 交叉类型     | `type`      | 语义更清晰                     |
| 函数签名     | `type`      | 更简洁                         |
| 元组         | `type`      | interface 不直观               |
| 需要 extends | `interface` | extends 比 & 更清晰            |

## 3. 禁止 any

```typescript
// ❌ 禁止
const data: any = response.data;
function process(input: any): any {}

// ✅ 使用 unknown
const data: unknown = response.data;
function process(input: unknown): unknown {
  if (typeof input === 'string') {
    return input.toUpperCase();
  }
  throw new Error('Invalid input');
}

// ✅ 使用具体类型
interface ApiResponse<T> {
  code: number;
  data: T;
  message: string;
}
const response: ApiResponse<UserInfo> = await fetchUser();
```

### any 替代方案

| 场景       | 替代方案                  |
| ---------- | ------------------------- |
| 不确定类型 | `unknown`                 |
| 泛型场景   | 泛型 `<T>`                |
| 第三方库   | `@types/` 或手写声明      |
| 快速原型   | 临时允许，标记 TODO       |
| 对象字面量 | `Record<string, unknown>` |

## 4. 类型定义规范

### 4.1 API 响应类型

```typescript
// 通用响应包装
interface ApiResponse<T> {
  code: number;
  data: T;
  message: string;
}

// 分页响应
interface PaginatedResponse<T> {
  list: T[];
  total: number;
  page: number;
  pageSize: number;
}

// 具体接口
interface GetArticleListParams {
  page: number;
  pageSize: number;
  status?: BlogStatus;
  keyword?: string;
}

type GetArticleListResponse = ApiResponse<PaginatedResponse<ArticleVO>>;
```

### 4.2 DTO vs VO

```typescript
// DTO（Data Transfer Object）：发送给后端的数据
// 放在 modules/<feature>/types/dto.ts
interface CreateArticleDTO {
  title: string;
  content: string;
  tags: string[];
  status: BlogStatus;
}

// VO（View Object）：后端返回的展示数据
// 放在 modules/<feature>/types/vo.ts 或 <resource>.ts
interface ArticleVO {
  id: number;
  title: string;
  content: string;
  author: UserInfo;
  tags: string[];
  status: BlogStatus;
  createdAt: string;
  updatedAt: string;
}
```

### 4.3 组件 Props / Emits / Slots

```typescript
// Props
interface BlogCardProps {
  article: ArticleVO;
  showAuthor?: boolean;
  showExcerpt?: boolean;
}

// Emits
interface BlogCardEmits {
  (e: 'click', article: ArticleVO): void;
  (e: 'delete', articleId: number): void;
}

// 在组件中使用
const props = defineProps<BlogCardProps>();
const emit = defineEmits<BlogCardEmits>();
```

## 5. 泛型规范

```typescript
// ✅ 简单泛型用单字母
function identity<T>(value: T): T {
  return value;
}

// ✅ 复杂泛型用描述性名称
function createStore<TState extends Record<string, unknown>, TActions>(state: TState, actions: TActions) {}

// ✅ 泛型约束
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

// ✅ 泛型默认值
interface FetchOptions<T = unknown> {
  params?: Record<string, string>;
  body?: T;
  headers?: Record<string, string>;
}
```

## 6. 类型导入

```typescript
// ✅ 使用 import type 显式标记类型导入
import type { ArticleVO, BlogStatus } from '@/modules/blog';
import type { Ref, ComputedRef } from 'vue';

// ✅ 混合导入
import { useBlogList, type BlogListOptions } from '@/modules/blog';

// ❌ 避免
import { ArticleVO } from '@/modules/blog'; // 类型不应该混入运行时导入
```

## 7. 常见模式

### 7.1 枚举 vs 联合类型

```typescript
// ✅ 字符串字面量联合类型（推荐）
type OrderStatus = 'pending' | 'processing' | 'completed' | 'cancelled';

// ✅ 需要枚举值映射时使用 const enum
const enum HttpStatus {
  OK = 200,
  Created = 201,
  BadRequest = 400,
  Unauthorized = 401,
  NotFound = 404,
}
```

### 7.2 可选链与空值合并

```typescript
// ✅ 可选链
const authorName = article?.author?.name;

// ✅ 空值合并
const displayName = user.nickname ?? user.username ?? '匿名用户';

// ❌ 避免
const authorName = article && article.author && article.author.name;
```

### 7.3 类型守卫

```typescript
// ✅ 自定义类型守卫
function isArticleVO(value: unknown): value is ArticleVO {
  return typeof value === 'object' && value !== null && 'id' in value && 'title' in value;
}

// 使用
if (isArticleVO(data)) {
  console.log(data.title); // 类型安全
}
```

## 边界与限制

- 禁止在代码中使用 `any`（除非有充分理由并加注释说明）
- 禁止使用 `as` 强制类型断言绕过类型检查
- 禁止使用 `@ts-ignore`，优先使用 `@ts-expect-error`
- 类型文件放在模块 `types/` 目录下，不允许散落

## 参考

- [Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html)
- [TypeScript 官方文档](https://www.typescriptlang.org/docs/)
- [Deno Style Guide](https://deno.land/manual/contributing/style_guide)
- [Kite 开发规范 - 类型与常量](../spec/开发规范.md#8-类型与常量)
