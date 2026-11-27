---
name: 'component-guide'
description: 'Kite 项目 Vue 3 组件开发规范：组件设计、Props/Emits/Slots、Composable、生命周期。Use when creating Vue components, designing component API, asking about Vue 3 best practices, or reviewing component code.'
version: '1.0.0'
tags: ['vue', 'component', 'composable', 'props', 'emits', 'slots', 'composition-api']
---

# Component Guide — 组件开发规范

定义 Kite 项目中 Vue 3 组件的开发规范，包括组件设计原则、Props/Emits/Slots 定义、Composable 使用、生命周期管理。参考 Vue 官方 Style Guide（Priority A/B/C 规则）、Ant Design / Element Plus 组件设计模式。

## 何时使用

- 创建新的 Vue 组件
- 设计组件 Props / Emits / Slots API
- 抽取 Composable 逻辑
- 代码审查时检查组件质量
- 重构已有组件

## 前置条件

- 使用 Vue 3 Composition API + `<script setup lang="ts">`
- 组件文件放在 `src/modules/<feature>/components/` 或 `src/shared/components/`
- 页面文件放在 `src/modules/<feature>/pages/`

---

## 1. 组件结构模板

```vue
<script setup lang="ts">
// 1. 类型导入
import type { ArticleVO } from '@/modules/blog';

// 2. Props
interface Props {
  article: ArticleVO;
  showAuthor?: boolean;
  showExcerpt?: boolean;
}
const props = withDefaults(defineProps<Props>(), {
  showAuthor: true,
  showExcerpt: true,
});

// 3. Emits
interface Emits {
  (e: 'click', article: ArticleVO): void;
  (e: 'delete', articleId: number): void;
}
const emit = defineEmits<Emits>();

// 4. Composable / Store
const { isDeleting, handleDelete } = useArticleDelete();

// 5. 响应式数据
const isExpanded = ref(false);

// 6. 计算属性
const displayTitle = computed(() => {
  return props.article.title || '无标题';
});

// 7. 方法
function handleClick() {
  emit('click', props.article);
}
</script>

<template>
  <article class="article-card" @click="handleClick">
    <header class="article-card__header">
      <h3 class="article-card__title">{{ displayTitle }}</h3>
      <span v-if="props.showAuthor" class="article-card__author">
        {{ props.article.author.name }}
      </span>
    </header>
    <p v-if="props.showExcerpt" class="article-card__excerpt">
      {{ props.article.content }}
    </p>
    <footer class="article-card__footer">
      <button class="article-card__delete-btn" :disabled="isDeleting" @click.stop="handleDelete(props.article.id)">
        {{ isDeleting ? '删除中...' : '删除' }}
      </button>
    </footer>
  </article>
</template>

<style lang="scss" scoped>
.article-card {
  // BEM 风格
  &__header {
  }
  &__title {
  }
  &__author {
  }
  &__excerpt {
  }
  &__footer {
  }
  &__delete-btn {
  }
}
</style>
```

## 2. Vue 官方 Priority A 规则（必须遵守）

| 规则                        | 说明                                         |
| --------------------------- | -------------------------------------------- |
| 组件名必须多词              | 避免与 HTML 元素冲突，`BlogCard` 而非 `Card` |
| Props 定义要详细            | 至少指定 type，推荐加上 required/default     |
| v-for 必须设置 key          | 组件上必须使用唯一 key                       |
| 避免 v-if 和 v-for 同时使用 | 先用 computed 过滤                           |
| 组件样式必须 scoped         | 防止样式污染                                 |
| 私有属性名使用 `$_` 前缀    | 避免与 Vue 内部属性冲突                      |

## 3. Props 规范

### 3.1 定义方式

```typescript
// ✅ 推荐：TypeScript 泛型 + withDefaults
interface Props {
  articleId: number; // 必填
  initialData?: ArticleVO; // 可选
  mode?: 'view' | 'edit'; // 可选，有默认值
  disabled?: boolean; // 可选，有默认值
}

const props = withDefaults(defineProps<Props>(), {
  mode: 'view',
  disabled: false,
});

// ❌ 避免：运行时验证（TypeScript 项目不需要）
defineProps({
  articleId: { type: Number, required: true },
});
```

### 3.2 Props 命名

```typescript
// ✅ camelCase（TS 中）
defineProps<{
  blogId: number;
  isEditable: boolean;
  onSubmit: () => void;
}>();

// 模板中自动转换为 kebab-case
// <BlogCard :blog-id="1" :is-editable="true" />
```

### 3.3 Props 设计原则

- 必填 props 越少越好（3~5 个以内）
- 布尔 props 用 `is`/`has`/`can` 前缀
- 避免传递整个大对象，按需拆分为独立 props
- 回调函数用 `on` 前缀命名

## 4. Emits 规范

```typescript
// ✅ 明确定义 Emits 类型
interface Emits {
  (e: 'update:modelValue', value: string): void;
  (e: 'submit-success', data: ArticleVO): void;
  (e: 'close'): void;
  (e: 'delete', articleId: number): void;
}
const emit = defineEmits<Emits>();
```

### Emits 命名

- 事件名用 kebab-case（模板中）
- 成功事件加 `-success` 后缀
- v-model 事件用 `update:modelValue`
- 避免与原生事件重名（`click`、`submit` 等谨慎使用）

## 5. Composable 规范

### 5.1 命名与结构

```typescript
// composables/useBlogDetail.ts
import type { Ref } from 'vue';
import { ref, computed, watch, onMounted } from 'vue';
import { getArticleById } from '@/modules/blog/api/article';
import type { ArticleVO } from '@/modules/blog';

interface UseBlogDetailOptions {
  id: Ref<number> | number;
}

interface UseBlogDetailReturn {
  article: Ref<ArticleVO | null>;
  isLoading: Ref<boolean>;
  error: Ref<string | null>;
  refresh: () => Promise<void>;
}

export function useBlogDetail(options: UseBlogDetailOptions): UseBlogDetailReturn {
  const article = ref<ArticleVO | null>(null);
  const isLoading = ref(false);
  const error = ref<string | null>(null);

  const articleId = computed(() => (typeof options.id === 'number' ? options.id : options.id.value));

  async function fetchArticle() {
    isLoading.value = true;
    error.value = null;
    try {
      const response = await getArticleById(articleId.value);
      article.value = response.data;
    } catch (e) {
      error.value = e instanceof Error ? e.message : '加载失败';
    } finally {
      isLoading.value = false;
    }
  }

  async function refresh() {
    await fetchArticle();
  }

  onMounted(() => {
    fetchArticle();
  });

  watch(articleId, () => {
    fetchArticle();
  });

  return { article, isLoading, error, refresh };
}
```

### 5.2 Composable 设计原则

| 原则     | 说明                              |
| -------- | --------------------------------- |
| 单一职责 | 一个 composable 只做一件事        |
| 显式输入 | 通过 options 参数接收依赖         |
| 显式输出 | 返回明确的类型定义                |
| 可测试   | 不依赖全局状态，方便单元测试      |
| 命名规范 | 以 `use` 开头，文件名与函数名一致 |

## 6. 页面组件规范

页面组件只做展示与协调，业务逻辑全部委托给 composable/store：

```vue
<script setup lang="ts">
import { useBlogList } from '@/modules/blog/composables/useBlogList';
import BlogCard from '@/modules/blog/components/BlogCard.vue';
import Pagination from '@/shared/components/Pagination.vue';

const { articles, isLoading, pagination, handlePageChange, handleDelete } = useBlogList();
</script>

<template>
  <div class="blog-list-page">
    <h1>文章列表</h1>
    <div v-if="isLoading" class="loading">加载中...</div>
    <div v-else class="blog-list-page__grid">
      <BlogCard v-for="article in articles" :key="article.id" :article="article" @delete="handleDelete" />
    </div>
    <Pagination v-bind="pagination" @page-change="handlePageChange" />
  </div>
</template>
```

## 7. 生命周期使用

```typescript
// ✅ 推荐顺序
import { onMounted, onBeforeUnmount, onUpdated, watch } from 'vue';

// 1. onMounted：初始化数据、添加事件监听
onMounted(() => {
  fetchData();
  window.addEventListener('resize', handleResize);
});

// 2. onBeforeUnmount：清理副作用
onBeforeUnmount(() => {
  window.removeEventListener('resize', handleResize);
  clearInterval(timer);
});

// 3. watch：响应式监听
watch(
  () => props.articleId,
  (newId) => {
    fetchArticle(newId);
  }
);

// 4. computed：派生状态
const displayTitle = computed(() => props.article?.title ?? '无标题');
```

## 边界与限制

- 页面组件禁止包含大量业务逻辑（委托给 composable）
- 组件内禁止直接调用 Axios（通过 API 层）
- 禁止在 `watch` 中执行副作用而不清理
- 禁止在 `onMounted` 中执行异步操作而不处理 loading/error 状态
- 共享组件放在 `src/shared/components/`，模块私有组件放在模块内

## 参考

- [Vue 3 官方文档 - 组件基础](https://vuejs.org/guide/essentials/component-basics.html)
- [Vue 官方 Style Guide](https://vuejs.org/style-guide/)
- [Vue 3 Composition API](https://vuejs.org/guide/extras/composition-api-faq.html)
- [Kite 开发规范 - 页面与逻辑分层](../spec/开发规范.md#4-页面与逻辑分层)
