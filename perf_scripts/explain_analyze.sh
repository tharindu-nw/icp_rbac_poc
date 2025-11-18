#!/bin/bash

# Get the actual UUIDs from your database
SUPER_ADMIN_UUID="ef77a058-c457-11f0-9fcf-c0a705219895"
REGULAR_USER_UUID="eedfad02-c457-11f0-9fcf-c0a705219895"
SAMPLE_PROJECT_UUID="eefcd094-c457-11f0-9fcf-c0a705219895"
SAMPLE_ENV_UUID="ef06f10a-c457-11f0-9fcf-c0a705219895"

# Database credentials
DB_USER="localdbuser"
DB_PASS="admin"
DB_NAME="icp_rbac_poc"

OUTPUT_DIR="explain_results"
mkdir -p $OUTPUT_DIR

echo "Running EXPLAIN ANALYZE queries and saving to $OUTPUT_DIR/"
echo "Started at: $(date)"
echo ""

# Query 1: Super Admin - List Projects (worst case)
echo "1. Super Admin - List Projects (500 projects)..."
mysql -u $DB_USER -p$DB_PASS $DB_NAME <<EOF > $OUTPUT_DIR/1_super_admin_list_projects.txt
EXPLAIN ANALYZE
SELECT DISTINCT
    p.project_uuid,
    p.project_name,
    p.org_uuid,
    p.description,
    vupa.access_level,
    vupa.role_id
FROM v_user_project_access vupa
INNER JOIN projects p ON vupa.project_uuid = p.project_uuid
WHERE vupa.user_uuid = '$SUPER_ADMIN_UUID'
ORDER BY p.project_name;
EOF

# Query 2: Regular User - List Projects
echo "2. Regular User - List Projects (8 projects)..."
mysql -u $DB_USER -p$DB_PASS $DB_NAME <<EOF > $OUTPUT_DIR/2_regular_user_list_projects.txt
EXPLAIN ANALYZE
SELECT DISTINCT
    p.project_uuid,
    p.project_name,
    p.org_uuid,
    p.description,
    vupa.access_level,
    vupa.role_id
FROM v_user_project_access vupa
INNER JOIN projects p ON vupa.project_uuid = p.project_uuid
WHERE vupa.user_uuid = '$REGULAR_USER_UUID'
ORDER BY p.project_name;
EOF

# Query 3: Regular User - List All Environments
echo "3. Regular User - List All Environments..."
mysql -u $DB_USER -p$DB_PASS $DB_NAME <<EOF > $OUTPUT_DIR/3_regular_user_list_environments.txt
EXPLAIN ANALYZE
SELECT DISTINCT
    e.env_uuid,
    e.env_name,
    e.env_type,
    e.project_uuid,
    e.description,
    vuea.project_name,
    vuea.org_uuid,
    vuea.access_level,
    vuea.role_id
FROM v_user_environment_access vuea
INNER JOIN environments e ON vuea.env_uuid = e.env_uuid
WHERE vuea.user_uuid = '$REGULAR_USER_UUID'
ORDER BY vuea.project_name, e.env_name;
EOF

# Query 4: Regular User - List Environments Filtered by Project
echo "4. Regular User - List Environments (filtered by project)..."
mysql -u $DB_USER -p$DB_PASS $DB_NAME <<EOF > $OUTPUT_DIR/4_regular_user_list_environments_filtered.txt
EXPLAIN ANALYZE
SELECT DISTINCT
    e.env_uuid,
    e.env_name,
    e.env_type,
    e.project_uuid,
    e.description,
    vuea.project_name,
    vuea.org_uuid,
    vuea.access_level,
    vuea.role_id
FROM v_user_environment_access vuea
INNER JOIN environments e ON vuea.env_uuid = e.env_uuid
WHERE vuea.user_uuid = '$REGULAR_USER_UUID'
  AND e.project_uuid = '$SAMPLE_PROJECT_UUID'
ORDER BY vuea.project_name, e.env_name;
EOF

# Query 5: Project Access Check
echo "5. Project Access Check..."
mysql -u $DB_USER -p$DB_PASS $DB_NAME <<EOF > $OUTPUT_DIR/5_project_access_check.txt
EXPLAIN ANALYZE
SELECT COUNT(*) as count
FROM v_user_project_access
WHERE user_uuid = '$REGULAR_USER_UUID'
  AND project_uuid = '$SAMPLE_PROJECT_UUID';
EOF

# Query 6: Environment Access Check
echo "6. Environment Access Check..."
mysql -u $DB_USER -p$DB_PASS $DB_NAME <<EOF > $OUTPUT_DIR/6_environment_access_check.txt
EXPLAIN ANALYZE
SELECT COUNT(*) as count
FROM v_user_environment_access
WHERE user_uuid = '$REGULAR_USER_UUID'
  AND env_uuid = '$SAMPLE_ENV_UUID';
EOF

# Query 7: View Definition - v_user_project_access
echo "7. Analyzing view: v_user_project_access (Direct access part)..."
mysql -u $DB_USER -p$DB_PASS $DB_NAME <<EOF > $OUTPUT_DIR/7_view_project_direct_access.txt
EXPLAIN ANALYZE
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
  AND gum.user_uuid = '$REGULAR_USER_UUID';
EOF

# Query 8: View Definition - v_user_project_access (Org-level access part)
echo "8. Analyzing view: v_user_project_access (Org-level access part)..."
mysql -u $DB_USER -p$DB_PASS $DB_NAME <<EOF > $OUTPUT_DIR/8_view_project_org_access.txt
EXPLAIN ANALYZE
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
  AND grm.env_uuid IS NULL
  AND gum.user_uuid = '$SUPER_ADMIN_UUID';
EOF

echo ""
echo "Completed at: $(date)"
echo ""
echo "Results saved to $OUTPUT_DIR/"
echo "Files created:"
ls -lh $OUTPUT_DIR/
