---
name: 'backend-database-design'
description: 'Database design standards covering table/field naming, required fields, index conventions, and SQL writing rules. Use when designing database tables, writing SQL, reviewing DDL, or creating entity classes.'
version: '1.0.0'
tags: ['backend', 'database', 'mysql', 'sql', 'ddl', 'java']
---

# Backend Database Design Standards

数据库设计规范，涵盖表/字段命名、必备字段、索引规范和 SQL 编写规则。参考阿里巴巴数据库设计规范及若依(RuoYi)等开源项目实践。

## 何时使用

- 设计新的数据库表时
- 编写或审查 DDL 语句时
- 创建 Entity 实体类时
- 编写 SQL 查询语句时
- 审查数据库索引时
- 询问"表应该怎么建"或"字段命名有什么规范"

## 命名规范

### 表名

- 格式：`t_` + 模块名 + 实体名，全小写 + 下划线
- 示例：`t_order_main`、`t_order_item`、`t_user_info`
- **禁止使用**数据库关键字作为表名或字段名
- 表名不超过 32 个字符

### 字段名

- 全小写 + 下划线（snake_case）
- 示例：`user_name`、`order_status`、`create_time`、`is_deleted`
- 字段名不超过 32 个字符
- 布尔类型字段用 `is_` 前缀：`is_deleted`、`is_active`

### 索引名

| 索引类型 | 格式                   | 示例                      |
| -------- | ---------------------- | ------------------------- |
| 普通索引 | `idx_表名_字段名`      | `idx_t_order_user_id`     |
| 唯一索引 | `uk_表名_字段名`       | `uk_t_user_phone`         |
| 联合索引 | `idx_表名_字段1_字段2` | `idx_t_order_user_status` |

## 必备字段

每张业务表必须包含以下字段：

```sql
CREATE TABLE t_xxx (
    id          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    create_by   VARCHAR(64)  DEFAULT NULL COMMENT '创建人',
    create_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_by   VARCHAR(64)  DEFAULT NULL COMMENT '更新人',
    update_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    is_deleted  TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除标记(0:未删除 1:已删除)',
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='表注释';
```

## 字段设计规范

### 数据类型选择

| 场景   | 推荐类型        | 说明                              |
| ------ | --------------- | --------------------------------- |
| 主键   | `BIGINT`        | 自增，避免使用 UUID（索引性能差） |
| 金额   | `DECIMAL(18,2)` | 禁止使用 FLOAT/DOUBLE             |
| 状态   | `TINYINT`       | 配合枚举使用                      |
| 时间   | `DATETIME`      | 比 TIMESTAMP 范围大               |
| 文本   | `VARCHAR(N)`    | 按实际需求定长                    |
| 长文本 | `TEXT`          | 独立存储，不参与查询              |
| JSON   | `JSON`          | MySQL 5.7+，谨慎使用              |
| 布尔   | `TINYINT(1)`    | 0/1 表示                          |

### 字段约束

- 所有字段必须有 `COMMENT` 注释
- 非空字段必须 `NOT NULL`，并设置合理默认值
- 字符串字段存储长度按需分配，避免全部 `VARCHAR(255)`
- 禁止使用 `ENUM` 类型，用 `TINYINT` + 代码枚举替代

## 索引规范

### 创建原则

1. **区分度高的字段**优先创建索引
2. 组合索引遵循**最左前缀**原则
3. 单表索引数量**不超过 5 个**
4. 不在更新频繁的字段上建索引
5. 字符字段建**前缀索引**：`INDEX idx_name (name(20))`

### 必须创建索引的场景

- WHERE 条件中频繁使用的字段
- ORDER BY 排序字段
- JOIN 关联字段
- 具有唯一性约束的字段

### 索引反例

```sql
-- 错误：在区分度低的字段上建索引
CREATE INDEX idx_t_user_gender ON t_user(gender);  -- 只有男/女

-- 错误：无视最左前缀
CREATE INDEX idx_t_order_status_time ON t_order(status, create_time);
SELECT * FROM t_order WHERE create_time > '2024-01-01';  -- 不走索引

-- 正确：组合索引把高区分度字段放前面
CREATE INDEX idx_t_order_user_status ON t_order(user_id, status);
```

## SQL 编写规范

### 必须遵守

1. **禁止 `SELECT *`**，必须明确指定字段列表
2. 使用 `IS NULL` / `IS NOT NULL` 判断 NULL，**不能用 `= NULL`**
3. 分页查询必须有 `ORDER BY`
4. 多表 JOIN 字段类型必须一致
5. 避免在 WHERE 子句中对字段使用函数：`WHERE DATE(create_time) = '2024-01-01'` → 应改为范围查询

### MyBatis 特殊规范

```xml
<!-- 正确：使用 #{} 参数化查询，防止 SQL 注入 -->
<select id="getUser" resultType="User">
    SELECT id, user_name FROM t_user WHERE id = #{id}
</select>

<!-- 错误：使用 ${} 拼接，存在 SQL 注入风险 -->
<select id="getUser" resultType="User">
    SELECT id, user_name FROM t_user WHERE id = ${id}
</select>
```

`${}` 仅用于动态表名、动态列名等无法预编译的场景，且必须做白名单校验。

## 实体类映射规范

```java
@Data
@TableName("t_user")
public class User {
    @TableId(type = IdType.AUTO)
    private Long id;

    private String userName;       // 映射 user_name
    private LocalDateTime createTime;  // 映射 create_time
    private Integer isDeleted;          // 映射 is_deleted（逻辑删除）
}
```

- 实体类名与表名对应，去掉 `t_` 前缀
- 字段名使用 lowerCamelCase，映射数据库 snake_case
- 时间字段使用 `LocalDateTime`（Java 8+）

## 边界与限制

- 本规范适用于 MySQL 5.7+ / 关系型数据库
- 不适用于 MongoDB、Redis 等 NoSQL 数据库
- 高并发场景需额外考虑分库分表、读写分离
- 逻辑删除 vs 物理删除：根据业务需求选择，审计类数据推荐逻辑删除

## 验证清单

- [ ] 表名以 `t_` 开头，全小写 + 下划线
- [ ] 所有字段有 `COMMENT` 注释
- [ ] 必备字段完整（id, create_by, create_time, update_by, update_time, is_deleted）
- [ ] 金额字段使用 `DECIMAL` 类型
- [ ] 索引命名符合规范，数量不超过 5 个
- [ ] 无 `SELECT *` 语句
- [ ] MyBatis SQL 使用 `#{}` 而非 `${}`
