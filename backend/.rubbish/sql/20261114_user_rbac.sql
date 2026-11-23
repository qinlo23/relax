-- Run ONCE during maintenance, after backup, using mysql WITHOUT --force.
-- MySQL DDL auto-commits: restore the backup on failure; do not rerun a partial migration.
-- Preflight prints unmapped accounts; SIGNAL prevents all subsequent DDL on invalid input.
DROP PROCEDURE IF EXISTS preflight_user_rbac;
DELIMITER $$
CREATE PROCEDURE preflight_user_rbac()
BEGIN
    IF EXISTS(SELECT 1 FROM user_account u LEFT JOIN user_role r ON r.role_name=u.role_name WHERE r.id IS NULL) THEN
        SELECT u.id,u.role_name FROM user_account u LEFT JOIN user_role r ON r.role_name=u.role_name WHERE r.id IS NULL;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Unmapped account roles; migration stopped';
    END IF;
    IF NOT EXISTS(SELECT 1 FROM user_account u JOIN user_role r ON r.role_name=u.role_name WHERE r.role_name='ADMIN' AND r.enabled=1 AND u.status=0) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='No active ADMIN account; migration stopped';
    END IF;
    IF NOT EXISTS(SELECT 1 FROM user_role WHERE role_name='USER' AND enabled=1) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Enabled USER role missing; migration stopped';
    END IF;
END$$
DELIMITER ;
CALL preflight_user_rbac();
DROP PROCEDURE preflight_user_rbac;

ALTER TABLE user_role ADD COLUMN role_code VARCHAR(64) NULL,
    ADD COLUMN built_in TINYINT(1) NOT NULL DEFAULT 0;
UPDATE user_role SET role_code=CASE role_name WHEN 'ADMIN' THEN 'SUPER_ADMIN' WHEN 'USER' THEN 'USER' ELSE CONCAT('CUSTOM_',id) END,
    built_in=IF(role_name IN ('ADMIN','USER'),1,0);
ALTER TABLE user_role MODIFY role_code VARCHAR(64) NOT NULL,
    ADD UNIQUE KEY uk_user_role_role_code(role_code);
ALTER TABLE user_account ADD COLUMN auth_version BIGINT UNSIGNED NOT NULL DEFAULT 0;

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

START TRANSACTION;
INSERT INTO user_account_role(user_id,role_id)
SELECT u.id,r.id FROM user_account u JOIN user_role r ON r.role_name=u.role_name;
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
COMMIT;

-- Verify the backfill before removing the old relationship.
DELIMITER $$
CREATE PROCEDURE verify_user_rbac()
BEGIN
    IF (SELECT COUNT(*) FROM user_account) <> (SELECT COUNT(*) FROM user_account_role) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Role backfill count mismatch; restore backup';
    END IF;
END$$
DELIMITER ;
CALL verify_user_rbac();
DROP PROCEDURE verify_user_rbac;
ALTER TABLE user_account DROP FOREIGN KEY fk_user_account_role_name,
    DROP INDEX idx_user_account_role_name, DROP COLUMN role_name;
SELECT COUNT(*) AS accounts FROM user_account;
SELECT COUNT(*) AS memberships FROM user_account_role;
SELECT id,role_code,role_name,built_in FROM user_role ORDER BY id;
