#!/bin/bash
# | ef7810d8-c457-11f0-9fcf-c0a705219895 | env_only_user       | User With Single Environment Access |
# | ef77cb14-c457-11f0-9fcf-c0a705219895 | multi_group_user    | User In Many Groups                 |
# | ef77e4c8-c457-11f0-9fcf-c0a705219895 | single_project_user | User With Single Project            |
# | ef77a058-c457-11f0-9fcf-c0a705219895 | super_admin         | Super Admin User                    |
# | ef7792d4-c457-11f0-9fcf-c0a705219895 | user_no_access      | User With No Access                 |
# | eedfad02-c457-11f0-9fcf-c0a705219895 | user0001            | Test User 1                         |

# 1. Test super_admin (should see ALL 500 projects)
curl http://localhost:9090/api/v1/users/ef77a058-c457-11f0-9fcf-c0a705219895/projects

# 2. Test user_no_access (should see 0 projects)
curl http://localhost:9090/api/v1/users/ef7792d4-c457-11f0-9fcf-c0a705219895/projects

# 3. Test single_project_user (should see exactly 1 project)
curl http://localhost:9090/api/v1/users/ef77e4c8-c457-11f0-9fcf-c0a705219895/projects

# 4. Test regular user (should see some projects)
curl http://localhost:9090/api/v1/users/eedfad02-c457-11f0-9fcf-c0a705219895/projects

# 5. Test environments for a user
curl http://localhost:9090/api/v1/users/eedfad02-c457-11f0-9fcf-c0a705219895/environments

# 6. Test environment filtering by project
curl "http://localhost:9090/api/v1/users/eedfad02-c457-11f0-9fcf-c0a705219895/environments?project_id=eefa6fe8-c457-11f0-9fcf-c0a705219895"

# 7. Test project access check (should return true)
curl http://localhost:9090/api/v1/users/ef77a058-c457-11f0-9fcf-c0a705219895/check/project/eefa6fe8-c457-11f0-9fcf-c0a705219895

# 8. Test project access check (should return false)
curl http://localhost:9090/api/v1/users/ef7792d4-c457-11f0-9fcf-c0a705219895/check/project/eefa6fe8-c457-11f0-9fcf-c0a705219895

# 9. Test environment access check
curl http://localhost:9090/api/v1/users/ef7810d8-c457-11f0-9fcf-c0a705219895/environments
curl http://localhost:9090/api/v1/users/ef7810d8-c457-11f0-9fcf-c0a705219895/check/environment/ef02a582-c457-11f0-9fcf-c0a705219895
