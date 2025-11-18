# RBAC PoC for WSO2 Integration Control Plane

## Overview

This repository contains a Proof of Concept (PoC) implementation of Role-Based Access Control (RBAC) for the WSO2 Integration Control Plane (ICP). The goal is to evaluate a MySQL-based RBAC system as an alternative to SpiceDB, focusing on **project-level** and **environment-level** permissions.

## Objectives

1. Design and implement a MySQL schema for RBAC with contextual scoping
2. Create realistic test data (1K users, 500 projects, 1K environments)
3. Implement a Ballerina REST API for authorization queries
4. Establish baseline performance metrics
5. Compare performance with SpiceDB (future)
6. Load testing and optimization (Phase 2)

## Architecture

### RBAC Model

- **Users** belong to **Groups**
- **Groups** are assigned **Roles** with **Context** (org/project/environment scope)
- **Roles** contain **Permissions** grouped by domain
- Context determines scope of access:
  - `org_uuid` set → Access all projects/environments in organization
  - `project_uuid` set → Access all environments in project
  - `env_uuid` set → Access specific environment only

### Permission Domains

1. **Component-Management** - Manage and view components
2. **Environment-Management** - Manage prod/non-prod environments
3. **Observability-Management** - View logs (prod/non-prod)
4. **Project-Management** - Manage projects and components
5. **User-Management** - Manage users, groups, roles

### Pre-defined Roles

| Role | Description | Permissions |
|------|-------------|-------------|
| **Admin** | Full control within scope | All 26 permissions |
| **Deployer** | Deploy to all environments | 6 permissions (manage components + envs) |
| **Developer** | Non-prod only | 6 permissions (non-prod access only) |
| **Operator** | Manage environments, view components | 5 permissions |
| **Monitor** | View resources and logs | 4 permissions |
| **Viewer** | Read-only access | 2 permissions |
| **User Manager** | Manage users and groups | 10 permissions |

## Database Schema

### Core Tables
- `organizations` - Organization entities
- `users` - User accounts
- `groups` - User groups within orgs
- `roles` - Role definitions
- `permissions` - Permission definitions (26 total)
- `projects` - Project entities
- `environments` - Environment entities (prod/non-prod)

### Mapping Tables
- `group_user_mapping` - Users ↔ Groups (many-to-many)
- `group_role_mapping` - Groups ↔ Roles with context (org/project/env scope)
- `role_permission_mapping` - Roles ↔ Permissions (many-to-many)

### Views
- `v_user_project_access` - User's accessible projects (handles org + project level access)
- `v_user_environment_access` - User's accessible environments (handles org + project + env level access)

## Test Data

### Scale
- **1 Organization**
- **1,004 Users** (1,000 regular + 4 edge cases)
- **100 Groups**
- **7 Roles** (with permission mappings)
- **26 Permissions** (across 5 domains)
- **500 Projects**
- **1,000 Environments** (2 per project: dev + prod)

### Distribution
- Users per group: 1-5 (avg ~3)
- Group-role mappings:
  - 10% Org-level Admin (access all 500 projects)
  - 15% Project-level Admin (3-8 projects each)
  - 25% Project-level Deployer (3-7 projects each)
  - 30% Project-level Developer (3-7 projects each)
  - 10% Environment-level Developer (specific non-prod envs)
  - 5% Project-level Operator (2-5 projects each)
  - 3% Project-level Monitor (2-4 projects each)
  - 2% Org-level User Manager

### Edge Case Users
- `super_admin` - Org-level admin (sees all 500 projects)
- `user_no_access` - No permissions
- `single_project_user` - Access to exactly 1 project
- `env_only_user` - Access to single environment only
- `multi_group_user` - Member of 15 groups

## API Endpoints

### Implemented Endpoints

    GET /api/v1/health
    GET /api/v1/users/{userId}/projects
    GET /api/v1/users/{userId}/environments?project_id={projectId}
    GET /api/v1/users/{userId}/check/project/{projectId}
    GET /api/v1/users/{userId}/check/environment/{envId}

### Response Format

All responses include query_time_ms for performance tracking.

Example response:

```json
{
    "projects": [...],
    "count": 8,
    "query_time_ms": 2.49
}
```

## Performance Results (Phase 1 Baseline)

### Test Environment
- **Database:** MySQL 8.0
- **Connection Pool:** 10 max connections, 5 min idle
- **Test Runs:** 10 iterations per query

### Average Query Times

| Operation | User Type | Avg (ms) | Min (ms) | Max (ms) | Records |
|-----------|-----------|----------|----------|----------|---------|
| List Projects | Super Admin | 32.13 | 18.32 | 71.77 | 500 |
| List Projects | Regular User | 2.49 | 1.90 | 4.10 | 8 |
| List Projects | Single Project | 2.20 | 1.62 | 3.15 | 1 |
| List Environments | Regular User (all) | 6.50 | 4.34 | 7.99 | 33 |
| List Environments | Regular User (filtered) | 4.90 | 2.78 | 5.91 | 1 |
| Project Access Check | Regular User | 2.49 | 1.36 | 4.74 | - |
| Environment Access Check | Regular User | 4.35 | 2.34 | 16.25 | - |

### Query Analysis (EXPLAIN ANALYZE)

**Super Admin Query Breakdown (21.3ms total):**
- Union materialization: 12.5ms
- Hash join (org-level access): 4.4ms
- Table scan (500 projects): 2.55ms
- Final sorting and deduplication: 4.3ms

**Regular User Query Breakdown (1.58ms total):**
- Index lookups on user/group mappings: 0.05ms
- Project filtering: 1.42ms
- Final processing: 0.11ms

**Optimization Opportunities Identified:**
1. Materialized views for user-project access (would reduce 32ms to ~5ms)
2. Caching for org-level admins
3. Query splitting to avoid UNION overhead

## Project Structure

    rbac-poc/
    ├── Ballerina.toml           # Project configuration
    ├── Config.toml              # Database and service config
    ├── service.bal              # REST API endpoints
    ├── modules/
    │   └── storage/
    │       ├── types.bal        # Data models and DTOs
    │       ├── connection.bal   # MySQL connection management
    │       └── repository.bal   # Database queries
    ├── database/
    │   ├── schema.sql           # Database schema with views
    │   └── seed_data.sql        # Test data generation
    └── tests/
        ├── test_performance.sh  # Performance testing script
        └── explain_analyze.sh   # Query analysis script

## Setup Instructions

### 1. Create Database
```bash
mysql -u root -p < database/schema.sql
mysql -u root -p < database/seed_data.sql
```

### 2. Configure Application

Update Config.toml with your database credentials:

```toml
servicePort = 9090

[icp_rbac_poc.storage]
host = "localhost"
port = 3306
name = "icp_rbac_poc"
username = "root"
password = "your_password"
maxOpenConnections = 10
maxConnectionLifeTime = 1800  # 30 minutes in seconds
minIdleConnections = 5
```

### 3. Run Service

```bash
bal run
```

### 4. Test Endpoints

```bash
# Health check
curl http://localhost:9090/api/v1/health

# List projects for a user
curl http://localhost:9090/api/v1/users/{user_uuid}/projects

# Check project access
curl http://localhost:9090/api/v1/users/{user_uuid}/check/project/{project_uuid}
```

## Performance Testing

### Run Performance Tests

```bash
# Update script with actual UUIDs from your database
./perf_scripts/test_performance.sh

# Run 10 iterations
for i in {1..10}; do
    echo "=== Run $i ==="
    ./perf_scripts/test_performance.sh
    sleep 1
done
```

### Analyze Query Plans

```bash
# Update script with actual UUIDs
./perf_scripts/explain_analyze.sh

# View results
ls -lh explain_results/
cat explain_results/1_super_admin_list_projects.txt
```


## References

- MySQL EXPLAIN ANALYZE Documentation: https://dev.mysql.com/doc/refman/8.0/en/explain.html
- Ballerina MySQL Connector: https://central.ballerina.io/ballerinax/mysql/latest
- WSO2 Integration Control Plane: https://github.com/wso2/integration-control-plane

## License

Copyright (c) 2025, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
