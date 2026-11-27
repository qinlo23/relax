---
name: 'naming-convention'
description: 'Kite 项目命名规范：文件、目录、变量、组件、CSS 类名等命名规则。Use when naming files/folders/variables/components, asking about naming rules, or creating new modules/pages/components.'
version: '1.0.0'
tags: ['naming', 'convention', 'camelCase', 'PascalCase', 'kebab-case', 'BEM']
---

# Naming Convention — 命名规范

统一 Kite 项目中所有命名方式，确保代码可读性、一致性和可维护性。参考阿里巴巴 Java 开发手册命名风格、Airbnb 命名规范、Vue 官方风格指南。

## 何时使用

- 创建新文件、目录、组件、变量时
- 代码审查时检查命名是否符合规范
- 团队成员询问命名规则
- 重构旧代码中的命名问题

## 前置条件

- 理解 camelCase、PascalCase、kebab-case、UPPER_SNAKE_CASE 四种命名风格
- 目录命名参考已存在的 `src/modules/` 结构

---

## 1. 命名风格速查

| 风格                 | 格式                       | 适用场景                          |
| -------------------- | -------------------------- | --------------------------------- |
| **camelCase**        | 首字母小写，单词首字母大写 | 变量、函数、方法、Composable 实例 |
| **PascalCase**       | 每个单词首字母大写         | 类、接口、类型别名、Vue 组件      |
| **kebab-case**       | 全小写 + 短横线连接        | 目录、普通 TS/JS 文件、CSS 类名   |
| **UPPER_SNAKE_CASE** | 全大写 + 下划线连接        | 常量、枚举值                      |
| **dot.case**         | 全小写 + 点连接            | Store 文件名                      |

## 2. 文件命名

### 2.1 目录命名

```
✅ 正确
src/modules/blog/           # 全小写
src/modules/user-profile/   # 多词用短横线
src/shared/components/       # 复数
src/core/api/                # 单数

❌ 错误
src/modules/Blog/            # 不要大写
src/modules/user_profile/    # 不要下划线
src/modules/userProfile/     # 不要驼峰
```

### 2.2 文件命名

| 文件类型   | 命名风格               | 示例                                                             |
| ---------- | ---------------------- | ---------------------------------------------------------------- |
| Vue 页面   | PascalCase             | `HomePage.vue`、`BlogListPage.vue`、`UserProfilePage.vue`        |
| Vue 组件   | PascalCase             | `BlogCard.vue`、`PriceTrend.vue`、`SearchBar.vue`                |
| Composable | camelCase `use` 前缀   | `useBlogDetail.ts`、`useUserProfile.ts`、`useTablePagination.ts` |
| Store      | dot.case `.store` 后缀 | `article.store.ts`、`priceItem.store.ts`、`auth.store.ts`        |
| API 模块   | kebab-case 按资源      | `article.ts`、`comment.ts`、`user.ts`                            |
| 类型定义   | kebab-case 按资源      | `article.ts`、`dto.ts`、`vo.ts`、`common.ts`                     |
| 常量       | kebab-case             | `status.ts`、`enums.ts`、`config.ts`                             |
| 工具函数   | kebab-case             | `format-date.ts`、`validate-form.ts`                             |
| 样式文件   | kebab-case             | `blog-card.scss`、`_tokens.scss`                                 |

### 2.3 页面命名规则

页面文件必须以 `Page` 结尾：

```
✅ 正确
BlogListPage.vue        # 文章列表页
BlogDetailPage.vue      # 文章详情页
UserProfilePage.vue     # 用户资料页
DashboardPage.vue       # 仪表盘

❌ 错误
BlogList.vue            # 缺少 Page 后缀
blog-list.vue           # 用于页面不能用 kebab-case
Blog.vue                # 太简短，不明确
```

## 3. 代码命名

### 3.1 变量与函数

```typescript
// ✅ 变量：camelCase，布尔值用 is/has/can 前缀
const userName = 'Alice';
const isLoading = ref(false);
const hasPermission = computed(() => true);
const canEdit = ref(true);

// ✅ 函数：camelCase，动词开头
function getUserInfo() {}
function fetchArticleList() {}
function handleSubmit() {}
function validateForm() {}

// ❌ 错误
const user_name = 'Alice'; // 不用下划线
const UserName = 'Alice'; // 不用 PascalCase
const loading = ref(false); // 布尔值缺少前缀
function getData() {} // 太模糊
```

### 3.2 常量

```typescript
// ✅ 常量：UPPER_SNAKE_CASE
const MAX_PAGE_SIZE = 100;
const API_BASE_URL = '/api/v1';
const DEFAULT_USER_AVATAR = '/assets/avatar.png';

// 枚举
enum OrderStatus {
  PENDING = 'pending',
  PROCESSING = 'processing',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
}
```

### 3.3 类型与接口

```typescript
// ✅ 接口/类型：PascalCase
interface UserInfo {
  id: number;
  name: string;
  email: string;
}

type BlogStatus = 'draft' | 'published' | 'archived';

// DTO/VO 命名
interface CreateArticleDTO {
  title: string;
  content: string;
}

interface ArticleVO {
  id: number;
  title: string;
  createdAt: string;
}
```

### 3.4 组件 Props 与 Emits

```typescript
// ✅ Props：camelCase
const props = defineProps<{
  blogId: number;
  isEditable: boolean;
  initialData?: ArticleVO;
}>();

// ✅ Emits：kebab-case（模板中），camelCase（TS 中）
const emit = defineEmits<{
  (e: 'update:modelValue', value: string): void;
  (e: 'submit-success', data: ArticleVO): void;
  (e: 'close'): void;
}>();
```

## 4. CSS 类命名（BEM）

```scss
// ✅ BEM 风格：block__element--modifier
.blog-card {
  &__title {
    &--featured {
    }
  }
  &__meta {
    &--compact {
    }
  }
  &__image {
    &--loading {
    }
  }
}

// 编译后
.blog-card {
}
.blog-card__title {
}
.blog-card__title--featured {
}
.blog-card__meta {
}
.blog-card__meta--compact {
}

// ❌ 错误
.blogCard {
} // 不用驼峰
.blog_card {
} // 不用下划线
.blog-card .title {
} // 不嵌套（用 BEM）
```

## 5. 禁止事项

- ❌ 禁止使用拼音命名（全拼、缩写都不行）
- ❌ 禁止中英文混合命名
- ❌ 禁止使用无意义缩写（`btn` → `button`，`msg` → `message`）
- ❌ 禁止使用数字编号（`div1`、`div2`）
- ❌ 禁止单字母变量（循环变量 `i`、`j` 除外）
- ❌ 禁止保留字作变量名（`class`、`default`、`delete` 等）

## 6. 常见缩写对照

| 缩写    | 全称                              | 使用场景     |
| ------- | --------------------------------- | ------------ |
| `id`    | identifier                        | 标识符       |
| `url`   | Uniform Resource Locator          | URL 地址     |
| `api`   | Application Programming Interface | API 相关     |
| `dto`   | Data Transfer Object              | 数据传输对象 |
| `vo`    | View Object                       | 视图对象     |
| `props` | properties                        | 组件属性     |
| `ref`   | reference                         | 引用         |
| `src`   | source                            | 源文件目录   |
| `dist`  | distribution                      | 构建输出目录 |
| `env`   | environment                       | 环境配置     |

## 边界与限制

- 此规范适用于 Kite 项目所有新增代码
- 历史代码中的命名问题在重构时逐步修正
- 第三方库的命名风格不受此规范约束
- 如有命名争议，以本规范为准

## 参考

- [Vue 官方 Style Guide - Naming](https://vuejs.org/style-guide/)
- [阿里巴巴 Java 开发手册 - 命名风格](https://github.com/alibaba/p3c)
- [Kite 开发规范 - 命名规范](../spec/开发规范.md#6-命名规范)
