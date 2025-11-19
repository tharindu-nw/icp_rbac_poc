# RBAC PoC for WSO2 Integration Control Plane

## Overview

This repository contains a Proof of Concept (PoC) implementation of Role-Based Access Control (RBAC) for the WSO2 Integration Control Plane (ICP). The goal is to evaluate an SQL-based RBAC system as an alternative to SpiceDB, focusing on **project-level** and **environment-level** permissions with support for both **MySQL** (production) and **H2** (development/testing).

## Objectives

1. Design and implement an SQL schema for RBAC with contextual scoping
2. Create realistic test data (1K users, 500 projects, 1K environments, 100+ roles)
3. Implement a Ballerina REST API for authorization queries
4. Establish baseline performance metrics for both MySQL and H2
5. Validate scalability with custom role growth

## Architecture

### RBAC Model

- **Users** belong to **Groups**
- **Groups** are assigned **Roles** with **Context** (org/project/environment scope)
- **Roles** contain **Permissions** grouped by domain
- Context determines scope of access:
  - org_uuid set → Access all projects/environments in organization
  - project_uuid set → Access all environments in project
  - env_uuid set → Access specific environment only

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
- organizations - Organization entities
- users - User accounts
- groups - User groups within orgs
- roles - Role definitions (predefined + custom)
- permissions - Permission definitions (26 total)
- projects - Project entities
- environments - Environment entities (prod/non-prod)

### Mapping Tables
- group_user_mapping - Users ↔ Groups (many-to-many)
- group_role_mapping - Groups ↔ Roles with context (org/project/env scope)
- role_permission_mapping - Roles ↔ Permissions (many-to-many)

### Views
- v_user_project_access - User's accessible projects (handles org + project level access)
- v_user_environment_access - User's accessible environments (handles org + project + env level access)

## Test Data

### Scale
- **1 Organization**
- **1,004 Users** (1,000 regular + 4 edge cases)
- **103 Groups** (100 regular + 3 special)
- **107 Roles** (7 predefined + 100 custom roles)
- **26 Permissions** (across 5 domains)
- **500 Projects**
- **1,000 Environments** (2 per project: dev + prod)
- **~2,100 Group-User Mappings** (avg 2-3 groups per user)
- **~800 Group-Role Mappings** (includes custom role assignments)
- **~146 Role-Permission Mappings**

### Distribution
- Users per group: 1-5 (avg ~3)
- Group-role mappings:
  - 10% Org-level Admin (access all 500 projects)
  - 15% Project-level Admin (5 projects each)
  - 25% Project-level Deployer (5 projects each)
  - 30% Project-level Developer (5 projects each)
  - 10% Environment-level Developer (5 non-prod envs each)
  - 5% Project-level Operator (3 projects each)
  - 3% Project-level Monitor (3 projects each)
  - 2% Org-level User Manager

### Edge Case Users
- super_admin - Org-level admin (sees all 500 projects)
- user_no_access - No permissions
- single_project_user - Access to exactly 1 project
- env_only_user - Access to single environment only
- multi_group_user - Member of 15 groups

## API Endpoints

### Implemented Endpoints

```
GET /api/v1/health
GET /api/v1/users/{userId}/projects
GET /api/v1/users/{userId}/environments?project_id={projectId}
GET /api/v1/users/{userId}/check/project/{projectId}
GET /api/v1/users/{userId}/check/environment/{envId}
```

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

## Performance Results

### Test Configuration
- **Test Runs:** 10 iterations per query
- **Connection Pool:** 10 max connections, 5 min idle
- **Data Scale:** 107 roles, ~800 group-role mappings, 500 projects, 1,000 environments

### MySQL 8.0 Performance (Networked, Localhost)

| Operation | User Type | Avg (ms) | Min (ms) | Max (ms) | Records |
|-----------|-----------|----------|----------|----------|---------|
| **List Projects** | Super Admin | 22.31 | 14.40 | 72.84 | 500 |
| **List Projects** | Regular User | 2.72 | 1.92 | 3.84 | 14 |
| **List Projects** | Single Project | 1.74 | 1.41 | 2.40 | 1 |
| **List Environments** | Regular User (all) | 4.76 | 3.40 | 9.61 | 45 |
| **List Environments** | Regular User (filtered) | 3.43 | 2.78 | 4.03 | 1 |
| **Project Access Check** | Regular User | 1.63 | 1.18 | 2.59 | - |
| **Environment Access Check** | Regular User | 2.41 | 1.55 | 3.94 | - |

### H2 2.x Performance (Embedded, MySQL Mode)

| Operation | User Type | Avg (ms) | Min (ms) | Max (ms) | Records |
|-----------|-----------|----------|----------|----------|---------|
| **List Projects** | Super Admin | 11.74 | 5.69 | 67.74 | 500 |
| **List Projects** | Regular User | 1.26 | 0.77 | 3.69 | 17 |
| **List Projects** | Single Project | 0.65 | 0.46 | 1.17 | 1 |
| **List Environments** | Regular User (all) | 3.33 | 0.71 | 25.71 | 34 |
| **List Environments** | Regular User (filtered) | 1.21 | 0.45 | 5.08 | 2 |
| **Project Access Check** | Regular User | 0.46 | 0.20 | 1.92 | - |
| **Environment Access Check** | Regular User | 0.48 | 0.20 | 1.62 | - |

## Project Structure

```
icp_rbac_poc/
├── Ballerina.toml              # Project configuration
├── Config.toml                 # Database and service config
├── service.bal                 # REST API endpoints
├── modules/
│   └── storage/
│       ├── types.bal           # Data models and DTOs
│       ├── connection.bal      # Database connection manager (MySQL/H2)
│       ├── repository.bal      # Database queries
│       └── storage.bal         # Module exports
├── db_scripts/
│   ├── schema.sql              # MySQL schema with views
│   ├── seed_data.sql           # MySQL test data generation
│   ├── schema_h2.sql           # H2 schema (MySQL compatibility mode)
│   ├── seed_data_h2.sql        # H2 test data generation
│   └── add_custom_roles_mysql.sql  # Add 100 custom roles to MySQL
└── perf_scripts/
    ├── test_performance.sh     # Performance testing script
    └── explain_analyze.sh      # Query analysis script
```

## Setup Instructions

### Option 1: MySQL Setup

**1. Create Database**

```bash
mysql -u root -p < db_scripts/schema.sql
mysql -u root -p < db_scripts/seed_data.sql
```

**2. Configure Application**

Update Config.toml:

```toml
servicePort = 9090

[icp_rbac_poc.storage]
dbType = "mysql"
host = "localhost"
port = 3306
name = "icp_rbac_poc"
username = "root"
password = "your_password"
maxOpenConnections = 10
maxConnectionLifeTime = 1800
minIdleConnections = 5
```

### Option 2: H2 Setup (Development)

**1. Initialize Database**

```bash
# Build project first to get H2 driver
bal build

# Initialize H2 database
H2_JAR=$(find ~/.ballerina/repositories/central.ballerina.io/bala/ballerinax/h2.driver -name "h2-*.jar" | head -1)

java -cp "$H2_JAR" org.h2.tools.RunScript \
  -url "jdbc:h2:./data/icp_rbac_poc;MODE=MySQL" \
  -user sa \
  -script db_scripts/schema_h2.sql

java -cp "$H2_JAR" org.h2.tools.RunScript \
  -url "jdbc:h2:./data/icp_rbac_poc;MODE=MySQL" \
  -user sa \
  -script db_scripts/seed_data_h2.sql
```

**2. Configure Application**

Update Config.toml:

```toml
servicePort = 9090

[icp_rbac_poc.storage]
dbType = "h2"
h2JdbcUrl = "jdbc:h2:./data/icp_rbac_poc;MODE=MySQL;AUTO_SERVER=TRUE;DB_CLOSE_DELAY=-1"
h2Username = "sa"
h2Password = ""
maxOpenConnections = 10
maxConnectionLifeTime = 1800
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

### Adding Custom Roles (Scalability Test)

To test with 100+ custom roles:

```bash
# MySQL
mysql -u root -p icp_rbac_poc < db_scripts/add_custom_roles_mysql.sql

# H2 - custom roles already included in seed_data_h2.sql
```
