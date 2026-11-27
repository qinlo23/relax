---
name: 'backend-api-design'
description: 'RESTful API design standards covering URL naming, HTTP methods, unified response format, exception handling, versioning, and pagination. Use when designing new APIs, reviewing API contracts, or creating controllers.'
version: '1.0.0'
tags: ['backend', 'api', 'restful', 'controller', 'exception-handling', 'java']
---

# Backend API Design Standards

后端接口设计规范，涵盖 RESTful URL 设计、统一响应体、异常处理、版本控制和分页等。参考阿里巴巴、Google API 设计指南及若依(RuoYi)等开源项目实践。

## 何时使用

- 设计新的 REST API 接口时
- 编写 Controller 层代码时
- 定义统一响应体时
- 设计全局异常处理机制时
- 审查 API 接口规范时
- 询问"接口应该怎么设计"或"返回值格式是什么"

## URL 设计规范

### 基本规则

- 使用名词**复数**表示资源：`/users`、`/orders`、`/products`
- 使用 HTTP 方法表达操作：GET(查)、POST(增)、PUT(改)、DELETE(删)
- 层级关系用路径嵌套：`/api/v1/users/{userId}/orders`
- 路径全小写，单词间用连字符：`/user-orders`（禁止下划线）

### 版本控制

```
/api/v1/users          # 版本1
/api/v2/users          # 版本2（不兼容变更时）
```

版本号放在 URL 路径中，`v` + 数字。当入参/出参发生改名、删除等不兼容变更时升级版本。

### 过滤、排序、分页

```
GET /api/v1/users?page=1&size=20&sort=createTime,desc&status=active
```

| 参数   | 说明              | 默认值 |
| ------ | ----------------- | ------ |
| `page` | 页码（从 1 开始） | 1      |
| `size` | 每页条数          | 20     |
| `sort` | 排序字段,方向     | —      |
| 其他   | 业务过滤条件      | —      |

## 统一响应体

### 标准格式

```json
{
  "code": 200,
  "message": "success",
  "data": {},
  "timestamp": 1693300000000,
  "traceId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}
```

### 响应类设计

```java
public class ApiResponse<T> {
    private Integer code;       // 业务状态码
    private String message;     // 提示信息
    private T data;             // 响应数据
    private Long timestamp;     // 时间戳
    private String traceId;     // 链路追踪ID

    public static <T> ApiResponse<T> success(T data) { ... }
    public static <T> ApiResponse<T> error(Integer code, String message) { ... }
}
```

### 分页响应

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "records": [...],
    "total": 100,
    "page": 1,
    "size": 20,
    "pages": 5
  }
}
```

## HTTP 状态码

| 状态码 | 场景       | 说明                   |
| ------ | ---------- | ---------------------- |
| 200    | 成功       | GET/PUT 成功           |
| 201    | 创建成功   | POST 成功              |
| 204    | 无内容     | DELETE 成功            |
| 400    | 参数错误   | 请求参数校验失败       |
| 401    | 未认证     | 未登录或 Token 过期    |
| 403    | 无权限     | 已登录但无操作权限     |
| 404    | 不存在     | 资源不存在             |
| 409    | 冲突       | 数据冲突（如重复创建） |
| 500    | 服务器错误 | 系统内部异常           |

## 异常处理规范

### 全局异常拦截

使用 `@RestControllerAdvice` + `@ExceptionHandler` 统一处理所有异常，**禁止**在 Controller 中 try-catch。

### 异常分类体系

```
BizException (RuntimeException)        # 业务异常（用户可感知）
├── ParamException                     # 参数校验异常
├── AuthException                      # 认证异常
├── PermissionException                # 权限异常
├── DataNotFoundException              # 数据不存在
└── BusinessException                  # 其他业务异常

SystemException (RuntimeException)     # 系统异常（不可感知，需告警）
```

### 异常处理示例

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BizException.class)
    public ApiResponse<Void> handleBizException(BizException e) {
        return ApiResponse.error(e.getCode(), e.getMessage());
    }

    @ExceptionHandler(Exception.class)
    public ApiResponse<Void> handleException(Exception e) {
        log.error("系统异常", e);
        return ApiResponse.error(500, "系统繁忙，请稍后重试");
    }
}
```

**关键原则**：对外绝不暴露 SQL 异常、堆栈信息。`traceId` 用于内部排查。

## 幂等性设计

写操作接口（POST/PUT/DELETE）必须支持幂等：

- **方案一**：唯一业务键 + 数据库唯一索引
- **方案二**：Token 机制（先获取 Token，提交时携带 Token）
- **方案三**：分布式锁（基于 Redis）

## 边界与限制

- 本规范适用于 RESTful API 设计，不适用于 GraphQL、gRPC
- 统一响应体格式一旦确定，全项目必须一致，不得自定义返回结构
- 异常处理器的 `Exception` 兜底处理必须放在最后

## 验证清单

- [ ] URL 使用名词复数，路径层级合理
- [ ] 接口有版本号前缀
- [ ] 分页参数统一使用 `page`/`size`
- [ ] 所有接口返回统一 `ApiResponse` 格式
- [ ] 全局异常处理器已配置
- [ ] 自定义异常类继承 `BizException` 或 `SystemException`
- [ ] 对外不暴露 SQL 异常和堆栈信息
- [ ] 写操作接口已实现幂等机制
