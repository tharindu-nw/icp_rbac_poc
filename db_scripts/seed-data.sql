-- ============================================
-- SEED DATA GENERATION SCRIPT FOR RBAC PoC
-- ============================================
-- This script generates realistic test data for:
-- - 1 Organization
-- - 1,000 Users
-- - 100 Groups
-- - 7 Roles (Admin, Deployer, Developer, Operator, Monitor, Viewer, User Manager)
-- - 500 Projects
-- - 1,000 Environments (2 per project avg)
-- - Realistic mappings with focus on project and env-level permissions
-- ============================================

USE icp_rbac_poc;

SET @org_uuid = UUID();
SET @batch_size = 100;

-- ============================================
-- 1. INSERT ORGANIZATION
-- ============================================
INSERT INTO organizations (org_uuid, org_name, created_at, updated_at) 
VALUES (@org_uuid, 'ICP Test Organization', NOW(), NOW());

-- ============================================
-- 2. INSERT ROLES
-- ============================================

-- Admin Role
SET @admin_role_id = UUID();
INSERT INTO roles (role_id, role_name, description, created_at, updated_at)
VALUES (@admin_role_id, 'Admin', 'Full administrative control within assigned scope', NOW(), NOW());

-- Deployer Role
SET @deployer_role_id = UUID();
INSERT INTO roles (role_id, role_name, description, created_at, updated_at)
VALUES (@deployer_role_id, 'Deployer', 'Can deploy and manage all environments (prod + non-prod)', NOW(), NOW());

-- Developer Role
SET @developer_role_id = UUID();
INSERT INTO roles (role_id, role_name, description, created_at, updated_at)
VALUES (@developer_role_id, 'Developer', 'Can develop and deploy to non-production environments only', NOW(), NOW());

-- Operator Role
SET @operator_role_id = UUID();
INSERT INTO roles (role_id, role_name, description, created_at, updated_at)
VALUES (@operator_role_id, 'Operator', 'Can manage environments and view observability but not modify components', NOW(), NOW());

-- Monitor Role
SET @monitor_role_id = UUID();
INSERT INTO roles (role_id, role_name, description, created_at, updated_at)
VALUES (@monitor_role_id, 'Monitor', 'Can view all resources and logs for monitoring/troubleshooting', NOW(), NOW());

-- Viewer Role
SET @viewer_role_id = UUID();
INSERT INTO roles (role_id, role_name, description, created_at, updated_at)
VALUES (@viewer_role_id, 'Viewer', 'Read-only access to projects and components, no logs', NOW(), NOW());

-- User Manager Role
SET @user_manager_role_id = UUID();
INSERT INTO roles (role_id, role_name, description, created_at, updated_at)
VALUES (@user_manager_role_id, 'User Manager', 'Can manage users, groups, and role assignments', NOW(), NOW());

-- ============================================
-- 3. ASSIGN PERMISSIONS TO ROLES
-- ============================================

-- Admin gets ALL permissions (26 permissions)
INSERT INTO role_permission_mapping (role_id, permission_id, created_at)
SELECT @admin_role_id, permission_id, NOW()
FROM permissions;

-- Deployer permissions (6 permissions)
INSERT INTO role_permission_mapping (role_id, permission_id, created_at)
SELECT @deployer_role_id, permission_id, NOW()
FROM permissions
WHERE permission_name IN (
    'project:view',
    'component:manage',
    'component:view',
    'component:view_logs',
    'environment:manage',
    'observability:view_logs'
);

-- Developer permissions (6 permissions)
INSERT INTO role_permission_mapping (role_id, permission_id, created_at)
SELECT @developer_role_id, permission_id, NOW()
FROM permissions
WHERE permission_name IN (
    'project:view',
    'component:manage',
    'component:view',
    'component:view_logs',
    'environment:manage_non_prod',
    'observability:view_non_prod_logs'
);

-- Operator permissions (5 permissions)
INSERT INTO role_permission_mapping (role_id, permission_id, created_at)
SELECT @operator_role_id, permission_id, NOW()
FROM permissions
WHERE permission_name IN (
    'project:view',
    'component:view',
    'component:view_logs',
    'environment:manage',
    'observability:view_logs'
);

-- Monitor permissions (4 permissions)
INSERT INTO role_permission_mapping (role_id, permission_id, created_at)
SELECT @monitor_role_id, permission_id, NOW()
FROM permissions
WHERE permission_name IN (
    'project:view',
    'component:view',
    'component:view_logs',
    'observability:view_logs'
);

-- Viewer permissions (2 permissions)
INSERT INTO role_permission_mapping (role_id, permission_id, created_at)
SELECT @viewer_role_id, permission_id, NOW()
FROM permissions
WHERE permission_name IN (
    'project:view',
    'component:view'
);

-- User Manager permissions (10 permissions)
INSERT INTO role_permission_mapping (role_id, permission_id, created_at)
SELECT @user_manager_role_id, permission_id, NOW()
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

DELIMITER $$

DROP PROCEDURE IF EXISTS generate_users$$
CREATE PROCEDURE generate_users()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE user_uuid_val VARCHAR(36);
    
    WHILE i <= 1000 DO
        SET user_uuid_val = UUID();
        INSERT INTO users (user_uuid, username, display_name, created_at, updated_at)
        VALUES (
            user_uuid_val,
            CONCAT('user', LPAD(i, 4, '0')),
            CONCAT('Test User ', i),
            NOW(),
            NOW()
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

CALL generate_users();
DROP PROCEDURE IF EXISTS generate_users;

-- ============================================
-- 5. GENERATE GROUPS (100 groups)
-- ============================================

DELIMITER $$

DROP PROCEDURE IF EXISTS generate_groups$$
CREATE PROCEDURE generate_groups()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE group_uuid_val VARCHAR(36);
    
    WHILE i <= 100 DO
        SET group_uuid_val = UUID();
        INSERT INTO `groups` (group_id, group_name, org_uuid, description, created_at, updated_at)
        VALUES (
            group_uuid_val,
            CONCAT('Team-', i),
            @org_uuid,
            CONCAT('Test group ', i),
            NOW(),
            NOW()
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

CALL generate_groups();
DROP PROCEDURE IF EXISTS generate_groups;

-- ============================================
-- 6. GENERATE PROJECTS (500 projects)
-- ============================================

DELIMITER $$

DROP PROCEDURE IF EXISTS generate_projects$$
CREATE PROCEDURE generate_projects()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE project_uuid_val VARCHAR(36);
    
    WHILE i <= 500 DO
        SET project_uuid_val = UUID();
        INSERT INTO projects (project_uuid, project_name, org_uuid, description, created_at, updated_at)
        VALUES (
            project_uuid_val,
            CONCAT('Project-', i),
            @org_uuid,
            CONCAT('Test project ', i),
            NOW(),
            NOW()
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

CALL generate_projects();
DROP PROCEDURE IF EXISTS generate_projects;

-- ============================================
-- 7. GENERATE ENVIRONMENTS (1,000 environments, 2 per project avg)
-- ============================================

DELIMITER $$

DROP PROCEDURE IF EXISTS generate_environments$$
CREATE PROCEDURE generate_environments()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE proj_uuid VARCHAR(36);
    DECLARE env_counter INT DEFAULT 1;
    DECLARE cur CURSOR FOR SELECT project_uuid FROM projects;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO proj_uuid;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Create dev environment (non-production)
        INSERT INTO environments (env_uuid, env_name, env_type, project_uuid, description, created_at, updated_at)
        VALUES (
            UUID(),
            'dev',
            'non-production',
            proj_uuid,
            CONCAT('Development environment for project'),
            NOW(),
            NOW()
        );
        
        -- Create prod environment (production) for every project
        INSERT INTO environments (env_uuid, env_name, env_type, project_uuid, description, created_at, updated_at)
        VALUES (
            UUID(),
            'prod',
            'production',
            proj_uuid,
            CONCAT('Production environment for project'),
            NOW(),
            NOW()
        );
        
        SET env_counter = env_counter + 2;
    END LOOP;
    
    CLOSE cur;
END$$

DELIMITER ;

CALL generate_environments();
DROP PROCEDURE IF EXISTS generate_environments;

-- ============================================
-- 8. MAP USERS TO GROUPS (Realistic distribution)
-- ============================================
-- Distribution:
-- - Each user belongs to 1-5 groups (avg 3)
-- - Each group has 20-50 users

DELIMITER $$

DROP PROCEDURE IF EXISTS map_users_to_groups$$
CREATE PROCEDURE map_users_to_groups()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE u_uuid VARCHAR(36);
    DECLARE num_groups INT;
    DECLARE i INT;
    DECLARE random_group_id VARCHAR(36);
    DECLARE cur CURSOR FOR SELECT user_uuid FROM users;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO u_uuid;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Each user joins 1-5 groups (weighted towards 3)
        SET num_groups = FLOOR(1 + (RAND() * 5));
        SET i = 0;
        
        WHILE i < num_groups DO
            -- Pick a random group
            SELECT group_id INTO random_group_id 
            FROM `groups` 
            ORDER BY RAND() 
            LIMIT 1;
            
            -- Insert if not already exists
            INSERT IGNORE INTO group_user_mapping (group_id, user_uuid, created_at)
            VALUES (random_group_id, u_uuid, NOW());
            
            SET i = i + 1;
        END WHILE;
        
    END LOOP;
    
    CLOSE cur;
END$$

DELIMITER ;

CALL map_users_to_groups();
DROP PROCEDURE IF EXISTS map_users_to_groups;

-- ============================================
-- 9. MAP GROUPS TO ROLES WITH CONTEXT
-- ============================================
-- Distribution focused on PROJECT and ENVIRONMENT level:
-- - 10% of groups: Org-level Admin (groups 1-10)
-- - 15% of groups: Project-level Admin (groups 11-25, 3-8 projects each)
-- - 25% of groups: Project-level Deployer (groups 26-50, 3-7 projects each)
-- - 30% of groups: Project-level Developer (groups 51-80, 3-7 projects each)
-- - 10% of groups: Environment-level Developer (groups 81-90, specific non-prod envs)
-- - 5% of groups: Project-level Operator (groups 91-95, 2-5 projects each)
-- - 5% of groups: Project-level Monitor (groups 96-98, 2-4 projects each)
-- - 2% of groups: Org-level User Manager (groups 99-100)

DELIMITER $$

DROP PROCEDURE IF EXISTS map_groups_to_roles$$
CREATE PROCEDURE map_groups_to_roles()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE g_id VARCHAR(36);
    DECLARE group_counter INT DEFAULT 0;
    DECLARE num_projects INT;
    DECLARE num_envs INT;
    DECLARE i INT;
    DECLARE random_project_uuid VARCHAR(36);
    DECLARE random_env_uuid VARCHAR(36);
    DECLARE cur CURSOR FOR SELECT group_id FROM `groups`;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO g_id;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        SET group_counter = group_counter + 1;
        
        -- 10% Org-level Admin (groups 1-10)
        IF group_counter <= 10 THEN
            INSERT INTO group_role_mapping (group_id, role_id, org_uuid, project_uuid, env_uuid, created_at)
            VALUES (g_id, @admin_role_id, @org_uuid, NULL, NULL, NOW());
        
        -- 15% Project-level Admin (groups 11-25)
        ELSEIF group_counter <= 25 THEN
            SET num_projects = FLOOR(3 + (RAND() * 6)); -- 3-8 projects
            SET i = 0;
            WHILE i < num_projects DO
                SELECT project_uuid INTO random_project_uuid 
                FROM projects 
                ORDER BY RAND() 
                LIMIT 1;
                
                INSERT IGNORE INTO group_role_mapping (group_id, role_id, org_uuid, project_uuid, env_uuid, created_at)
                VALUES (g_id, @admin_role_id, @org_uuid, random_project_uuid, NULL, NOW());
                
                SET i = i + 1;
            END WHILE;
        
        -- 25% Project-level Deployer (groups 26-50)
        ELSEIF group_counter <= 50 THEN
            SET num_projects = FLOOR(3 + (RAND() * 5)); -- 3-7 projects
            SET i = 0;
            WHILE i < num_projects DO
                SELECT project_uuid INTO random_project_uuid 
                FROM projects 
                ORDER BY RAND() 
                LIMIT 1;
                
                INSERT IGNORE INTO group_role_mapping (group_id, role_id, org_uuid, project_uuid, env_uuid, created_at)
                VALUES (g_id, @deployer_role_id, @org_uuid, random_project_uuid, NULL, NOW());
                
                SET i = i + 1;
            END WHILE;
        
        -- 30% Project-level Developer (groups 51-80)
        ELSEIF group_counter <= 80 THEN
            SET num_projects = FLOOR(3 + (RAND() * 5)); -- 3-7 projects
            SET i = 0;
            WHILE i < num_projects DO
                SELECT project_uuid INTO random_project_uuid 
                FROM projects 
                ORDER BY RAND() 
                LIMIT 1;
                
                INSERT IGNORE INTO group_role_mapping (group_id, role_id, org_uuid, project_uuid, env_uuid, created_at)
                VALUES (g_id, @developer_role_id, @org_uuid, random_project_uuid, NULL, NOW());
                
                SET i = i + 1;
            END WHILE;
        
        -- 10% Environment-level Developer (groups 81-90, non-prod envs only)
        ELSEIF group_counter <= 90 THEN
            SET num_envs = FLOOR(3 + (RAND() * 5)); -- 3-7 environments
            SET i = 0;
            WHILE i < num_envs DO
                SELECT env_uuid INTO random_env_uuid 
                FROM environments 
                WHERE env_type = 'non-production'
                ORDER BY RAND() 
                LIMIT 1;
                
                INSERT IGNORE INTO group_role_mapping (group_id, role_id, org_uuid, project_uuid, env_uuid, created_at)
                VALUES (g_id, @developer_role_id, @org_uuid, NULL, random_env_uuid, NOW());
                
                SET i = i + 1;
            END WHILE;
        
        -- 5% Project-level Operator (groups 91-95)
        ELSEIF group_counter <= 95 THEN
            SET num_projects = FLOOR(2 + (RAND() * 4)); -- 2-5 projects
            SET i = 0;
            WHILE i < num_projects DO
                SELECT project_uuid INTO random_project_uuid 
                FROM projects 
                ORDER BY RAND() 
                LIMIT 1;
                
                INSERT IGNORE INTO group_role_mapping (group_id, role_id, org_uuid, project_uuid, env_uuid, created_at)
                VALUES (g_id, @operator_role_id, @org_uuid, random_project_uuid, NULL, NOW());
                
                SET i = i + 1;
            END WHILE;
        
        -- 3% Project-level Monitor (groups 96-98)
        ELSEIF group_counter <= 98 THEN
            SET num_projects = FLOOR(2 + (RAND() * 3)); -- 2-4 projects
            SET i = 0;
            WHILE i < num_projects DO
                SELECT project_uuid INTO random_project_uuid 
                FROM projects 
                ORDER BY RAND() 
                LIMIT 1;
                
                INSERT IGNORE INTO group_role_mapping (group_id, role_id, org_uuid, project_uuid, env_uuid, created_at)
                VALUES (g_id, @monitor_role_id, @org_uuid, random_project_uuid, NULL, NOW());
                
                SET i = i + 1;
            END WHILE;
        
        -- 2% Org-level User Manager (groups 99-100)
        ELSE
            INSERT INTO group_role_mapping (group_id, role_id, org_uuid, project_uuid, env_uuid, created_at)
            VALUES (g_id, @user_manager_role_id, @org_uuid, NULL, NULL, NOW());
        END IF;
        
    END LOOP;
    
    CLOSE cur;
END$$

DELIMITER ;

CALL map_groups_to_roles();
DROP PROCEDURE IF EXISTS map_groups_to_roles;

-- ============================================
-- 10. CREATE TEST EDGE CASE USERS
-- ============================================

-- User with NO access
INSERT INTO users (user_uuid, username, display_name, created_at, updated_at)
VALUES (UUID(), 'user_no_access', 'User With No Access', NOW(), NOW());

-- User with access to ALL projects (via org-level admin)
SET @super_user_uuid = UUID();
SET @super_group_id = UUID();
INSERT INTO users (user_uuid, username, display_name, created_at, updated_at)
VALUES (@super_user_uuid, 'super_admin', 'Super Admin User', NOW(), NOW());

INSERT INTO `groups` (group_id, group_name, org_uuid, description, created_at, updated_at)
VALUES (@super_group_id, 'Super-Admin-Group', @org_uuid, 'Super admin group', NOW(), NOW());

INSERT INTO group_user_mapping (group_id, user_uuid, created_at)
VALUES (@super_group_id, @super_user_uuid, NOW());

INSERT INTO group_role_mapping (group_id, role_id, org_uuid, project_uuid, env_uuid, created_at)
VALUES (@super_group_id, @admin_role_id, @org_uuid, NULL, NULL, NOW());

-- User in many groups (15 groups)
SET @multi_group_user_uuid = UUID();
INSERT INTO users (user_uuid, username, display_name, created_at, updated_at)
VALUES (@multi_group_user_uuid, 'multi_group_user', 'User In Many Groups', NOW(), NOW());

INSERT INTO group_user_mapping (group_id, user_uuid, created_at)
SELECT group_id, @multi_group_user_uuid, NOW()
FROM `groups`
LIMIT 15;

-- User with only 1 project access
SET @single_project_user_uuid = UUID();
SET @single_project_group_id = UUID();

SELECT project_uuid INTO @single_project_uuid FROM projects LIMIT 1;

INSERT INTO users (user_uuid, username, display_name, created_at, updated_at)
VALUES (@single_project_user_uuid, 'single_project_user', 'User With Single Project', NOW(), NOW());

INSERT INTO `groups` (group_id, group_name, org_uuid, description, created_at, updated_at)
VALUES (@single_project_group_id, 'Single-Project-Group', @org_uuid, 'Single project group', NOW(), NOW());

INSERT INTO group_user_mapping (group_id, user_uuid, created_at)
VALUES (@single_project_group_id, @single_project_user_uuid, NOW());

INSERT INTO group_role_mapping (group_id, role_id, org_uuid, project_uuid, env_uuid, created_at)
VALUES (@single_project_group_id, @developer_role_id, @org_uuid, @single_project_uuid, NULL, NOW());

-- User with only environment-level access (specific dev environment)
SET @env_only_user_uuid = UUID();
SET @env_only_group_id = UUID();

SELECT env_uuid INTO @env_only_env_uuid FROM environments WHERE env_type = 'non-production' LIMIT 1;

INSERT INTO users (user_uuid, username, display_name, created_at, updated_at)
VALUES (@env_only_user_uuid, 'env_only_user', 'User With Single Environment Access', NOW(), NOW());

INSERT INTO `groups` (group_id, group_name, org_uuid, description, created_at, updated_at)
VALUES (@env_only_group_id, 'Single-Env-Group', @org_uuid, 'Single environment group', NOW(), NOW());

INSERT INTO group_user_mapping (group_id, user_uuid, created_at)
VALUES (@env_only_group_id, @env_only_user_uuid, NOW());

INSERT INTO group_role_mapping (group_id, role_id, org_uuid, project_uuid, env_uuid, created_at)
VALUES (@env_only_group_id, @developer_role_id, @org_uuid, NULL, @env_only_env_uuid, NOW());

-- ============================================
-- 11. VERIFICATION QUERIES
-- ============================================

SELECT '=== DATA GENERATION SUMMARY ===' AS '';

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

SELECT '=== ROLE SUMMARY ===' AS '';
SELECT r.role_name, COUNT(rpm.permission_id) as permission_count
FROM roles r
LEFT JOIN role_permission_mapping rpm ON r.role_id = rpm.role_id
GROUP BY r.role_name
ORDER BY permission_count DESC;

SELECT '=== ENVIRONMENT TYPE DISTRIBUTION ===' AS '';
SELECT env_type, COUNT(*) as count FROM environments GROUP BY env_type;

SELECT '=== GROUP-ROLE MAPPING DISTRIBUTION ===' AS '';
SELECT 
    CASE 
        WHEN project_uuid IS NULL AND env_uuid IS NULL THEN 'Org-level'
        WHEN env_uuid IS NULL THEN 'Project-level'
        ELSE 'Environment-level'
    END AS scope_level,
    r.role_name,
    COUNT(*) as count
FROM group_role_mapping grm
INNER JOIN roles r ON grm.role_id = r.role_id
GROUP BY scope_level, r.role_name
ORDER BY scope_level, r.role_name;

SELECT '=== SAMPLE USER ACCESS ===' AS '';
SELECT 
    u.username,
    COUNT(DISTINCT vupa.project_uuid) as accessible_projects,
    COUNT(DISTINCT vuea.env_uuid) as accessible_environments
FROM users u
LEFT JOIN v_user_project_access vupa ON u.user_uuid = vupa.user_uuid
LEFT JOIN v_user_environment_access vuea ON u.user_uuid = vuea.user_uuid
WHERE u.username IN ('user0001', 'super_admin', 'user_no_access', 'single_project_user', 'env_only_user')
GROUP BY u.username;

SELECT '=== DATA GENERATION COMPLETE ===' AS '';