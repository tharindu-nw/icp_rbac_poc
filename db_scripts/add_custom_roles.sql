-- ============================================
-- Add Custom Roles to MySQL Database
-- Matches H2 test scenario
-- ============================================

USE icp_rbac_poc;

-- Get the org_uuid
SET @org_uuid = (SELECT org_uuid FROM organizations LIMIT 1);

-- Check current state
SELECT 'Before Adding Custom Roles' as status;
SELECT 'Roles' as metric, COUNT(*) as count FROM roles
UNION ALL
SELECT 'Group-Role Mappings', COUNT(*) FROM group_role_mapping;

-- Add 100 custom roles
INSERT INTO roles (role_id, role_name, description, created_at, updated_at)
SELECT 
    UUID(),
    CONCAT('Custom-Role-', n),
    'Custom role for testing',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM (
    SELECT a.N + b.N * 10 + 1 AS n
    FROM 
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
         UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
         UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b
    WHERE a.N + b.N * 10 + 1 <= 100
) numbers;

-- Create temporary table for easier assignments
CREATE TEMPORARY TABLE temp_custom_roles AS
SELECT role_id, role_name FROM roles WHERE role_name LIKE 'Custom-Role-%';

CREATE TEMPORARY TABLE temp_groups_subset AS
SELECT group_id FROM `groups` 
WHERE group_name REGEXP '^Team-[0-9]+$' 
  AND CAST(SUBSTRING(group_name, 6) AS UNSIGNED) BETWEEN 11 AND 60;

CREATE TEMPORARY TABLE temp_projects_subset AS
SELECT project_uuid FROM projects 
WHERE CAST(SUBSTRING(project_name, 9) AS UNSIGNED) <= 150
LIMIT 150;

-- Add group-role-project mappings
-- 50 groups × 2 custom roles × 3 projects = 300 new mappings
INSERT INTO group_role_mapping (group_id, role_id, org_uuid, project_uuid, env_uuid, created_at)
SELECT 
    tgs.group_id,
    tcr.role_id,
    @org_uuid,
    tps.project_uuid,
    NULL,
    CURRENT_TIMESTAMP
FROM temp_groups_subset tgs
CROSS JOIN (
    SELECT role_id FROM temp_custom_roles ORDER BY RAND() LIMIT 2
) tcr
CROSS JOIN (
    SELECT project_uuid FROM temp_projects_subset ORDER BY RAND() LIMIT 3
) tps;

-- Check new state
SELECT 'After Adding Custom Roles' as status;
SELECT 'Roles' as metric, COUNT(*) as count FROM roles
UNION ALL
SELECT 'Group-Role Mappings', COUNT(*) FROM group_role_mapping
UNION ALL
SELECT 'Custom Role Mappings', COUNT(*) 
FROM group_role_mapping grm 
INNER JOIN roles r ON grm.role_id = r.role_id 
WHERE r.role_name LIKE 'Custom-Role-%';

-- Sample the new data
SELECT 
    g.group_name,
    r.role_name,
    p.project_name,
    'project' as scope
FROM group_role_mapping grm
INNER JOIN `groups` g ON grm.group_id = g.group_id
INNER JOIN roles r ON grm.role_id = r.role_id
INNER JOIN projects p ON grm.project_uuid = p.project_uuid
WHERE r.role_name LIKE 'Custom-Role-%'
LIMIT 10;

-- Cleanup temporary tables
DROP TEMPORARY TABLE IF EXISTS temp_custom_roles;
DROP TEMPORARY TABLE IF EXISTS temp_groups_subset;
DROP TEMPORARY TABLE IF EXISTS temp_projects_subset;

SELECT '=== Custom roles added successfully ===' as status;
