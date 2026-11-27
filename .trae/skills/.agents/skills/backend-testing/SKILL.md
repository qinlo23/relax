---
name: 'backend-testing'
description: 'Backend testing standards covering unit tests, integration tests, test naming, coverage requirements, and Mock usage. Use when writing tests, setting up test frameworks, or reviewing test coverage.'
version: '1.0.0'
tags: ['backend', 'testing', 'junit', 'mockito', 'java', 'unit-test', 'integration-test']
---

# Backend Testing Standards

后端测试规范，涵盖单元测试、集成测试、测试命名、覆盖率要求和 Mock 使用。参考 Google Testing Blog、阿里巴巴及 Spring Boot 官方测试最佳实践。

## 何时使用

- 编写单元测试或集成测试时
- 配置测试框架（JUnit5 + Mockito）时
- 审查测试覆盖率时
- 询问"这个测试怎么写"或"测试应该覆盖什么"
- 为新功能补充测试时

## 测试分层

| 层级     | 工具                            | 范围                    | 覆盖率要求     |
| -------- | ------------------------------- | ----------------------- | -------------- |
| 单元测试 | JUnit5 + Mockito                | Service/Mapper/Utils 层 | 核心业务 ≥ 60% |
| 集成测试 | SpringBootTest + Testcontainers | 核心接口/Controller     | 核心接口 ≥ 80% |
| 接口测试 | Postman/JMeter/REST Assured     | 全量接口                | 全覆盖         |

### 测试金字塔

```
       /\
      /  \      接口测试（少）
     /----\
    /      \    集成测试（中）
   /--------\
  /          \  单元测试（多）
 /------------\
```

## 测试命名规范

### 测试类命名

- 格式：`被测类名 + Test`
- 示例：`UserServiceTest`、`OrderControllerTest`、`StringUtilsTest`

### 测试方法命名

**推荐格式**：`test + 方法名 + 场景`

```java
@Test
void testCreateUser_WhenNameIsNull_ThrowException() { }

@Test
void testCreateUser_WhenNameExists_ReturnError() { }

@Test
void testCreateUser_Success_ReturnUser() { }
```

**备选格式**（Given-When-Then）：

```java
@Test
void givenValidUser_whenCreate_thenReturnSuccess() { }
```

## 测试结构：AAA 模式

所有测试方法遵循 **Arrange → Act → Assert** 模式：

```java
@Test
void testCreateUser_Success() {
    // Arrange（准备）：准备测试数据和 Mock 行为
    UserDTO dto = new UserDTO("张三", "13800001111");
    when(userMapper.selectByPhone(dto.getPhone())).thenReturn(null);
    when(userMapper.insert(any(User.class))).thenReturn(1);

    // Act（执行）：执行被测方法
    UserVO result = userService.createUser(dto);

    // Assert（断言）：验证结果
    assertNotNull(result);
    assertEquals("张三", result.getName());
    verify(userMapper, times(1)).insert(any(User.class));
}
```

## 单元测试规范

### 测试范围

- **必须测试**：Service 层核心业务逻辑、工具类公开方法
- **可选测试**：简单 getter/setter、纯配置类
- **不测试**：框架代码（如 Spring Boot 启动类）

### Mock 使用

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserMapper userMapper;      // Mock 依赖的 Mapper

    @InjectMocks
    private UserService userService;     // 注入 Mock 到被测对象

    @Test
    void testCreateUser_Success() {
        // Mock 行为
        when(userMapper.selectByPhone("13800001111")).thenReturn(null);
        when(userMapper.insert(any(User.class))).thenReturn(1);

        UserVO result = userService.createUser(new UserDTO("张三", "13800001111"));

        assertNotNull(result);
        verify(userMapper).insert(any(User.class));  // 验证调用
    }
}
```

### 必须覆盖的场景

| 场景     | 说明                                     |
| -------- | ---------------------------------------- |
| 正常流程 | 正常输入，期望正确输出                   |
| 边界条件 | null、空字符串、0、负数、最大值          |
| 异常场景 | 参数校验失败、业务规则冲突、外部依赖异常 |
| 分支覆盖 | if-else、switch 每个分支                 |

## 集成测试规范

### 测试范围

- Controller 层接口（请求→响应全链路）
- 数据库操作（MyBatis Mapper）
- 外部服务调用（Mock 外部，不 Mock 内部）

### 示例

```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void testGetUser_Success() throws Exception {
        mockMvc.perform(get("/api/v1/users/1")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.code").value(200))
            .andExpect(jsonPath("$.data.name").value("张三"));
    }

    @Test
    void testGetUser_NotFound() throws Exception {
        mockMvc.perform(get("/api/v1/users/99999")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.code").value(404));
    }
}
```

### 数据库测试

- 使用 `@Transactional` 自动回滚，保证测试数据不污染数据库
- 或使用 Testcontainers 启动独立测试数据库
- 每个测试方法独立准备数据，不依赖其他测试的执行顺序

## 测试独立性

- **每个测试独立可运行**，不依赖执行顺序
- 不在测试间共享可变状态
- `@BeforeEach` 初始化，`@AfterEach` 清理
- 禁止使用 `@Order` 强制指定执行顺序

## 覆盖率要求

| 指标         | 最低要求 |
| ------------ | -------- |
| 行覆盖率     | ≥ 60%    |
| 分支覆盖率   | ≥ 50%    |
| 核心业务模块 | ≥ 80%    |

使用 JaCoCo 插件统计：

```xml
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.11</version>
    <executions>
        <execution>
            <goals>
                <goal>prepare-agent</goal>
            </goals>
        </execution>
        <execution>
            <id>report</id>
            <phase>test</phase>
            <goals>
                <goal>report</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

## 边界与限制

- 单元测试必须快速（单个测试 < 100ms），不依赖外部环境（数据库、网络）
- 集成测试可以使用真实数据库，但必须自动回滚
- 测试代码与生产代码同等重要，需要 Code Review
- 测试失败时 CI 流水线必须终止

## 验证清单

- [ ] 测试类命名：`被测类名 + Test`
- [ ] 测试方法命名：`test + 方法名 + 场景`
- [ ] 每个测试遵循 AAA 模式
- [ ] 核心业务逻辑有单元测试
- [ ] 覆盖正常流程、边界条件、异常场景
- [ ] Mock 使用正确，不 Mock 被测对象
- [ ] 测试独立运行，不依赖执行顺序
- [ ] JaCoCo 覆盖率报告已配置
- [ ] CI 流水线中配置了测试阶段
