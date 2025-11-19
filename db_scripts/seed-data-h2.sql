-- ============================================
-- SEED DATA GENERATION SCRIPT FOR H2 DATABASE
-- FIXED VERSION - No LATERAL joins, proper distribution
-- ============================================

-- Set variables (H2 way)
SET @org_uuid = RANDOM_UUID();

-- ============================================
-- 1. INSERT ORGANIZATION
-- ============================================
INSERT INTO organizations (org_uuid, org_name, created_at, updated_at) 
VALUES (@org_uuid, 'ICP Test Organization', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ============================================
-- 2. INSERT ROLES
-- ============================================

-- Store role IDs
SET @admin_role_id = RANDOM_UUID();
SET @deployer_role_id = RANDOM_UUID();
SET @developer_role_id = RANDOM_UUID();
SET @operator_role_id = RANDOM_UUID();
SET @monitor_role_id = RANDOM_UUID();
SET @viewer_role_id = RANDOM_UUID();
SET @user_manager_role_id = RANDOM_UUID();

INSERT INTO roles (role_id, role_name, description, created_at, updated_at) VALUES
(@admin_role_id, 'Admin', 'Full administrative control within assigned scope', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(@deployer_role_id, 'Deployer', 'Can deploy and manage all environments (prod + non-prod)', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(@developer_role_id, 'Developer', 'Can develop and deploy to non-production environments only', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(@operator_role_id, 'Operator', 'Can manage environments and view observability but not modify components', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(@monitor_role_id, 'Monitor', 'Can view all resources and logs for monitoring/troubleshooting', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(@viewer_role_id, 'Viewer', 'Read-only access to projects and components, no logs', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(@user_manager_role_id, 'User Manager', 'Can manage users, groups, and role assignments', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ============================================
-- 3. ASSIGN PERMISSIONS TO ROLES
-- ============================================

-- Admin gets ALL permissions
INSERT INTO role_permission_mapping (role_id, permission_id, created_at)
SELECT @admin_role_id, permission_id, CURRENT_TIMESTAMP
FROM permissions;

-- Deployer permissions
INSERT INTO role_permission_mapping (role_id, permission_id, created_at)
SELECT @deployer_role_id, permission_id, CURRENT_TIMESTAMP
FROM permissions
WHERE permission_name IN (
    'project:view',
    'component:manage',
    'component:view',
    'component:view_logs',
    'environment:manage',
    'observability:view_logs'
);

-- Developer permissions
INSERT INTO role_permission_mapping (role_id, permission_id, created_at)
SELECT @developer_role_id, permission_id, CURRENT_TIMESTAMP
FROM permissions
WHERE permission_name IN (
    'project:view',
    'component:manage',
    'component:view',
    'component:view_logs',
    'environment:manage_non_prod',
    'observability:view_non_prod_logs'
);

-- Operator permissions
INSERT INTO role_permission_mapping (role_id, permission_id, created_at)
SELECT @operator_role_id, permission_id, CURRENT_TIMESTAMP
FROM permissions
WHERE permission_name IN (
    'project:view',
    'component:view',
    'component:view_logs',
    'environment:manage',
    'observability:view_logs'
);

-- Monitor permissions
INSERT INTO role_permission_mapping (role_id, permission_id, created_at)
SELECT @monitor_role_id, permission_id, CURRENT_TIMESTAMP
FROM permissions
WHERE permission_name IN (
    'project:view',
    'component:view',
    'component:view_logs',
    'observability:view_logs'
);

-- Viewer permissions
INSERT INTO role_permission_mapping (role_id, permission_id, created_at)
SELECT @viewer_role_id, permission_id, CURRENT_TIMESTAMP
FROM permissions
WHERE permission_name IN (
    'project:view',
    'component:view'
);

-- User Manager permissions
INSERT INTO role_permission_mapping (role_id, permission_id, created_at)
SELECT @user_manager_role_id, permission_id, CURRENT_TIMESTAMP
FROM permissions
WHERE permission_name IN (
    'project:view',
    'user:view',
    'user:manage_users',
    'user:view_roles',
    'user:view_groups',
    'user:manage_groups',
    'user:view_permissions',
    'user:create_groups',
    'user:update_groups',
    'user:delete_groups'
);

-- ============================================
-- 4. GENERATE USERS (1,000 users)
-- ============================================

CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS numbers (n INT PRIMARY KEY);
INSERT INTO numbers 
SELECT X FROM SYSTEM_RANGE(1, 1000);

INSERT INTO users (user_uuid, username, display_name, created_at, updated_at)
SELECT 
    RANDOM_UUID(),
    CONCAT('user', LPAD(CAST(n AS VARCHAR), 4, '0')),
    CONCAT('Test User ', CAST(n AS VARCHAR)),
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM numbers;

-- ============================================
-- 5. GENERATE GROUPS (100 groups)
-- ============================================

CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS numbers_groups (n INT PRIMARY KEY);
INSERT INTO numbers_groups 
SELECT X FROM SYSTEM_RANGE(1, 100);

INSERT INTO `groups` (group_id, group_name, org_uuid, description, created_at, updated_at)
SELECT 
    RANDOM_UUID(),
    CONCAT('Team-', CAST(n AS VARCHAR)),
    @org_uuid,
    CONCAT('Test group ', CAST(n AS VARCHAR)),
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM numbers_groups;

-- ============================================
-- 6. GENERATE PROJECTS (500 projects)
-- ============================================

CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS numbers_projects (n INT PRIMARY KEY);
INSERT INTO numbers_projects 
SELECT X FROM SYSTEM_RANGE(1, 500);

INSERT INTO projects (project_uuid, project_name, org_uuid, description, created_at, updated_at)
SELECT 
    RANDOM_UUID(),
    CONCAT('Project-', CAST(n AS VARCHAR)),
    @org_uuid,
    CONCAT('Test project ', CAST(n AS VARCHAR)),
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM numbers_projects;

-- ============================================
-- 7. GENERATE ENVIRONMENTS (1,000 environments, 2 per project)
-- ============================================

INSERT INTO environments (env_uuid, env_name, env_type, project_uuid, description, created_at, updated_at)
SELECT 
    RANDOM_UUID(),
    'dev',
    'non-production',
    project_uuid,
    'Development environment for project',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM projects;

INSERT INTO environments (env_uuid, env_name, env_type, project_uuid, description, created_at, updated_at)
SELECT 
    RANDOM_UUID(),
    'prod',
    'production',
    project_uuid,
    'Production environment for project',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM projects;

-- ============================================
-- 8. CREATE HELPER TABLES FOR ASSIGNMENTS
-- ============================================

CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS group_assignments (
    group_id VARCHAR(36),
    group_number INT
);

INSERT INTO group_assignments
SELECT group_id, ROW_NUMBER() OVER (ORDER BY group_id) as group_number
FROM `groups`;

CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS project_assignments (
    project_uuid VARCHAR(36),
    project_number INT
);

INSERT INTO project_assignments
SELECT project_uuid, ROW_NUMBER() OVER (ORDER BY project_uuid) as project_number
FROM projects;

CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS env_assignments (
    env_uuid VARCHAR(36),
    env_number INT,
    env_type VARCHAR(20)
);

INSERT INTO env_assignments
SELECT env_uuid, ROW_NUMBER() OVER (ORDER BY env_uuid) as env_number, env_type
FROM environments;

-- ============================================
-- 9. MAP GROUPS TO ROLES WITH CONTEXT
-- ============================================

-- 10% Org-level Admin (groups 1-10)
INSERT INTO group_role_mapping (group_id, role_id, org_uuid, project_uuid, env_uuid, created_at)
SELECT group_id, @admin_role_id, @org_uuid, NULL, NULL, CURRENT_TIMESTAMP
FROM group_assignments
WHERE group_number <= 10;

-- 15% Project-level Admin (groups 11-25) - assign 5 projects to each group
INSERT INTO group_role_mapping (group_id, role_id, org_uuid, project_uuid, env_uuid, created_at)
SELECT 
    ga.group_id,
    @admin_role_id,
    @org_uuid,
    pa.project_uuid,
    NULL,
    CURRENT_TIMESTAMP
FROM group_assignments ga
INNER JOIN project_assignments pa ON MOD((ga.group_number - 11) * 500 + pa.project_number, 100) < 5
WHERE ga.group_number > 10 AND ga.group_number <= 25 AND pa.project_number <= 75;

-- 25% Project-level Deployer (groups 26-50) - assign 5 projects to each group
INSERT INTO group_role_mapping (group_id, role_id, org_uuid, project_uuid, env_uuid, created_at)
SELECT 
    ga.group_id,
    @deployer_role_id,
    @org_uuid,
    pa.project_uuid,
    NULL,
    CURRENT_TIMESTAMP
FROM group_assignments ga
INNER JOIN project_assignments pa ON MOD((ga.group_number - 26) * 500 + pa.project_number, 100) < 5
WHERE ga.group_number > 25 AND ga.group_number <= 50 AND pa.project_number <= 125;

-- 30% Project-level Developer (groups 51-80) - assign 5 projects to each group
INSERT INTO group_role_mapping (group_id, role_id, org_uuid, project_uuid, env_uuid, created_at)
SELECT 
    ga.group_id,
    @developer_role_id,
    @org_uuid,
    pa.project_uuid,
    NULL,
    CURRENT_TIMESTAMP
FROM group_assignments ga
INNER JOIN project_assignments pa ON MOD((ga.group_number - 51) * 500 + pa.project_number, 100) < 5
WHERE ga.group_number > 50 AND ga.group_number <= 80 AND pa.project_number <= 150;

-- 10% Environment-level Developer (groups 81-90) - assign 5 non-prod envs to each group
INSERT INTO group_role_mapping (group_id, role_id, org_uuid, project_uuid, env_uuid, created_at)
SELECT 
    ga.group_id,
    @developer_role_id,
    @org_uuid,
    NULL,
    ea.env_uuid,
    CURRENT_TIMESTAMP
FROM group_assignments ga
INNER JOIN env_assignments ea ON MOD((ga.group_number - 81) * 500 + ea.env_number, 100) < 5
WHERE ga.group_number > 80 AND ga.group_number <= 90 
  AND ea.env_type = 'non-production' 
  AND ea.env_number <= 50;

-- 5% Project-level Operator (groups 91-95) - assign 3 projects to each group
INSERT INTO group_role_mapping (group_id, role_id, org_uuid, project_uuid, env_uuid, created_at)
SELECT 
    ga.group_id,
    @operator_role_id,
    @org_uuid,
    pa.project_uuid,
    NULL,
    CURRENT_TIMESTAMP
FROM group_assignments ga
INNER JOIN project_assignments pa ON MOD((ga.group_number - 91) * 500 + pa.project_number, 100) < 3
WHERE ga.group_number > 90 AND ga.group_number <= 95 AND pa.project_number <= 15;

-- 3% Project-level Monitor (groups 96-98) - assign 3 projects to each group
INSERT INTO group_role_mapping (group_id, role_id, org_uuid, project_uuid, env_uuid, created_at)
SELECT 
    ga.group_id,
    @monitor_role_id,
    @org_uuid,
    pa.project_uuid,
    NULL,
    CURRENT_TIMESTAMP
FROM group_assignments ga
INNER JOIN project_assignments pa ON MOD((ga.group_number - 96) * 500 + pa.project_number, 100) < 3
WHERE ga.group_number > 95 AND ga.group_number <= 98 AND pa.project_number <= 9;

-- 2% Org-level User Manager (groups 99-100)
INSERT INTO group_role_mapping (group_id, role_id, org_uuid, project_uuid, env_uuid, created_at)
SELECT group_id, @user_manager_role_id, @org_uuid, NULL, NULL, CURRENT_TIMESTAMP
FROM group_assignments
WHERE group_number > 98;

-- ============================================
-- 10. MAP USERS TO GROUPS (AVOID ORG-LEVEL GROUPS!)
-- ============================================

CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS user_assignments (
    user_uuid VARCHAR(36),
    user_number INT
);

INSERT INTO user_assignments
SELECT user_uuid, ROW_NUMBER() OVER (ORDER BY user_uuid) as user_number
FROM users
WHERE username LIKE 'user%';

-- First group assignment - evenly distribute users across project-level groups (11-98)
INSERT INTO group_user_mapping (group_id, user_uuid, created_at)
SELECT 
    ga.group_id,
    ua.user_uuid,
    CURRENT_TIMESTAMP
FROM user_assignments ua
INNER JOIN group_assignments ga ON MOD(ua.user_number, 88) + 11 = ga.group_number;

-- Second group assignment - assign to different project-level groups
INSERT INTO group_user_mapping (group_id, user_uuid, created_at)
SELECT 
    ga.group_id,
    ua.user_uuid,
    CURRENT_TIMESTAMP
FROM user_assignments ua
INNER JOIN group_assignments ga ON MOD(ua.user_number + 29, 88) + 11 = ga.group_number
WHERE MOD(ua.user_number, 10) < 7;  -- 70% get second group

-- Third group assignment - another different project-level group
INSERT INTO group_user_mapping (group_id, user_uuid, created_at)
SELECT 
    ga.group_id,
    ua.user_uuid,
    CURRENT_TIMESTAMP
FROM user_assignments ua
INNER JOIN group_assignments ga ON MOD(ua.user_number + 59, 88) + 11 = ga.group_number
WHERE MOD(ua.user_number, 10) < 3;  -- 30% get third group

-- ============================================
-- 11. CREATE TEST EDGE CASE USERS
-- ============================================

-- User with NO access
INSERT INTO users (user_uuid, username, display_name, created_at, updated_at)
VALUES (RANDOM_UUID(), 'user_no_access', 'User With No Access', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Super admin user (org-level admin)
SET @super_user_uuid = RANDOM_UUID();
SET @super_group_id = RANDOM_UUID();

INSERT INTO users (user_uuid, username, display_name, created_at, updated_at)
VALUES (@super_user_uuid, 'super_admin', 'Super Admin User', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO `groups` (group_id, group_name, org_uuid, description, created_at, updated_at)
VALUES (@super_group_id, 'Super-Admin-Group', @org_uuid, 'Super admin group', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO group_user_mapping (group_id, user_uuid, created_at)
VALUES (@super_group_id, @super_user_uuid, CURRENT_TIMESTAMP);

INSERT INTO group_role_mapping (group_id, role_id, org_uuid, project_uuid, env_uuid, created_at)
VALUES (@super_group_id, @admin_role_id, @org_uuid, NULL, NULL, CURRENT_TIMESTAMP);

-- User with only 1 project access
SET @single_project_user_uuid = RANDOM_UUID();
SET @single_project_group_id = RANDOM_UUID();
SET @single_project_uuid = (SELECT project_uuid FROM projects LIMIT 1);

INSERT INTO users (user_uuid, username, display_name, created_at, updated_at)
VALUES (@single_project_user_uuid, 'single_project_user', 'User With Single Project', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO `groups` (group_id, group_name, org_uuid, description, created_at, updated_at)
VALUES (@single_project_group_id, 'Single-Project-Group', @org_uuid, 'Single project group', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO group_user_mapping (group_id, user_uuid, created_at)
VALUES (@single_project_group_id, @single_project_user_uuid, CURRENT_TIMESTAMP);

INSERT INTO group_role_mapping (group_id, role_id, org_uuid, project_uuid, env_uuid, created_at)
VALUES (@single_project_group_id, @developer_role_id, @org_uuid, @single_project_uuid, NULL, CURRENT_TIMESTAMP);

-- User with only environment-level access
SET @env_only_user_uuid = RANDOM_UUID();
SET @env_only_group_id = RANDOM_UUID();
SET @env_only_env_uuid = (SELECT env_uuid FROM environments WHERE env_type = 'non-production' LIMIT 1);

INSERT INTO users (user_uuid, username, display_name, created_at, updated_at)
VALUES (@env_only_user_uuid, 'env_only_user', 'User With Single Environment Access', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO `groups` (group_id, group_name, org_uuid, description, created_at, updated_at)
VALUES (@env_only_group_id, 'Single-Env-Group', @org_uuid, 'Single environment group', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO group_user_mapping (group_id, user_uuid, created_at)
VALUES (@env_only_group_id, @env_only_user_uuid, CURRENT_TIMESTAMP);

INSERT INTO group_role_mapping (group_id, role_id, org_uuid, project_uuid, env_uuid, created_at)
VALUES (@env_only_group_id, @developer_role_id, @org_uuid, NULL, @env_only_env_uuid, CURRENT_TIMESTAMP);

-- User in many groups (15 groups) - only project-level groups
SET @multi_group_user_uuid = RANDOM_UUID();

INSERT INTO users (user_uuid, username, display_name, created_at, updated_at)
VALUES (@multi_group_user_uuid, 'multi_group_user', 'User In Many Groups', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO group_user_mapping (group_id, user_uuid, created_at)
SELECT group_id, @multi_group_user_uuid, CURRENT_TIMESTAMP
FROM group_assignments
WHERE group_number BETWEEN 11 AND 25
LIMIT 15;

-- Clean up temporary tables
DROP TABLE IF EXISTS numbers;
DROP TABLE IF EXISTS numbers_groups;
DROP TABLE IF EXISTS numbers_projects;
DROP TABLE IF EXISTS group_assignments;
DROP TABLE IF EXISTS user_assignments;
DROP TABLE IF EXISTS project_assignments;
DROP TABLE IF EXISTS env_assignments;

-- ============================================
-- 12. VERIFICATION QUERIES
-- ============================================

SELECT '=== DATA GENERATION SUMMARY ===' AS SUMMARY;

SELECT 'Organizations' AS entity, COUNT(*) AS count FROM organizations
UNION ALL
SELECT 'Users', COUNT(*) FROM users
UNION ALL
SELECT 'Groups', COUNT(*) FROM `groups`
UNION ALL
SELECT 'Roles', COUNT(*) FROM roles
UNION ALL
SELECT 'Permissions', COUNT(*) FROM permissions
UNION ALL
SELECT 'Projects', COUNT(*) FROM projects
UNION ALL
SELECT 'Environments', COUNT(*) FROM environments
UNION ALL
SELECT 'Group-User Mappings', COUNT(*) FROM group_user_mapping
UNION ALL
SELECT 'Group-Role Mappings', COUNT(*) FROM group_role_mapping
UNION ALL
SELECT 'Role-Permission Mappings', COUNT(*) FROM role_permission_mapping;

SELECT '=== DATA GENERATION COMPLETE ===' AS STATUS;
