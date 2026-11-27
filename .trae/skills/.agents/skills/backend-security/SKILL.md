---
name: 'backend-security'
description: 'Backend security standards covering authentication, authorization, data protection, input validation, and OWASP Top 10 defense. Use when implementing login/auth, handling sensitive data, or reviewing security vulnerabilities.'
version: '1.0.0'
tags: ['backend', 'security', 'authentication', 'authorization', 'owasp', 'java']
---

# Backend Security Standards

后端安全规范，涵盖认证鉴权、数据保护、输入校验、OWASP Top 10 防护等。参考阿里巴巴、OWASP 及 Spring Security 官方最佳实践。

## 何时使用

- 实现用户登录/注册/鉴权功能时
- 处理敏感数据（密码、手机号、身份证）时
- 设计接口访问权限控制时
- 审查安全漏洞时
- 配置应用安全策略时
- 询问"如何防止 SQL 注入"或"密码怎么加密"

## 认证与鉴权

### 认证方案

- 统一使用 **JWT + Spring Security** 或 **Shiro**
- Token 存储在请求头 `Authorization: Bearer <token>`
- Token 过期时间：Access Token ≤ 2 小时，Refresh Token ≤ 7 天
- 密码使用 **BCrypt** 加密存储，**禁止明文、MD5、SHA1**

```java
// 密码加密
PasswordEncoder encoder = new BCryptPasswordEncoder();
String encodedPassword = encoder.encode(rawPassword);

// 密码校验
boolean matches = encoder.matches(rawPassword, encodedPassword);
```

### 权限控制

- 接口级权限：`@PreAuthorize("hasRole('ADMIN')")`
- 数据级权限：在 Service 层按用户 ID 过滤
- 菜单/按钮级权限：前端控制 + 后端二次校验

### 敏感操作二次验证

以下操作需要二次验证（短信验证码/密码确认）：

- 修改密码
- 修改绑定手机号/邮箱
- 支付/转账
- 注销账号

## 数据安全

### 敏感数据脱敏

| 数据类型 | 脱敏规则       | 示例                     |
| -------- | -------------- | ------------------------ |
| 手机号   | 中间4位替换    | `138****8000`            |
| 邮箱     | 用户名部分替代 | `zh***@company.com`      |
| 身份证   | 中间8位替换    | `3201**********1234`     |
| 银行卡   | 保留后4位      | `**** **** **** 1234`    |
| 密码     | 不返回         | 响应中永远不包含密码字段 |

脱敏在**序列化返回**时进行，使用 Jackson 自定义序列化器或注解。

### 配置安全

- 数据库密码、API Key 等敏感配置使用**环境变量**或**配置中心**
- **禁止**在代码中硬编码任何密钥、密码
- 配置文件区分环境：`application-dev.yml` / `application-prod.yml`
- 敏感配置文件加入 `.gitignore`

```yaml
# 正确：使用环境变量
spring:
  datasource:
    password: ${DB_PASSWORD}

# 错误：硬编码密码
spring:
  datasource:
    password: mypassword123
```

## 输入校验

### 接口层校验

```java
@PostMapping("/users")
public ApiResponse<UserVO> createUser(@Valid @RequestBody UserDTO dto) {
    // @Valid 触发 JSR-303 校验
}

public class UserDTO {
    @NotBlank(message = "用户名不能为空")
    @Size(min = 2, max = 20, message = "用户名长度2-20位")
    private String username;

    @NotBlank(message = "手机号不能为空")
    @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号格式不正确")
    private String phone;
}
```

### 安全校验原则

- **永远不信任前端输入**，后端必须独立校验
- 文件上传：校验类型（白名单）、大小限制、重命名存储
- 富文本输入：XSS 过滤（Jsoup 等）
- 数值范围：上限限制（防止溢出攻击）

## OWASP Top 10 防护

### SQL 注入防护

- 使用参数化查询：MyBatis `#{}`、JPA 参数绑定
- 禁止拼接 SQL 字符串
- 动态排序/表名场景：白名单校验

### XSS 防护

- 输入过滤：去除 `<script>` 等危险标签
- 输出编码：JSON 序列化时转义特殊字符
- 设置 `Content-Type: application/json`（不返回 HTML）

### CSRF 防护

- 前后端分离项目：Token 存储在 Header 而非 Cookie
- 设置 `SameSite=Strict` Cookie 属性
- 关键操作增加验证码/Token 校验

### 接口防刷

- 登录接口：限制错误次数，超出锁定账号/IP
- 短信接口：同一手机号每分钟 1 次，每天 10 次
- 全局限流：使用 Redis + 令牌桶/漏桶算法

```java
@RateLimiter(key = "login", limit = 5, window = 60) // 每分钟最多5次
@PostMapping("/login")
public ApiResponse<LoginVO> login(@Valid @RequestBody LoginDTO dto) { ... }
```

## 边界与限制

- 本规范适用于 Spring Boot 后端项目
- 不涵盖前端安全（CSP、CORS 等前端配置）
- 生产环境建议接入 API 网关（统一鉴权、限流、日志）
- 安全审计：关键操作必须记录审计日志（操作人、时间、内容、IP）

## 验证清单

- [ ] 密码使用 BCrypt 加密存储
- [ ] Token 有合理的过期时间
- [ ] 敏感接口有二次验证
- [ ] 敏感数据在返回时脱敏
- [ ] 配置文件中无硬编码密码/密钥
- [ ] 所有接口请求参数有 `@Valid` 校验
- [ ] SQL 使用 `#{}` 参数化查询
- [ ] 登录/短信接口有防刷机制
- [ ] 文件上传有类型和大小校验
