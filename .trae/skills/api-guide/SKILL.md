---
name: 'api-guide'
description: 'Kite 项目 API 接口与数据层规范：Axios 封装、拦截器、请求/响应类型、错误处理、Loading 管理。Use when creating API modules, designing request/response types, handling API errors, or managing loading states.'
version: '1.0.0'
tags: ['api', 'axios', 'request', 'interceptor', 'error-handling', 'loading', 'dto', 'vo']
---

# API Guide — API 接口与数据层规范

定义 Kite 项目中 API 层的设计规范，包括 Axios 实例封装、请求/响应拦截器、错误处理策略、Loading 状态管理、DTO/VO 类型定义。参考阿里巴巴、字节跳动等大厂前端 API 层设计模式。

## 何时使用

- 创建新的 API 模块
- 设计请求/响应类型
- 配置 Axios 拦截器
- 处理 API 错误
- 管理 Loading 状态
- 对接后端接口

## 前置条件

- 项目已安装 Axios
- 已配置 `src/core/api/request.ts`（Axios 实例）
- 了解模块化 API 目录结构

---

## 1. API 层架构

```text
src/
├── core/
│   └── api/
│       └── request.ts              # Axios 实例 + 全局拦截器
├── modules/
│   └── blog/
│       └── api/
│           ├── article.ts          # 文章相关接口
│           └── comment.ts          # 评论相关接口
```

**数据流**：

```text
pages + components
    ↓
composables / store
    ↓
modules/<feature>/api/  （按资源拆分）
    ↓
src/core/api/request    （Axios 实例 + 拦截器）
    ↓
后端接口
```

## 2. Axios 实例配置

```typescript
// src/core/api/request.ts
import axios, { type AxiosInstance, type AxiosRequestConfig, type InternalAxiosRequestConfig } from 'axios';
import { ElMessage } from 'element-plus';
import type { ApiResponse } from '@/shared/types/common';

const instance: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  timeout: 15000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// 请求拦截器
instance.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    // 添加 Token
    const token = localStorage.getItem('token');
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// 响应拦截器
instance.interceptors.response.use(
  (response) => {
    const { data } = response;

    // 业务状态码判断
    if (data.code !== 200) {
      ElMessage.error(data.message || '请求失败');
      return Promise.reject(new Error(data.message));
    }

    return data;
  },
  (error) => {
    // HTTP 错误处理
    if (error.response) {
      const { status } = error.response;
      switch (status) {
        case 401:
          // Token 过期，跳转登录
          localStorage.removeItem('token');
          window.location.href = '/login';
          break;
        case 403:
          ElMessage.error('没有权限访问');
          break;
        case 404:
          ElMessage.error('请求的资源不存在');
          break;
        case 500:
          ElMessage.error('服务器内部错误');
          break;
        default:
          ElMessage.error(`请求失败: ${status}`);
      }
    } else if (error.request) {
      ElMessage.error('网络错误，请检查网络连接');
    }
    return Promise.reject(error);
  }
);

export default instance;
```

## 3. 通用类型定义

```typescript
// src/shared/types/common.ts

// 通用 API 响应
interface ApiResponse<T = unknown> {
  code: number;
  data: T;
  message: string;
}

// 分页参数
interface PaginationParams {
  page: number;
  pageSize: number;
}

// 分页响应
interface PaginatedData<T> {
  list: T[];
  total: number;
  page: number;
  pageSize: number;
}

type PaginatedResponse<T> = ApiResponse<PaginatedData<T>>;
```

## 4. API 模块编写规范

### 4.1 按资源拆分

```typescript
// src/modules/blog/api/article.ts
import request from '@/core/api/request';
import type { ApiResponse, PaginatedResponse, PaginationParams } from '@/shared/types/common';
import type { ArticleVO, CreateArticleDTO, UpdateArticleDTO } from '@/modules/blog/types';

// 获取文章列表
export function getArticleList(params: PaginationParams & { keyword?: string }) {
  return request.get<PaginatedResponse<ArticleVO>>('/api/articles', { params });
}

// 获取文章详情
export function getArticleById(id: number) {
  return request.get<ApiResponse<ArticleVO>>(`/api/articles/${id}`);
}

// 创建文章
export function createArticle(data: CreateArticleDTO) {
  return request.post<ApiResponse<ArticleVO>>('/api/articles', data);
}

// 更新文章
export function updateArticle(id: number, data: UpdateArticleDTO) {
  return request.put<ApiResponse<ArticleVO>>(`/api/articles/${id}`, data);
}

// 删除文章
export function deleteArticle(id: number) {
  return request.delete<ApiResponse<null>>(`/api/articles/${id}`);
}
```

### 4.2 命名规范

| 操作     | 命名格式                  | 示例                  |
| -------- | ------------------------- | --------------------- |
| 查询列表 | `get<Resource>List`       | `getArticleList`      |
| 查询详情 | `get<Resource>ById`       | `getArticleById`      |
| 创建     | `create<Resource>`        | `createArticle`       |
| 更新     | `update<Resource>`        | `updateArticle`       |
| 删除     | `delete<Resource>`        | `deleteArticle`       |
| 批量操作 | `batch<Action><Resource>` | `batchDeleteArticles` |

## 5. 错误处理策略

### 5.1 分层处理

```text
┌─────────────────────────────────────────┐
│ 全局拦截器（src/core/api/request.ts）     │
│ - HTTP 状态码错误（401/403/404/500）       │
│ - 网络错误                                │
│ - 业务状态码非 200                        │
│ - 统一 Toast 提示                         │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Composable 层                            │
│ - 特定接口的 loading/error 状态管理        │
│ - 业务特定的错误处理（如表单验证）          │
│ - 重试逻辑                                │
└─────────────────────────────────────────┘
```

### 5.2 Composable 中的错误处理

```typescript
// composables/useArticleList.ts
export function useArticleList() {
  const articles = ref<ArticleVO[]>([]);
  const isLoading = ref(false);
  const error = ref<string | null>(null);

  async function fetchArticles(params: PaginationParams) {
    isLoading.value = true;
    error.value = null;
    try {
      const response = await getArticleList(params);
      articles.value = response.data.list;
    } catch (e) {
      error.value = e instanceof Error ? e.message : '加载文章列表失败';
      // 全局拦截器已处理通用错误，这里只处理业务特定逻辑
    } finally {
      isLoading.value = false;
    }
  }

  return { articles, isLoading, error, fetchArticles };
}
```

## 6. Loading 状态管理

### 6.1 模式一：Composable 内置

```typescript
// 每个 Composable 管理自己的 loading
const { articles, isLoading, error } = useArticleList();
```

### 6.2 模式二：全局 Loading

```typescript
// 全局请求计数
let requestCount = 0;
const isLoading = ref(false);

function showLoading() {
  requestCount++;
  isLoading.value = true;
}

function hideLoading() {
  requestCount--;
  if (requestCount <= 0) {
    isLoading.value = false;
    requestCount = 0;
  }
}
```

### 6.3 推荐：混合策略

- 列表加载：骨架屏（Skeleton）
- 表单提交：按钮 Loading 状态
- 全局操作：全屏 Loading / NProgress

## 7. 请求取消

```typescript
// 页面卸载时取消未完成的请求
import { onBeforeUnmount } from 'vue';

const controller = new AbortController();

onBeforeUnmount(() => {
  controller.abort();
});

// 请求中使用
request.get('/api/articles', {
  signal: controller.signal,
});
```

## 8. 禁止事项

- ❌ 禁止在组件中直接调用 Axios（必须通过 API 模块）
- ❌ 禁止硬编码接口 URL
- ❌ 禁止忽略错误处理（每个请求必须有 try-catch 或 .catch）
- ❌ 禁止使用 mock 数据冒充真实接口返回
- ❌ 禁止在 API 模块中操作 DOM 或 UI 状态

## 边界与限制

- API 模块只能被 Composable 或 Store 调用，不能直接被组件调用
- 全局拦截器处理通用错误，业务特定错误在 Composable 中处理
- 接口 URL 统一使用环境变量管理 Base URL

## 参考

- [Axios 官方文档](https://axios-http.com/)
- [Kite 开发规范 - 数据流](../spec/开发规范.md#5-数据流)
