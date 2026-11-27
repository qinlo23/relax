---
name: "backend-code-standards"
description: "Backend coding standards covering naming conventions, code formatting, OOP rules, and project structure. Use when writing backend code, creating new classes, reviewing code style, or setting up project conventions."
version: "1.0.0"
tags: ["backend", "java", "coding-standards", "naming", "code-style"]
---

# Backend Code Standards

后端编码规范，涵盖命名风格、代码格式、OOP 规约和项目结构约定。参考阿里巴巴 Java 开发手册、Google Java Style Guide 及若依(RuoYi)等知名开源项目实践。

## 何时使用

- 编写新的 Java 类、方法、变量时
- 审查代码风格和命名规范时
- 初始化新项目模块时
- 询问"应该怎么命名"或"代码格式有什么要求"
- 重构代码以符合团队规范时

## 命名规范

### 类/接口命名

| 类型 | 规范 | 示例 |
|------|------|------|
| 类名 | UpperCamelCase，名词或名词短语 | `UserController`, `OrderService`, `PasswordEncoder` |
| 接口名 | UpperCamelCase，名词或形容词 | `UserRepository`, `Comparable`, `Serializable` |
| 抽象类 | Abstract 或 Base 开头 | `AbstractService`, `BaseController` |
| 异常类 | Exception 结尾 | `BizException`, `AuthException` |
| 测试类 | 被测类名 + Test | `UserServiceTest`, `OrderControllerTest` |
| 枚举类 | 名词，通常单数 | `OrderStatus`, `UserType` |

### 方法命名

| 操作 | 前缀 | 示例 |
|------|------|------|
| 获取单个对象 | `get` | `getUserById(Long id)` |
| 获取多个对象 | `list` | `listOrdersByUserId(Long userId)` |
| 获取统计值 | `count` | `countActiveUsers()` |
| 新增 | `save` 或 `insert` | `saveUser(UserDTO dto)` |
| 删除 | `remove` 或 `delete` | `removeOrder(Long orderId)` |
| 修改 | `update` | `updateUser(UserDTO dto)` |
| 校验 | `check` 或 `validate` | `checkUserExists(Long userId)` |
| 布尔判断 | `is` 或 `has` | `isActive()`, `hasPermission()` |

### 变量/常量/包命名

- **变量**：lowerCamelCase，如 `userName`, `orderList`, `maxRetryCount`
- **常量**：CONSTANT_CASE，如 `MAX_RETRY_COUNT`, `DEFAULT_PAGE_SIZE`
- **包名**：全小写，点分隔，如 `com.company.project.module.controller`
- **数据库字段**：snake_case，如 `create_time`, `is_deleted`
- **URL 路径**：kebab-case，如 `/api/v1/user-orders`

## 代码格式

### 缩进与空格

- 缩进：4 个空格，**禁止使用 Tab 字符**
- 单行字符数：不超过 120 个字符
- 大括号：K&R 风格（左大括号不换行）
- 操作符两侧加空格：`a = b + c`
- 逗号后加空格：`foo(a, b, c)`

### 文件编码与换行

- 所有源文件使用 UTF-8 编码
- 换行符统一使用 LF（`\n`）
- 文件末尾留一个空行
- 行尾不留多余空格

### 自动化工具

项目必须配置以下工具并集成到 CI 流水线：

- `.editorconfig` — 跨编辑器基础格式配置
- `checkstyle.xml` — Java 代码风格检查（推荐 Google 或 Sun 规范）
- 可选：`Spotless` Maven 插件自动格式化

## OOP 规约

### 基本原则

1. 所有覆写方法必须加 `@Override` 注解
2. 禁止使用过时的类和方法，用 `@Deprecated` 标记并说明替代方案
3. 包装类对象的比较使用 `equals()`，而非 `==`
4. POJO 类中布尔变量不要加 `is` 前缀（与框架生成 getter 冲突）
5. 构造方法中禁止加入业务逻辑，有初始化逻辑放到 `init()` 或 `@PostConstruct` 中

### 类设计

- 单一职责：一个类只做一件事
- 开闭原则：对扩展开放，对修改关闭
- 依赖倒置：依赖抽象接口，不依赖具体实现
- 接口隔离：不强迫实现不需要的方法

## 项目结构规范

### Maven 多模块结构

```
project-root/
├── pom.xml                    # 父POM：统一管理依赖版本
├── project-common/            # 公共模块：工具类、常量、异常、枚举
├── project-framework/         # 框架模块：AOP、拦截器、配置、安全
├── project-system/            # 系统模块：基础功能（用户、角色、权限）
├── project-business/          # 业务模块（按领域拆分）
│   ├── project-order/         # 订单领域
│   ├── project-product/       # 商品领域
│   └── project-user/          # 用户领域
├── project-api/               # 对外 Feign/Dubbo 接口定义
└── project-admin/             # 启动模块（入口）
```

### 单模块内部分层

```
src/main/java/com/company/project/
├── controller/        # Web 请求与响应（薄层，不写业务逻辑）
├── service/           # 业务接口
│   └── impl/          # 业务实现
├── mapper/            # 数据访问层
├── model/
│   ├── entity/        # 数据库实体（与表一一对应）
│   ├── dto/           # 数据传输对象
│   ├── vo/            # 视图对象（返回给前端）
│   └── query/         # 查询条件对象
├── config/            # 配置类
├── handler/           # 全局异常处理器
├── interceptor/       # 拦截器
├── aop/               # 切面
├── annotation/        # 自定义注解
├── enums/             # 枚举类
├── constant/          # 常量
└── utils/             # 工具类
```

**分层依赖原则**：Controller → Service → Mapper。上层依赖下层，禁止反向依赖和跨层调用。

## 边界与限制

- 本规范适用于 Java / Spring Boot 后端项目
- 不覆盖前端、移动端、Python/Go 等其他语言项目
- 具体项目可根据团队情况微调，但需在项目文档中明确
- 优先级：项目级约定 > 本规范 > 默认 IDE 设置

## 验证清单

- [ ] 类名、方法名、变量名符合命名规范
- [ ] 无 Tab 缩进，单行不超过 120 字符
- [ ] 所有 `@Override` 方法有注解
- [ ] 项目目录结构符合分层约定
- [ ] `.editorconfig` 和 `checkstyle.xml` 已提交到仓库
- [ ] CI 流水线中已配置代码风格检查