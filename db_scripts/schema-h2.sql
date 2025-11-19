-- ============================================
-- RBAC Schema for ICP PoC - H2 Database
-- H2 with MySQL MODE for compatibility
-- ============================================

-- Drop existing database objects completely (in case of re-run)
DROP VIEW IF EXISTS v_user_environment_access;
DROP VIEW IF EXISTS v_user_project_access;

DROP TABLE IF EXISTS role_permission_mapping CASCADE;
DROP TABLE IF EXISTS group_role_mapping CASCADE;
DROP TABLE IF EXISTS group_user_mapping CASCADE;
DROP TABLE IF EXISTS environments CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS permissions CASCADE;
DROP TABLE IF EXISTS roles CASCADE;
DROP TABLE IF EXISTS `groups` CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS organizations CASCADE;

-- Organizations table
CREATE TABLE organizations (
    org_uuid VARCHAR(36) PRIMARY KEY,
    org_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Users table
CREATE TABLE users (
    user_uuid VARCHAR(36) PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    display_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_username ON users(username);

-- Groups table (groups is a reserved word, use backticks)
CREATE TABLE `groups` (
    group_id VARCHAR(36) PRIMARY KEY,
    group_name VARCHAR(255) NOT NULL,
    org_uuid VARCHAR(36) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_groups_org FOREIGN KEY (org_uuid) REFERENCES organizations(org_uuid) ON DELETE CASCADE
);

CREATE INDEX idx_groups_org ON `groups`(org_uuid);

-- Roles table
CREATE TABLE roles (
    role_id VARCHAR(36) PRIMARY KEY,
    role_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Permissions table
CREATE TABLE permissions (
    permission_id VARCHAR(36) PRIMARY KEY,
    permission_name VARCHAR(255) NOT NULL UNIQUE,
    permission_domain ENUM(
        'Component-Management',
        'Environment-Management', 
        'Observability-Management',
        'Project-Management',
        'User-Management'
    ) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    action VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE INDEX idx_perms_domain ON permissions(permission_domain);
CREATE INDEX idx_perms_resource ON permissions(resource_type);
CREATE INDEX idx_perms_name ON permissions(permission_name);

-- Projects table
CREATE TABLE projects (
    project_uuid VARCHAR(36) PRIMARY KEY,
    project_name VARCHAR(255) NOT NULL,
    org_uuid VARCHAR(36) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_projects_org FOREIGN KEY (org_uuid) REFERENCES organizations(org_uuid) ON DELETE CASCADE
);

CREATE INDEX idx_projects_org ON projects(org_uuid);
CREATE INDEX idx_projects_name ON projects(project_name);

-- Environments table
CREATE TABLE environments (
    env_uuid VARCHAR(36) PRIMARY KEY,
    env_name VARCHAR(255) NOT NULL,
    env_type ENUM('production', 'non-production') NOT NULL DEFAULT 'non-production',
    project_uuid VARCHAR(36) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_envs_project FOREIGN KEY (project_uuid) REFERENCES projects(project_uuid) ON DELETE CASCADE
);

CREATE INDEX idx_envs_project ON environments(project_uuid);
CREATE INDEX idx_envs_name ON environments(env_name);
CREATE INDEX idx_envs_type ON environments(env_type);

-- Group-User mapping
CREATE TABLE group_user_mapping (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    group_id VARCHAR(36) NOT NULL,
    user_uuid VARCHAR(36) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_gum_group FOREIGN KEY (group_id) REFERENCES `groups`(group_id) ON DELETE CASCADE,
    CONSTRAINT fk_gum_user FOREIGN KEY (user_uuid) REFERENCES users(user_uuid) ON DELETE CASCADE,
    CONSTRAINT uk_gum_group_user UNIQUE (group_id, user_uuid)
);

CREATE INDEX idx_gum_user ON group_user_mapping(user_uuid);
CREATE INDEX idx_gum_group ON group_user_mapping(group_id);

-- Group-Role mapping with context
CREATE TABLE group_role_mapping (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    group_id VARCHAR(36) NOT NULL,
    role_id VARCHAR(36) NOT NULL,
    org_uuid VARCHAR(36) NULL,
    project_uuid VARCHAR(36) NULL,
    env_uuid VARCHAR(36) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_grm_group FOREIGN KEY (group_id) REFERENCES `groups`(group_id) ON DELETE CASCADE,
    CONSTRAINT fk_grm_role FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE,
    CONSTRAINT fk_grm_org FOREIGN KEY (org_uuid) REFERENCES organizations(org_uuid) ON DELETE CASCADE,
    CONSTRAINT fk_grm_project FOREIGN KEY (project_uuid) REFERENCES projects(project_uuid) ON DELETE CASCADE,
    CONSTRAINT fk_grm_env FOREIGN KEY (env_uuid) REFERENCES environments(env_uuid) ON DELETE CASCADE,
    CONSTRAINT uk_grm_context UNIQUE (group_id, role_id, org_uuid, project_uuid, env_uuid)
);

CREATE INDEX idx_grm_group ON group_role_mapping(group_id);
CREATE INDEX idx_grm_role ON group_role_mapping(role_id);
CREATE INDEX idx_grm_org ON group_role_mapping(org_uuid);
CREATE INDEX idx_grm_project ON group_role_mapping(project_uuid);
CREATE INDEX idx_grm_env ON group_role_mapping(env_uuid);
CREATE INDEX idx_grm_grp_proj ON group_role_mapping(group_id, project_uuid);
CREATE INDEX idx_grm_grp_env ON group_role_mapping(group_id, env_uuid);

-- Role-Permission mapping
CREATE TABLE role_permission_mapping (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    role_id VARCHAR(36) NOT NULL,
    permission_id VARCHAR(36) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_rpm_role FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE,
    CONSTRAINT fk_rpm_perm FOREIGN KEY (permission_id) REFERENCES permissions(permission_id) ON DELETE CASCADE,
    CONSTRAINT uk_rpm_role_perm UNIQUE (role_id, permission_id)
);

CREATE INDEX idx_rpm_role ON role_permission_mapping(role_id);
CREATE INDEX idx_rpm_perm ON role_permission_mapping(permission_id);

-- Insert permissions (using RANDOM_UUID for H2)
INSERT INTO permissions (permission_id, permission_name, permission_domain, resource_type, action, description) VALUES
-- Component-Management
(RANDOM_UUID(), 'component:manage', 'Component-Management', 'component', 'manage', 'Manage Component (Create, Edit and Delete)'),
(RANDOM_UUID(), 'component:view', 'Component-Management', 'component', 'read', 'View Component'),
(RANDOM_UUID(), 'component:view_logs', 'Component-Management', 'component', 'read', 'View Component Logs'),

-- Environment-Management
(RANDOM_UUID(), 'environment:manage', 'Environment-Management', 'environment', 'manage', 'Manage Environment (Create, Edit and Delete)'),
(RANDOM_UUID(), 'environment:manage_non_prod', 'Environment-Management', 'environment', 'manage', 'Manage Non-Prod Environment'),
(RANDOM_UUID(), 'environment:manage_prod', 'Environment-Management', 'environment', 'manage', 'Manage Prod Environment'),

-- Observability-Management
(RANDOM_UUID(), 'observability:view_logs', 'Observability-Management', 'observability', 'read', 'View Logs'),
(RANDOM_UUID(), 'observability:view_prod_logs', 'Observability-Management', 'observability', 'read', 'View Prod Logs'),
(RANDOM_UUID(), 'observability:view_non_prod_logs', 'Observability-Management', 'observability', 'read', 'View Non-Prod Logs'),

-- Project-Management
(RANDOM_UUID(), 'project:view', 'Project-Management', 'project', 'read', 'View Projects'),
(RANDOM_UUID(), 'project:manage', 'Project-Management', 'project', 'manage', 'Manage Projects'),
(RANDOM_UUID(), 'project:manage_components', 'Project-Management', 'project', 'manage', 'Manage Project Components'),

-- User-Management
(RANDOM_UUID(), 'user:view', 'User-Management', 'user', 'read', 'View Users'),
(RANDOM_UUID(), 'user:view_permissions', 'User-Management', 'permission', 'read', 'View Permissions'),
(RANDOM_UUID(), 'user:update_groups', 'User-Management', 'group', 'write', 'Update Groups'),
(RANDOM_UUID(), 'user:view_roles', 'User-Management', 'role', 'read', 'View Roles'),
(RANDOM_UUID(), 'user:delete_roles', 'User-Management', 'role', 'delete', 'Delete Roles'),
(RANDOM_UUID(), 'user:manage_users', 'User-Management', 'user', 'manage', 'Manage Users'),
(RANDOM_UUID(), 'user:delete_users', 'User-Management', 'user', 'delete', 'Delete Users'),
(RANDOM_UUID(), 'user:view_groups', 'User-Management', 'group', 'read', 'View Groups'),
(RANDOM_UUID(), 'user:delete_groups', 'User-Management', 'group', 'delete', 'Delete Groups'),
(RANDOM_UUID(), 'user:create_roles', 'User-Management', 'role', 'write', 'Create Roles'),
(RANDOM_UUID(), 'user:manage_roles', 'User-Management', 'role', 'manage', 'Manage Roles'),
(RANDOM_UUID(), 'user:update_users', 'User-Management', 'user', 'write', 'Update Users'),
(RANDOM_UUID(), 'user:create_groups', 'User-Management', 'group', 'write', 'Create Groups'),
(RANDOM_UUID(), 'user:manage_groups', 'User-Management', 'group', 'manage', 'Manage Groups'),
(RANDOM_UUID(), 'user:update_roles', 'User-Management', 'role', 'write', 'Update Roles');

-- Create views
CREATE VIEW v_user_project_access AS
SELECT DISTINCT
    gum.user_uuid,
    grm.project_uuid,
    p.project_name,
    p.org_uuid,
    grm.role_id,
    'project' AS access_level
FROM group_user_mapping gum
INNER JOIN group_role_mapping grm ON gum.group_id = grm.group_id
INNER JOIN projects p ON grm.project_uuid = p.project_uuid
WHERE grm.project_uuid IS NOT NULL

UNION

SELECT DISTINCT
    gum.user_uuid,
    p.project_uuid,
    p.project_name,
    p.org_uuid,
    grm.role_id,
    'org' AS access_level
FROM group_user_mapping gum
INNER JOIN group_role_mapping grm ON gum.group_id = grm.group_id
INNER JOIN projects p ON grm.org_uuid = p.org_uuid
WHERE grm.org_uuid IS NOT NULL 
  AND grm.project_uuid IS NULL 
  AND grm.env_uuid IS NULL;

CREATE VIEW v_user_environment_access AS
SELECT DISTINCT
    gum.user_uuid,
    e.env_uuid,
    e.env_name,
    e.env_type,
    e.project_uuid,
    p.project_name,
    p.org_uuid,
    grm.role_id,
    'environment' AS access_level
FROM group_user_mapping gum
INNER JOIN group_role_mapping grm ON gum.group_id = grm.group_id
INNER JOIN environments e ON grm.env_uuid = e.env_uuid
INNER JOIN projects p ON e.project_uuid = p.project_uuid
WHERE grm.env_uuid IS NOT NULL

UNION

SELECT DISTINCT
    gum.user_uuid,
    e.env_uuid,
    e.env_name,
    e.env_type,
    e.project_uuid,
    p.project_name,
    p.org_uuid,
    grm.role_id,
    'project' AS access_level
FROM group_user_mapping gum
INNER JOIN group_role_mapping grm ON gum.group_id = grm.group_id
INNER JOIN environments e ON grm.project_uuid = e.project_uuid
INNER JOIN projects p ON e.project_uuid = p.project_uuid
WHERE grm.project_uuid IS NOT NULL 
  AND grm.env_uuid IS NULL

UNION

SELECT DISTINCT
    gum.user_uuid,
    e.env_uuid,
    e.env_name,
    e.env_type,
    e.project_uuid,
    p.project_name,
    p.org_uuid,
    grm.role_id,
    'org' AS access_level
FROM group_user_mapping gum
INNER JOIN group_role_mapping grm ON gum.group_id = grm.group_id
INNER JOIN projects p ON grm.org_uuid = p.org_uuid
INNER JOIN environments e ON p.project_uuid = e.project_uuid
WHERE grm.org_uuid IS NOT NULL 
  AND grm.project_uuid IS NULL 
  AND grm.env_uuid IS NULL;

SELECT '=== H2 SCHEMA CREATED SUCCESSFULLY ===' AS STATUS;
