#!/bin/bash

# a0571544-dba6-4565-b584-4373feccb059	env_only_user	User With Single Environment Access
# dae44963-0a85-4318-af3d-2ee60f259f93	multi_group_user	User In Many Groups
# 4042d876-37ee-4f71-ae11-e1931353aaef	single_project_user	User With Single Project
# 554c4e4c-3a8c-4660-a5c2-bb48a4edcd20	super_admin	Super Admin User
# edf67679-3594-4f2c-ba5f-62791f9ca8dc	user0001	Test User 1
# a6e33f65-4ddc-4fe4-b2ce-ec6dfae777b3	user_no_access	User With No Access

# Get user UUIDs (replace with actual values from your DB)
SUPER_ADMIN_UUID="554c4e4c-3a8c-4660-a5c2-bb48a4edcd20"
REGULAR_USER_UUID="edf67679-3594-4f2c-ba5f-62791f9ca8dc"
SINGLE_PROJECT_UUID="4042d876-37ee-4f71-ae11-e1931353aaef"
MULTI_GROUP_UUID="dae44963-0a85-4318-af3d-2ee60f259f93"

# Get a sample project and environment UUID
PROJECT_UUID="0336d6ae-a417-4740-8758-f31cfc7e98c4"
ENV_UUID="ef500bd8-4104-4ab0-b76d-ce07049c0712"

echo "=== RBAC PoC Performance Test ==="
echo "Started at: $(date)"
echo ""

# Test 1: List projects for different users
echo "Test 1: List Projects"
echo "---------------------"
echo "Super Admin (all projects):"
curl -s http://localhost:9090/api/v1/users/$SUPER_ADMIN_UUID/projects | jq '{count: .count, query_time_ms: .query_time_ms}'
echo ""

echo "Regular User:"
curl -s http://localhost:9090/api/v1/users/$REGULAR_USER_UUID/projects | jq '{count: .count, query_time_ms: .query_time_ms}'
echo ""

echo "Single Project User:"
curl -s http://localhost:9090/api/v1/users/$SINGLE_PROJECT_UUID/projects | jq '{count: .count, query_time_ms: .query_time_ms}'
echo ""

# Test 2: List environments
echo "Test 2: List Environments"
echo "-------------------------"
echo "Regular User (all environments):"
curl -s http://localhost:9090/api/v1/users/$REGULAR_USER_UUID/environments | jq '{count: .count, query_time_ms: .query_time_ms}'
echo ""

echo "Regular User (filtered by project):"
curl -s "http://localhost:9090/api/v1/users/$REGULAR_USER_UUID/environments?project_id=$PROJECT_UUID" | jq '{count: .count, query_time_ms: .query_time_ms}'
echo ""

# Test 3: Permission checks
echo "Test 3: Permission Checks"
echo "-------------------------"
echo "Project access check:"
curl -s http://localhost:9090/api/v1/users/$REGULAR_USER_UUID/check/project/$PROJECT_UUID | jq '{has_access: .has_access, query_time_ms: .query_time_ms}'
echo ""

echo "Environment access check:"
curl -s http://localhost:9090/api/v1/users/$REGULAR_USER_UUID/check/environment/$ENV_UUID | jq '{has_access: .has_access, query_time_ms: .query_time_ms}'
echo ""

echo "Completed at: $(date)"
