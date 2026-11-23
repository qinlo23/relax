-- ======================================================
-- owl 数据库完整初始化脚本（MySQL 8.4）
-- 仅用于空库；包含建库、各模块建表和初始化数据，不用于已有数据库升级。
-- 执行：mysql -h 127.0.0.1 -u root -p < backend/.database/owl.sql
-- 初始账号（邮箱登录）：
--   admin@admin.com       密码：123456qin  角色：超级管理员（SUPER_ADMIN）
--   user@user.com         密码：123456qin  角色：普通用户（USER）
--   1693676136@qq.com     密码：123456qin  角色：普通用户（USER）
-- 数据库密码字段存储 BCrypt 哈希；仅初始化上述三个账号和两种角色。
-- ======================================================

-- ======================================================
-- 模块：数据库 owl
-- ======================================================

-- owl 数据库初始化；MySQL 8.4。
-- 新建数据库时首先执行本文件，再按 README 中的依赖顺序执行其他模块脚本。
CREATE DATABASE IF NOT EXISTS owl
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE owl;

-- ======================================================
-- 模块：user：用户、角色与权限
-- ======================================================

USE owl;

-- ======================================================
-- owl 数据库：user 模块 canonical DDL
-- 模块：user
-- MySQL 版本：8.4
-- 说明：user_role / user_account / user_address 由 user 模块维护，
--       admin 复用 user_role 表。
-- RBAC 已直接纳入基线：角色编码、内置角色、授权版本、权限目录及多对多关系。
-- 初始账号及角色见本文件顶部说明与末尾初始化数据。
-- ======================================================

-- ------------------------------------------------------
-- 1. 角色表
-- ------------------------------------------------------
CREATE TABLE user_role
(
    id          BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    role_code   VARCHAR(64) NOT NULL COMMENT '稳定角色编码',
    built_in    TINYINT(1) NOT NULL DEFAULT 0 COMMENT '内置角色',
    role_name   VARCHAR(100) NOT NULL COMMENT '角色展示名称',
    description VARCHAR(255) COMMENT '角色描述',
    enabled     TINYINT(1)   NOT NULL DEFAULT 1 COMMENT '是否启用：1=启用，0=禁用',
    create_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    PRIMARY KEY (id),
    UNIQUE KEY uk_user_role_role_code (role_code),
    UNIQUE KEY uk_user_role_role_name (role_name)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '角色表';

-- ------------------------------------------------------
-- 2. 用户表
-- ------------------------------------------------------
CREATE TABLE user_account
(
    id          BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    user_code   VARCHAR(64)      NOT NULL COMMENT '账号编号',
    username    VARCHAR(50)      NOT NULL COMMENT '用户名',
    password    VARCHAR(100) COMMENT '密码（加密存储）',
    phone       VARCHAR(20) COMMENT '手机号',
    email       VARCHAR(50)      NOT NULL COMMENT '邮箱',
    avatar_url  VARCHAR(2048) COMMENT '头像URL',
    nickname    VARCHAR(50) COMMENT '昵称',
    remark      VARCHAR(255) COMMENT '备注',
    auth_version BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '授权版本，变更后旧会话失效',
    status      TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '状态：0=正常，1=封禁',
    create_time DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    PRIMARY KEY (id),
    UNIQUE KEY uk_user_account_user_code (user_code),
    UNIQUE KEY uk_user_account_username (username),
    UNIQUE KEY uk_user_account_phone (phone),
    UNIQUE KEY uk_user_account_email (email)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '用户表';

-- ------------------------------------------------------
-- 3. 用户收货地址表
-- ------------------------------------------------------
CREATE TABLE user_address
(
    id             BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    user_id        BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    receiver_name  VARCHAR(50) COMMENT '收件人姓名',
    receiver_phone VARCHAR(20) COMMENT '收件人电话',
    province       VARCHAR(50) COMMENT '省',
    city           VARCHAR(50) COMMENT '市',
    district       VARCHAR(50) COMMENT '区县',
    detail         VARCHAR(255) COMMENT '详细地址',
    is_default     TINYINT(1)     NOT NULL DEFAULT 0 COMMENT '是否默认地址：1=是，0=否',
    create_time    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    PRIMARY KEY (id),
    KEY idx_user_address_user_id (user_id),
    CONSTRAINT fk_user_address_user_id FOREIGN KEY (user_id) REFERENCES user_account (id) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '用户收货地址表';

-- RBAC: role and permission relations belong to user.
CREATE TABLE user_permission
(
    id BIGINT UNSIGNED AUTO_INCREMENT,
    code VARCHAR(100) NOT NULL,
    name VARCHAR(100) NOT NULL,
    module VARCHAR(100) NOT NULL,
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_user_permission_code (code)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

CREATE TABLE user_account_role
(
    id BIGINT UNSIGNED AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL,
    role_id BIGINT UNSIGNED NOT NULL,
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_user_account_role_user_role (user_id, role_id),
    KEY idx_user_account_role_role_id (role_id),
    CONSTRAINT fk_user_account_role_user FOREIGN KEY (user_id) REFERENCES user_account(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_account_role_role FOREIGN KEY (role_id) REFERENCES user_role(id) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

CREATE TABLE user_role_permission
(
    id BIGINT UNSIGNED AUTO_INCREMENT,
    role_id BIGINT UNSIGNED NOT NULL,
    permission_id BIGINT UNSIGNED NOT NULL,
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_user_role_permission_role_permission (role_id, permission_id),
    KEY idx_user_role_permission_permission_id (permission_id),
    CONSTRAINT fk_user_role_permission_role FOREIGN KEY (role_id) REFERENCES user_role(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_role_permission_permission FOREIGN KEY (permission_id) REFERENCES user_permission(id) ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ======================================================
-- 模块：user / blog：个人博客
-- ======================================================

USE owl;

-- ======================================================
-- owl 数据库：user 模块 - 博客表
-- 模块：user
-- MySQL 版本：8.4
-- 说明：博客文章、设置、教育经历、技能分类/条目由 user 模块维护。
--       表名沿用 blog_ 前缀，与前端 src/modules/blog 语义对齐。
--       依赖 user 模块的 user_account 表（blog_post.user_id）。
-- ======================================================

-- ------------------------------------------------------
-- 1. 博客文章表
-- ------------------------------------------------------
CREATE TABLE blog_post
(
    id          BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    user_id     BIGINT UNSIGNED NOT NULL COMMENT '所属用户ID',
    title       VARCHAR(255)    NOT NULL COMMENT '文章标题',
    excerpt     VARCHAR(500) COMMENT '文章摘要',
    content     LONGTEXT COMMENT '文章正文（Markdown）',
    cover_url   VARCHAR(500) COMMENT '封面图片URL',
    tags        JSON COMMENT '标签数组',
    status      TINYINT         NOT NULL DEFAULT 0 COMMENT '状态：0=草稿，1=已发布',
    sort_order  INT             NOT NULL DEFAULT 0 COMMENT '排序权重，越大越靠前',
    create_time DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted     TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0=未删除，1=已删除',

    PRIMARY KEY (id),
    KEY idx_blog_post_user_id (user_id),
    KEY idx_blog_post_status (status),
    KEY idx_blog_post_sort_order (sort_order),
    KEY idx_blog_post_create_time (create_time),
    CONSTRAINT fk_blog_post_user_id FOREIGN KEY (user_id) REFERENCES user_account (id) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '博客文章表';

-- ------------------------------------------------------
-- 2. 博客设置表
-- ------------------------------------------------------
CREATE TABLE blog_settings
(
    id           BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    user_id      BIGINT UNSIGNED NOT NULL COMMENT '所属用户ID（一对一）',
    tag_line     VARCHAR(255) COMMENT '标签行（支持HTML）',
    bio          JSON COMMENT '简介段落数组',
    location     VARCHAR(100) COMMENT '位置信息',
    github_url   VARCHAR(255) COMMENT 'GitHub 链接',
    codetime_url VARCHAR(500) COMMENT 'CodeTime 统计 Badge URL',
    poem         VARCHAR(255) COMMENT '诗句/座右铭',
    update_time  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    PRIMARY KEY (id),
    UNIQUE KEY uk_blog_settings_user_id (user_id),
    CONSTRAINT fk_blog_settings_user_id FOREIGN KEY (user_id) REFERENCES user_account (id) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '博客设置表';

-- ------------------------------------------------------
-- 3. 教育经历表
-- ------------------------------------------------------
CREATE TABLE blog_education
(
    id          BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    user_id     BIGINT UNSIGNED NOT NULL COMMENT '所属用户ID',
    school      VARCHAR(255)    NOT NULL COMMENT '学校名称',
    degree      VARCHAR(255) COMMENT '学位/专业',
    `period`      VARCHAR(100) COMMENT '时间段',
    sort_order  INT             NOT NULL DEFAULT 0 COMMENT '排序权重',
    create_time DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',

    PRIMARY KEY (id),
    KEY idx_blog_education_user_id (user_id),
    KEY idx_blog_education_sort_order (sort_order),
    CONSTRAINT fk_blog_education_user_id FOREIGN KEY (user_id) REFERENCES user_account (id) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '博客教育经历表';

-- ------------------------------------------------------
-- 4. 技能分类表
-- ------------------------------------------------------
CREATE TABLE blog_skill_category
(
    id          BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    user_id     BIGINT UNSIGNED NOT NULL COMMENT '所属用户ID',
    category    VARCHAR(50)     NOT NULL COMMENT '分类名称',
    sort_order  INT             NOT NULL DEFAULT 0 COMMENT '排序权重',
    create_time DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',

    PRIMARY KEY (id),
    KEY idx_blog_skill_category_user_id (user_id),
    UNIQUE KEY uk_blog_skill_category_user_category (user_id, category),
    CONSTRAINT fk_blog_skill_category_user_id FOREIGN KEY (user_id) REFERENCES user_account (id) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '博客技能分类表';

-- ------------------------------------------------------
-- 5. 技能项表
-- ------------------------------------------------------
CREATE TABLE blog_skill_item
(
    id          BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    category_id BIGINT UNSIGNED NOT NULL COMMENT '所属分类ID',
    item_name   VARCHAR(50)     NOT NULL COMMENT '技能名称',
    sort_order  INT             NOT NULL DEFAULT 0 COMMENT '排序权重',
    create_time DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',

    PRIMARY KEY (id),
    KEY idx_blog_skill_item_category_id (category_id),
    UNIQUE KEY uk_blog_skill_item_category_item (category_id, item_name),
    CONSTRAINT fk_blog_skill_item_category_id FOREIGN KEY (category_id) REFERENCES blog_skill_category (id) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '博客技能项表';

-- ======================================================
-- 模块：user / gallery：个人画廊
-- ======================================================

USE owl;

-- ======================================================
-- owl 数据库：user 模块 - 画廊表
-- 模块：user
-- MySQL 版本：8.4
-- 说明：user_gallery 由 user 模块维护，每个用户拥有自己的画廊项。
-- ======================================================

-- ------------------------------------------------------
-- 画廊表
-- ------------------------------------------------------
CREATE TABLE user_gallery
(
    id            BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    user_id       BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    title         VARCHAR(100)   NOT NULL COMMENT '标题',
    description   VARCHAR(500) COMMENT '描述',
    image_url     VARCHAR(2048)  NOT NULL COMMENT '大图URL',
    thumbnail_url VARCHAR(2048) COMMENT '缩略图URL',
    sort_order    INT            NOT NULL DEFAULT 0 COMMENT '排序序号，数值越小越靠前',
    create_time   DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time   DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    PRIMARY KEY (id),
    KEY idx_user_gallery_user_id (user_id),
    KEY idx_user_gallery_sort_order (sort_order),
    CONSTRAINT fk_user_gallery_user_id FOREIGN KEY (user_id) REFERENCES user_account (id) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '画廊表';

-- ======================================================
-- 模块：admin / front：首页内容
-- ======================================================

USE owl;

-- ======================================================
-- owl 数据库：admin 模块 canonical DDL
-- 模块：admin
-- MySQL 版本：8.4
-- 说明：首页展示配置由 admin 模块维护。
-- ======================================================

-- ------------------------------------------------------
-- 1. 首页焦点展示项目表
-- ------------------------------------------------------
CREATE TABLE admin_spotlight
(
    id          BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    eyebrow     VARCHAR(100) NOT NULL COMMENT '眉题/前置标题',
    title       VARCHAR(200) NOT NULL COMMENT '主标题',
    description TEXT COMMENT '详细描述',
    image_url   VARCHAR(500) NOT NULL COMMENT '配图URL',
    sort_order  INT          NOT NULL DEFAULT 0 COMMENT '排序序号，数值越小越靠前',
    link        VARCHAR(500) COMMENT '点击跳转链接',
    target      VARCHAR(20)  NOT NULL DEFAULT '_self' COMMENT '链接打开方式',
    create_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    PRIMARY KEY (id),
    KEY idx_admin_spotlight_sort_order (sort_order)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '首页焦点展示项目表';

-- ------------------------------------------------------
-- 2. 产品特性展示表
-- ------------------------------------------------------
CREATE TABLE admin_feature
(
    id          BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    icon        VARCHAR(500) NOT NULL COMMENT '图标标识',
    title       VARCHAR(200) NOT NULL COMMENT '特性标题',
    description TEXT COMMENT '特性详细说明',
    sort_order  INT          NOT NULL DEFAULT 0 COMMENT '排序序号，数值越小越靠前',
    create_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    PRIMARY KEY (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '产品特性展示表';

-- ------------------------------------------------------
-- 3. 首页 Hero 视频表
-- ------------------------------------------------------
CREATE TABLE admin_hero_video
(
    id          BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    title       VARCHAR(200) NOT NULL COMMENT '视频标题/标识',
    video_url   VARCHAR(500) NOT NULL COMMENT '视频对象存储路径',
    poster_url  VARCHAR(500) COMMENT '封面图对象存储路径',
    sort_order  INT          NOT NULL DEFAULT 0 COMMENT '排序序号，数值越小越靠前',
    status      TINYINT(1)   NOT NULL DEFAULT 1 COMMENT '状态：1=启用，0=禁用',
    remark      VARCHAR(500) COMMENT '备注',
    create_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    PRIMARY KEY (id),
    KEY idx_admin_hero_video_sort_order (sort_order)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '首页 Hero 视频表';

-- ------------------------------------------------------
-- 4. 前台菜单项表
-- ------------------------------------------------------
CREATE TABLE admin_menu_item
(
    id          BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    title       VARCHAR(100) NOT NULL COMMENT '菜单标题',
    subtitle    VARCHAR(200) COMMENT '菜单副标题',
    path        VARCHAR(200) NOT NULL COMMENT '跳转的前端路由',
    image_url   VARCHAR(500) NOT NULL COMMENT '菜单配图对象存储路径',
    card_size   VARCHAR(20)  NOT NULL DEFAULT 'normal' COMMENT '卡片尺寸：large/normal/small',
    sort_order  INT          NOT NULL DEFAULT 0 COMMENT '排序序号，数值越小越靠前',
    status      TINYINT(1)   NOT NULL DEFAULT 1 COMMENT '状态：1=启用，0=禁用',
    remark      VARCHAR(500) COMMENT '备注',
    create_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    PRIMARY KEY (id),
    KEY idx_admin_menu_item_sort_order (sort_order)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '前台菜单项表';

-- ======================================================
-- 模块：ai：会话与消息
-- ======================================================

USE owl;

-- ======================================================
-- owl 数据库：ai 模块 canonical DDL
-- 模块：ai
-- MySQL 版本：8.4
-- ======================================================

-- ------------------------------------------------------
-- 1. 对话会话表
-- ------------------------------------------------------
CREATE TABLE agent_conversation
(
    id           CHAR(36)     NOT NULL COMMENT '会话ID（UUID，主键）',
    user_code    VARCHAR(64)  NOT NULL COMMENT '用户账号编号',
    title        VARCHAR(255) COMMENT '对话标题',
    total_tokens INT          NOT NULL DEFAULT 0 COMMENT '累计token消耗',
    deleted      TINYINT(1)   NOT NULL DEFAULT 0 COMMENT '是否删除：0=正常，1=已删除',
    create_time  DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    update_time  DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',

    PRIMARY KEY (id),
    KEY idx_agent_conversation_user_code (user_code),
    KEY idx_agent_conversation_create_time (create_time),
    KEY idx_agent_conversation_deleted (deleted)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = 'AI对话会话表';

-- ------------------------------------------------------
-- 2. 对话消息表
-- ------------------------------------------------------
CREATE TABLE agent_message
(
    id                BIGINT UNSIGNED AUTO_INCREMENT COMMENT '消息主键',
    conversation_id   CHAR(36)     NOT NULL COMMENT '所属会话ID',
    role              VARCHAR(20)  NOT NULL COMMENT '消息角色：user / assistant / system',
    content           TEXT         NOT NULL COMMENT '消息内容',
    prompt_tokens     INT COMMENT '输入token',
    completion_tokens INT COMMENT '输出token',
    total_token_count INT COMMENT '该消息总token数',
    model             VARCHAR(50) COMMENT '使用的模型名称',
    finish_reason     VARCHAR(30) COMMENT '生成终止原因',
    create_time       DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',

    PRIMARY KEY (id),
    KEY idx_agent_message_conversation_id (conversation_id),
    KEY idx_agent_message_create_time (create_time),
    KEY idx_agent_message_model (model),
    KEY idx_agent_message_finish_reason (finish_reason),
    CONSTRAINT fk_agent_message_conversation_id FOREIGN KEY (conversation_id)
        REFERENCES agent_conversation (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = 'AI对话消息表';

-- ======================================================
-- 模块：price：价格记录
-- ======================================================

USE owl;

-- ======================================================
-- owl 数据库：price 模块 canonical DDL
-- 模块：price
-- MySQL 版本：8.4
-- ======================================================

-- ------------------------------------------------------
-- 1. 价格系统分类表
-- ------------------------------------------------------
CREATE TABLE price_category
(
    id            BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    parent_id     BIGINT UNSIGNED COMMENT '父分类ID（顶级为NULL）',
    category_name VARCHAR(64)     NOT NULL COMMENT '分类名称',
    category_code VARCHAR(64)     NOT NULL COMMENT '分类唯一编码',
    level         INT             NOT NULL COMMENT '层级（1=一级分类，2=二级分类）',
    sort_order    INT             NOT NULL DEFAULT 0 COMMENT '排序值（越小越靠前）',
    status        TINYINT(1)      NOT NULL DEFAULT 1 COMMENT '状态：1=启用，0=禁用',
    create_time   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    PRIMARY KEY (id),
    UNIQUE KEY uk_price_category_code (category_code),
    KEY idx_price_category_parent (parent_id),
    KEY idx_price_category_status (status)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '价格系统分类表';

-- ------------------------------------------------------
-- 2. 被定价物品表
-- ------------------------------------------------------
CREATE TABLE price_item
(
    id             BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    item_code      VARCHAR(64)     NOT NULL COMMENT '物品唯一编码',
    item_name      VARCHAR(128)    NOT NULL COMMENT '物品名称',
    category_id    BIGINT UNSIGNED NOT NULL COMMENT '分类ID',
    unit           VARCHAR(32)     NOT NULL COMMENT '计价单位',
    specification  VARCHAR(128) COMMENT '规格描述',
    description    TEXT COMMENT '备注说明',
    ref_product_id BIGINT UNSIGNED COMMENT '关联商城商品ID',
    status         TINYINT(1)      NOT NULL DEFAULT 1 COMMENT '状态：1=启用，0=停用',
    create_time    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    PRIMARY KEY (id),
    UNIQUE KEY uk_price_item_code (item_code),
    KEY idx_price_item_category (category_id),
    KEY idx_price_item_status (status),
    CONSTRAINT fk_price_item_category FOREIGN KEY (category_id)
        REFERENCES price_category (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '被定价物品表';

-- ------------------------------------------------------
-- 3. 价格来源表
-- ------------------------------------------------------
CREATE TABLE price_source
(
    id                BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    source_name       VARCHAR(64)  NOT NULL COMMENT '来源名称',
    source_type       VARCHAR(32)  NOT NULL COMMENT '来源类型：API-接口，CRAWLER-爬虫，MANUAL-人工录入',
    source_url        VARCHAR(255) COMMENT '来源地址',
    reliability_level INT          NOT NULL DEFAULT 3 COMMENT '可靠等级1-5（5为最高）',
    remark            VARCHAR(255) COMMENT '备注',
    status            TINYINT(1)   NOT NULL DEFAULT 1 COMMENT '状态：1=启用，0=禁用',
    create_time       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',

    PRIMARY KEY (id),
    KEY idx_price_source_status (status),
    KEY idx_price_source_type (source_type)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '价格来源表';

-- ------------------------------------------------------
-- 4. 地理位置表
-- ------------------------------------------------------
CREATE TABLE geo_location
(
    id            BIGINT UNSIGNED  AUTO_INCREMENT COMMENT '主键ID',
    location_name VARCHAR(128)     NOT NULL COMMENT '地点名称',
    location_type VARCHAR(32)      NOT NULL COMMENT '类型：COUNTRY-国家，CITY-城市，DISTRICT-区县，STORE-门店',
    parent_id     BIGINT UNSIGNED COMMENT '父级区域ID',
    longitude     DECIMAL(10, 7)   NOT NULL COMMENT '经度（GCJ-02坐标系）',
    latitude      DECIMAL(10, 7)   NOT NULL COMMENT '纬度（GCJ-02坐标系）',
    geo_hash      VARCHAR(12) COMMENT 'GeoHash编码',
    status        TINYINT(1)       NOT NULL DEFAULT 1 COMMENT '状态：1=启用，0=禁用',
    create_time   DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',

    PRIMARY KEY (id),
    KEY idx_geo_location_parent (parent_id),
    KEY idx_geo_location_geo (longitude, latitude)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '地理位置表';

-- ------------------------------------------------------
-- 5. 价格记录表（时间序列数据）
-- ------------------------------------------------------
CREATE TABLE price_record
(
    id             BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    item_id        BIGINT UNSIGNED NOT NULL COMMENT '物品ID',
    location_id    BIGINT UNSIGNED NOT NULL COMMENT '位置ID',
    price          DECIMAL(18, 6)  NOT NULL COMMENT '价格数值',
    currency       ENUM ('CNY', 'USD', 'EUR', 'JPY', 'GBP', 'HKD') NOT NULL DEFAULT 'CNY' COMMENT '币种',
    price_unit     VARCHAR(32)     NOT NULL COMMENT '价格单位',
    source_id      BIGINT UNSIGNED NOT NULL COMMENT '来源ID',
    effective_time DATETIME        NOT NULL COMMENT '生效时间',
    expire_time    DATETIME COMMENT '失效时间（NULL表示长期有效）',
    record_time    DATETIME        NOT NULL COMMENT '记录时间',
    confidence     DECIMAL(5, 2)   NOT NULL DEFAULT 100.00 COMMENT '可信度（0-100）',
    create_time    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',

    PRIMARY KEY (id),
    KEY idx_price_record_item (item_id),
    KEY idx_price_record_location (location_id),
    KEY idx_price_record_time (effective_time),
    KEY idx_price_record_source (source_id),
    CONSTRAINT fk_price_record_item FOREIGN KEY (item_id)
        REFERENCES price_item (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_price_record_location FOREIGN KEY (location_id)
        REFERENCES geo_location (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_price_record_source FOREIGN KEY (source_id)
        REFERENCES price_source (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '价格记录表（时间序列数据）';

-- ------------------------------------------------------
-- 6. 价格文件扩展表
-- ------------------------------------------------------
CREATE TABLE price_item_media
(
    id         BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    item_id    BIGINT UNSIGNED NOT NULL COMMENT '物品ID',
    media_type ENUM ('IMAGE', 'VIDEO', 'DOC') NOT NULL COMMENT '媒体类型',
    url        VARCHAR(255)    NOT NULL COMMENT 'URL',
    sort_order INT             NOT NULL DEFAULT 0 COMMENT '排序',
    create_time DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',

    PRIMARY KEY (id),
    KEY idx_price_item_media_item (item_id),
    CONSTRAINT fk_price_item_media_item FOREIGN KEY (item_id)
        REFERENCES price_item (id) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '价格文件扩展表';

-- ======================================================
-- 模块：caishen：基金
-- ======================================================

USE owl;

-- ======================================================
-- owl 数据库：caishen 模块 canonical DDL
-- 模块：caishen（理财中心，代号 caishen）
-- MySQL 版本：8.4
-- 说明：V1 基金监控与提醒。基金档案 / 净值历史 / 用户关注 /
--       提醒规则 / 区间总结。caishen_fund_alert.watch_id 级联删除。
--       caishen_fund_nav 为追加型历史表，无 update_time。
-- ======================================================

-- ------------------------------------------------------
-- 1. 基金档案表
-- ------------------------------------------------------
CREATE TABLE caishen_fund
(
    id          BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    fund_code   VARCHAR(20)  NOT NULL COMMENT '基金代码，如 000001',
    fund_name   VARCHAR(100) NOT NULL COMMENT '基金名称',
    fund_type   VARCHAR(20) COMMENT '基金类型：股票型/混合型/债券型/货币型/指数型',
    status      TINYINT(1)   NOT NULL DEFAULT 1 COMMENT '状态：1=正常，0=停用',
    create_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    PRIMARY KEY (id),
    UNIQUE KEY uk_caishen_fund_fund_code (fund_code)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '基金档案表';

-- ------------------------------------------------------
-- 2. 基金净值历史表（追加型，无 update_time）
-- ------------------------------------------------------
CREATE TABLE caishen_fund_nav
(
    id                BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    fund_code         VARCHAR(20)   NOT NULL COMMENT '基金代码',
    nav_date          DATE          NOT NULL COMMENT '净值日期',
    unit_nav          DECIMAL(10,4) NOT NULL COMMENT '单位净值',
    accumulated_nav   DECIMAL(10,4) COMMENT '累计净值',
    daily_return_rate DECIMAL(8,4) COMMENT '日收益率（%），如 1.2345 表示 1.2345%',
    source            VARCHAR(20) COMMENT '数据来源：mock/python/manual',
    create_time       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',

    PRIMARY KEY (id),
    UNIQUE KEY uk_caishen_fund_nav_fund_nav_date (fund_code, nav_date),
    KEY idx_caishen_fund_nav_nav_date (nav_date)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '基金净值历史表';

-- ------------------------------------------------------
-- 3. 用户关注基金表
-- ------------------------------------------------------
CREATE TABLE caishen_fund_watch
(
    id          BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    user_id     BIGINT      NOT NULL COMMENT '用户ID，关联 user_account.id',
    fund_code   VARCHAR(20) NOT NULL COMMENT '基金代码',
    remark      VARCHAR(200) COMMENT '用户备注，如"定投基金"',
    create_time DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    PRIMARY KEY (id),
    UNIQUE KEY uk_caishen_fund_watch_user_fund (user_id, fund_code),
    KEY idx_caishen_fund_watch_user_id (user_id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '用户关注基金表';

-- ------------------------------------------------------
-- 4. 基金提醒规则表
-- ------------------------------------------------------
CREATE TABLE caishen_fund_alert
(
    id                 BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    watch_id           BIGINT UNSIGNED       NOT NULL COMMENT '关联 caishen_fund_watch.id，级联删除',
    alert_type         VARCHAR(20)  NOT NULL COMMENT '提醒类型：RISE_ABOVE（涨到）/ FALL_BELOW（跌到）',
    threshold_value    DECIMAL(10,4) COMMENT '绝对净值阈值',
    threshold_percent  DECIMAL(8,4) COMMENT '涨跌幅阈值（%），如 2.0000 表示 2%',
    status             VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE' COMMENT '状态：ACTIVE=生效中, TRIGGERED=已触发, PAUSED=暂停',
    last_triggered_at  DATETIME COMMENT '最近一次触发时间',
    create_time        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    PRIMARY KEY (id),
    KEY idx_caishen_fund_alert_watch_id (watch_id),
    KEY idx_caishen_fund_alert_status (status),
    CONSTRAINT fk_caishen_fund_alert_watch FOREIGN KEY (watch_id)
        REFERENCES caishen_fund_watch (id) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '基金提醒规则表';

-- ------------------------------------------------------
-- 5. 用户总结记录表
-- ------------------------------------------------------
CREATE TABLE caishen_summary
(
    id              BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    user_id         BIGINT      NOT NULL COMMENT '用户ID，关联 user_account.id',
    period_type     VARCHAR(10) NOT NULL COMMENT '周期类型：DAILY/WEEKLY/MONTHLY',
    start_date      DATE        NOT NULL COMMENT '统计开始日期',
    end_date        DATE        NOT NULL COMMENT '统计结束日期',
    metric_snapshot TEXT COMMENT '指标快照 JSON，如各基金涨跌幅',
    summary_text    TEXT COMMENT 'AI 生成的总结文本',
    status          VARCHAR(20) NOT NULL COMMENT '状态：PENDING/PROCESSING/SUCCESS/FAILED',
    error_message   VARCHAR(500) COMMENT '失败时的错误信息',
    create_time     DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time     DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    PRIMARY KEY (id),
    KEY idx_caishen_summary_user_id (user_id),
    KEY idx_caishen_summary_status (status)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '用户总结记录表';

-- ======================================================
-- user：账号、角色关系与权限初始化
-- ======================================================

-- 初始化角色：仅保留超级管理员和普通用户。
INSERT INTO user_role (role_code, role_name, built_in, description, enabled)
VALUES ('SUPER_ADMIN', '超级管理员', 1, '超级管理员', 1),
       ('USER', '普通用户', 1, '普通用户', 1);

-- 初始化用户：邮箱同时作为用户名，密码使用 BCrypt 哈希。
INSERT INTO user_account
(user_code, username, password, phone, email, avatar_url, nickname, remark, status, create_time, update_time)
VALUES
('U10001', 'admin@admin.com', '$2a$10$80wh2j/NmPVuRHTMepC0Wuv4IijUzttj7QqjZkJV5PC.rtXePqwve',
 NULL, 'admin@admin.com', '/DEFAULT_AVATAR.png', '系统管理员', '初始化账号', 0, NOW(), NOW()),
('U10002', 'user@user.com', '$2a$10$W87I.D83GpLny9WNtFDnA.Ui4rCfJjrNmnt7kEAd.pcyjZ3wneIM6',
 NULL, 'user@user.com', '/DEFAULT_AVATAR.png', '普通用户', '初始化账号', 0, NOW(), NOW()),
('U10003', '1693676136@qq.com', '$2a$10$5L5EoXBujMJ.WeKmbRpLJ.Qf2vQvKVWEfMKRcLE6gCZIiA.iZRPFu',
 NULL, '1693676136@qq.com', '/DEFAULT_AVATAR.png', '普通用户2', '初始化账号', 0, NOW(), NOW());

INSERT INTO user_account_role (user_id, role_id)
SELECT u.id, r.id
FROM user_account u
JOIN user_role r ON r.role_code = CASE
    WHEN u.email = 'admin@admin.com' THEN 'SUPER_ADMIN'
    ELSE 'USER'
END
WHERE u.email IN ('admin@admin.com', 'user@user.com', '1693676136@qq.com');

-- 权限目录：超级管理员由后端自动获得全部权限。
INSERT IGNORE INTO user_permission(code, name, module) VALUES
('admin:access', '进入后台', '后台'),
('dashboard:read', '查看控制台', '后台'),
('content:read', '查看内容管理入口', '后台'),
('settings:read', '查看界面设置', '后台'),
('user:read', '查看', '用户管理'),
('user:create', '新增', '用户管理'),
('user:update', '编辑', '用户管理'),
('user:delete', '删除', '用户管理'),
('user:status', '启用/禁用', '用户管理'),
('user:reset-password', '重置密码', '用户管理'),
('spotlight:read', '查看', '焦点项目'),
('spotlight:create', '新增', '焦点项目'),
('spotlight:update', '编辑', '焦点项目'),
('spotlight:delete', '删除', '焦点项目'),
('feature:read', '查看', '特性管理'),
('feature:create', '新增', '特性管理'),
('feature:update', '编辑', '特性管理'),
('feature:delete', '删除', '特性管理'),
('hero-video:read', '查看', 'Hero 视频'),
('hero-video:create', '新增', 'Hero 视频'),
('hero-video:update', '编辑', 'Hero 视频'),
('hero-video:delete', '删除', 'Hero 视频'),
('hero-video:status', '启用/禁用', 'Hero 视频'),
('menu-item:read', '查看', '首页菜单'),
('menu-item:create', '新增', '首页菜单'),
('menu-item:update', '编辑', '首页菜单'),
('menu-item:delete', '删除', '首页菜单'),
('menu-item:status', '启用/禁用', '首页菜单');
