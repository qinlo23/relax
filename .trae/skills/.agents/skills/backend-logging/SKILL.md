---
name: 'backend-logging'
description: 'Backend logging standards covering log framework, log levels, traceId, sensitive data masking, and audit logging. Use when adding log statements, configuring logback/log4j2, or troubleshooting logging issues.'
version: '1.0.0'
tags: ['backend', 'logging', 'logback', 'log4j2', 'java']
---

# Backend Logging Standards

后端日志规范，涵盖日志框架选型、日志级别、traceId 链路追踪、敏感数据脱敏和审计日志。参考阿里巴巴及大厂日志实践。

## 何时使用

- 添加或修改日志输出语句时
- 配置日志框架（Logback/Log4j2）时
- 设计全链路追踪方案时
- 排查日志相关问题（级别不对、格式混乱、信息不全）时
- 询问"这个日志应该用什么级别"或"日志怎么打"

## 日志框架

### 框架选型

- **门面**：SLF4J（统一 API）
- **实现**：Logback（Spring Boot 默认）或 Log4j2（高并发场景推荐）
- **禁止**使用 `System.out.println()` 和 `e.printStackTrace()`

### 依赖引入

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Slf4j  // Lombok 注解，等价于 private static final Logger log = LoggerFactory.getLogger(XXX.class);
public class UserService {
    public void doSomething() {
        log.info("用户操作: userId={}", userId);
    }
}
```

## 日志级别规范

| 级别    | 使用场景                                     | 生产环境 |
| ------- | -------------------------------------------- | -------- |
| `ERROR` | 影响系统正常运行、需要人工介入的异常         | 开启     |
| `WARN`  | 潜在问题、降级处理、可恢复的异常             | 开启     |
| `INFO`  | 关键业务流程节点、接口入参出参、定时任务执行 | 开启     |
| `DEBUG` | 调试信息、详细执行过程                       | **关闭** |
| `TRACE` | 最详细的追踪信息                             | **关闭** |

### 各级别使用示例

```java
// ERROR：需要人工介入
log.error("订单支付失败: orderId={}, amount={}", orderId, amount, exception);

// WARN：降级处理
log.warn("缓存查询失败，降级查询数据库: key={}", cacheKey);

// INFO：关键业务节点
log.info("用户下单成功: userId={}, orderId={}, amount={}", userId, orderId, amount);

// DEBUG：调试信息
log.debug("查询用户信息: userId={}, sql={}", userId, sql);
```

## traceId 全链路追踪

### 必要性

每个请求分配唯一 `traceId`，贯穿 Controller → Service → Mapper → 外部调用，方便日志聚合和问题排查。

### 实现方式

```java
// 拦截器/MDC 设置
String traceId = UUID.randomUUID().toString().replace("-", "");
MDC.put("traceId", traceId);

// 请求结束后清理
MDC.remove("traceId");
```

### Logback 配置

```xml
<appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
    <encoder>
        <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] [%X{traceId}] %-5level %logger{36} - %msg%n</pattern>
    </encoder>
</appender>
```

日志输出示例：

```
2024-01-15 10:30:45.123 [http-nio-8080-exec-1] [a1b2c3d4] INFO  c.c.p.service.UserService - 用户登录成功: userId=1001
```

## 敏感数据脱敏

以下数据在日志中**必须脱敏**：

| 数据类型 | 脱敏方式    | 日志输出             |
| -------- | ----------- | -------------------- |
| 手机号   | 中间4位替换 | `138****8000`        |
| 身份证   | 中间8位替换 | `3201**********1234` |
| 密码     | 完全隐藏    | `******`             |
| Token    | 只记录前8位 | `Bearer eyJhbGci...` |
| 银行卡   | 保留后4位   | `****1234`           |

### 实现方式

```java
// 自定义 toString 或日志工具类
log.info("用户注册: phone={}", MaskUtils.maskPhone(phone));
// 输出: 用户注册: phone=138****8000
```

## 日志书写规范

### 必须包含的信息

- **异常日志**：必须传入异常对象，而非仅 `e.getMessage()`

  ```java
  // 正确
  log.error("订单处理失败: orderId={}", orderId, e);
  // 错误：丢失堆栈
  log.error("订单处理失败: " + e.getMessage());
  ```

- **关键操作**：记录操作人、操作时间、操作内容、IP 地址

  ```java
  log.info("admin操作: userId={}, action={}, target={}, ip={}",
           userId, "DELETE_USER", targetUserId, ipAddress);
  ```

- **外部调用**：记录耗时、请求参数、响应结果
  ```java
  long start = System.currentTimeMillis();
  Result result = thirdPartyApi.call(params);
  long cost = System.currentTimeMillis() - start;
  log.info("第三方调用: api={}, cost={}ms, params={}, result={}", "paymentApi", cost, params, result);
  ```

### 禁止事项

- 禁止在循环中打印 INFO 级别日志
- 禁止使用字符串拼接构造日志信息（用 `{}` 占位符）
- 禁止打印大对象（如整个 List，超过 100 条只打印条数）
- 禁止在日志中打印敏感信息明文

## 审计日志

以下操作必须记录审计日志（独立存储，不可删除）：

- 用户登录/登出
- 权限变更（角色分配/修改）
- 敏感数据操作（查看/修改用户信息）
- 配置变更
- 删除操作

审计日志格式：`操作人 | 操作时间 | 操作类型 | 操作对象 | 操作前数据 | 操作后数据 | IP地址`

## 日志文件配置

```xml
<!-- 滚动策略：按天 + 按大小 -->
<rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
    <fileNamePattern>logs/app-%d{yyyy-MM-dd}.%i.log</fileNamePattern>
    <maxFileSize>100MB</maxFileSize>
    <maxHistory>30</maxHistory>
    <totalSizeCap>10GB</totalSizeCap>
</rollingPolicy>
```

## 边界与限制

- 本规范适用于 Java 后端项目
- 生产环境日志级别必须是 INFO 及以上
- 日志文件目录必须做磁盘空间监控
- 微服务场景建议接入 ELK（Elasticsearch + Logstash + Kibana）统一日志平台

## 验证清单

- [ ] 使用 SLF4J + Logback/Log4j2，无 `System.out.println`
- [ ] 异常日志传入异常对象 `log.error("msg", e)`
- [ ] 日志使用 `{}` 占位符，不使用字符串拼接
- [ ] 敏感数据已脱敏（手机号、身份证、密码等）
- [ ] traceId 已配置并贯穿全链路
- [ ] 关键业务操作有审计日志
- [ ] 生产环境 DEBUG 日志已关闭
- [ ] 日志文件有滚动策略和大小限制
