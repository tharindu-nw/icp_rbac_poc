-- ============================================
-- RBAC Schema for ICP PoC
-- Focus: Project and Environment level permissions
-- ============================================

-- Create database if it doesn't exist
CREATE DATABASE IF NOT EXISTS icp_rbac_poc;

-- Switch to the database
USE icp_rbac_poc;

-- ============================================
-- DROP EXISTING VIEWS (if re-running script)
-- ============================================
DROP VIEW IF EXISTS v_user_environment_access;
DROP VIEW IF EXISTS v_user_project_access;

-- ============================================
-- DROP EXISTING TABLES (if re-running script)
-- ============================================
DROP TABLE IF EXISTS role_permission_mapping;
DROP TABLE IF EXISTS group_role_mapping;
DROP TABLE IF EXISTS group_user_mapping;
DROP TABLE IF EXISTS environments;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS permissions;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS `groups`;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS organizations;

-- ============================================
-- CREATE TABLES
-- ============================================

-- Organizations table
CREATE TABLE organizations (
    org_uuid VARCHAR(36) PRIMARY KEY,
    org_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Users table
CREATE TABLE users (
    user_uuid VARCHAR(36) PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    display_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Groups table (using backticks because 'groups' is a reserved keyword)
CREATE TABLE `groups` (
    group_id VARCHAR(36) PRIMARY KEY,
    group_name VARCHAR(255) NOT NULL,
    org_uuid VARCHAR(36) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (org_uuid) REFERENCES organizations(org_uuid) ON DELETE CASCADE,
    INDEX idx_org_uuid (org_uuid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Roles table
CREATE TABLE roles (
    role_id VARCHAR(36) PRIMARY KEY,
    role_name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_role_name (role_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Permissions table with domain grouping
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
    resource_type VARCHAR(100) NOT NULL, -- e.g., 'project', 'environment', 'component', 'user'
    action VARCHAR(100) NOT NULL, -- e.g., 'read', 'write', 'delete', 'manage'
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_permission_domain (permission_domain),
    INDEX idx_resource_type (resource_type),
    INDEX idx_permission_name (permission_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Projects table
CREATE TABLE projects (
    project_uuid VARCHAR(36) PRIMARY KEY,
    project_name VARCHAR(255) NOT NULL,
    org_uuid VARCHAR(36) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (org_uuid) REFERENCES organizations(org_uuid) ON DELETE CASCADE,
    INDEX idx_org_uuid (org_uuid),
    INDEX idx_project_name (project_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Environments table
CREATE TABLE environments (
    env_uuid VARCHAR(36) PRIMARY KEY,
    env_name VARCHAR(255) NOT NULL,
    env_type ENUM('production', 'non-production') NOT NULL DEFAULT 'non-production',
    project_uuid VARCHAR(36) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (project_uuid) REFERENCES projects(project_uuid) ON DELETE CASCADE,
    INDEX idx_project_uuid (project_uuid),
    INDEX idx_env_name (env_name),
    INDEX idx_env_type (env_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- MAPPING TABLES
-- ============================================

-- Group-User mapping (Many-to-Many)
CREATE TABLE group_user_mapping (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    group_id VARCHAR(36) NOT NULL,
    user_uuid VARCHAR(36) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES `groups`(group_id) ON DELETE CASCADE,
    FOREIGN KEY (user_uuid) REFERENCES users(user_uuid) ON DELETE CASCADE,
    UNIQUE KEY unique_group_user (group_id, user_uuid),
    INDEX idx_user_uuid (user_uuid),
    INDEX idx_group_id (group_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Group-Role mapping with context (Many-to-Many with context)
-- Context: org_uuid, project_uuid, env_uuid define the scope
CREATE TABLE group_role_mapping (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    group_id VARCHAR(36) NOT NULL,
    role_id VARCHAR(36) NOT NULL,
    org_uuid VARCHAR(36) NULL, -- NULL means not scoped to org
    project_uuid VARCHAR(36) NULL, -- NULL means not scoped to project
    env_uuid VARCHAR(36) NULL, -- NULL means not scoped to environment
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES `groups`(group_id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE,
    FOREIGN KEY (org_uuid) REFERENCES organizations(org_uuid) ON DELETE CASCADE,
    FOREIGN KEY (project_uuid) REFERENCES projects(project_uuid) ON DELETE CASCADE,
    FOREIGN KEY (env_uuid) REFERENCES environments(env_uuid) ON DELETE CASCADE,
    -- Prevent duplicate mappings for same context
    UNIQUE KEY unique_group_role_context (group_id, role_id, org_uuid, project_uuid, env_uuid),
    INDEX idx_group_id (group_id),
    INDEX idx_role_id (role_id),
    INDEX idx_org_uuid (org_uuid),
    INDEX idx_project_uuid (project_uuid),
    INDEX idx_env_uuid (env_uuid),
    -- Composite indexes for common queries
    INDEX idx_group_project (group_id, project_uuid),
    INDEX idx_group_env (group_id, env_uuid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Role-Permission mapping (Many-to-Many)
CREATE TABLE role_permission_mapping (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    role_id VARCHAR(36) NOT NULL,
    permission_id VARCHAR(36) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(permission_id) ON DELETE CASCADE,
    UNIQUE KEY unique_role_permission (role_id, permission_id),
    INDEX idx_role_id (role_id),
    INDEX idx_permission_id (permission_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- SEED DATA FOR PERMISSIONS
-- ============================================

-- Insert all ICP permissions grouped by domain
INSERT INTO permissions (permission_id, permission_name, permission_domain, resource_type, action, description) VALUES
-- Component-Management domain
(UUID(), 'component:manage', 'Component-Management', 'component', 'manage', 'Manage Component (Create, Edit and Delete)'),
(UUID(), 'component:view', 'Component-Management', 'component', 'read', 'View Component'),
(UUID(), 'component:view_logs', 'Component-Management', 'component', 'read', 'View Component Logs'),

-- Environment-Management domain
(UUID(), 'environment:manage', 'Environment-Management', 'environment', 'manage', 'Manage Environment (Create, Edit and Delete)'),
(UUID(), 'environment:manage_non_prod', 'Environment-Management', 'environment', 'manage', 'Manage Non-Prod Environment (Create, Edit and Delete non-production environments)'),
(UUID(), 'environment:manage_prod', 'Environment-Management', 'environment', 'manage', 'Manage Prod Environment'),

-- Observability-Management domain
(UUID(), 'observability:view_logs', 'Observability-Management', 'observability', 'read', 'View Logs'),
(UUID(), 'observability:view_prod_logs', 'Observability-Management', 'observability', 'read', 'View Prod Logs'),
(UUID(), 'observability:view_non_prod_logs', 'Observability-Management', 'observability', 'read', 'View Non-Prod Logs'),

-- Project-Management domain
(UUID(), 'project:view', 'Project-Management', 'project', 'read', 'View Projects'),
(UUID(), 'project:manage', 'Project-Management', 'project', 'manage', 'Manage Projects (create, edit and delete)'),
(UUID(), 'project:manage_components', 'Project-Management', 'project', 'manage', 'Manage Project Components (manage components within project)'),

-- User-Management domain
(UUID(), 'user:view', 'User-Management', 'user', 'read', 'View Users'),
(UUID(), 'user:view_permissions', 'User-Management', 'permission', 'read', 'View Permissions'),
(UUID(), 'user:update_groups', 'User-Management', 'group', 'write', 'Update Groups (Update group role mappings)'),
(UUID(), 'user:view_roles', 'User-Management', 'role', 'read', 'View Roles'),
(UUID(), 'user:delete_roles', 'User-Management', 'role', 'delete', 'Delete Roles'),
(UUID(), 'user:manage_users', 'User-Management', 'user', 'manage', 'Manage Users'),
(UUID(), 'user:delete_users', 'User-Management', 'user', 'delete', 'Delete Users'),
(UUID(), 'user:view_groups', 'User-Management', 'group', 'read', 'View Groups (View group role mappings)'),
(UUID(), 'user:delete_groups', 'User-Management', 'group', 'delete', 'Delete Groups (Delete group role mappings)'),
(UUID(), 'user:create_roles', 'User-Management', 'role', 'write', 'Create Roles'),
(UUID(), 'user:manage_roles', 'User-Management', 'role', 'manage', 'Manage Roles'),
(UUID(), 'user:update_users', 'User-Management', 'user', 'write', 'Update Users'),
(UUID(), 'user:create_groups', 'User-Management', 'group', 'write', 'Create Groups (Create group role mappings)'),
(UUID(), 'user:manage_groups', 'User-Management', 'group', 'manage', 'Manage Groups (Manage group role mappings)'),
(UUID(), 'user:update_roles', 'User-Management', 'role', 'write', 'Update Roles');

-- ============================================
-- VIEWS FOR COMMON QUERIES
-- ============================================

-- View: User's accessible projects (covers all scenarios)
-- Scenario 1: Direct project-level access via group_role_mapping.project_uuid
-- Scenario 2: Org-level access (inherits all projects in the org)
CREATE OR REPLACE VIEW v_user_project_access AS
-- Direct project-level access
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

-- Org-level access (inherits all projects)
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

-- View: User's accessible environments (covers all scenarios)
-- Scenario 1: Direct env-level access
-- Scenario 2: Project-level access (inherits all envs in the project)
-- Scenario 3: Org-level access (inherits all envs in all projects in the org)
CREATE OR REPLACE VIEW v_user_environment_access AS
-- Direct environment-level access
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

-- Project-level access (inherits all environments in project)
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

-- Org-level access (inherits all environments in all projects in org)
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

-- ============================================
-- SCHEMA CREATION COMPLETE
-- ============================================

SELECT '=== SCHEMA CREATED SUCCESSFULLY ===' AS '';
SELECT 'Database: icp_rbac_poc' AS '';
SELECT 'Tables: 8 core tables + 3 mapping tables' AS '';
SELECT 'Views: 2 (v_user_project_access, v_user_environment_access)' AS '';
SELECT 'Permissions: 26 permissions across 5 domains' AS '';
