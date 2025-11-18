#!/bin/bash

# Get user UUIDs (replace with actual values from your DB)
SUPER_ADMIN_UUID="ef77a058-c457-11f0-9fcf-c0a705219895"
REGULAR_USER_UUID="eedfad02-c457-11f0-9fcf-c0a705219895"
SINGLE_PROJECT_UUID="ef77e4c8-c457-11f0-9fcf-c0a705219895"
MULTI_GROUP_UUID="ef77cb14-c457-11f0-9fcf-c0a705219895"

# Get a sample project and environment UUID
PROJECT_UUID="eefcd094-c457-11f0-9fcf-c0a705219895"
ENV_UUID="ef06f10a-c457-11f0-9fcf-c0a705219895"

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
