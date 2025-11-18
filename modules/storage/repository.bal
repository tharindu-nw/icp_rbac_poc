// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.

import ballerina/sql;
import ballerina/time;

// Get all projects accessible by a user
public function getUserProjects(string userUuid) returns ProjectWithAccess[]|error {
    sql:ParameterizedQuery query = `
        SELECT DISTINCT
            p.project_uuid,
            p.project_name,
            p.org_uuid,
            p.description,
            vupa.access_level,
            vupa.role_id
        FROM v_user_project_access vupa
        INNER JOIN projects p ON vupa.project_uuid = p.project_uuid
        WHERE vupa.user_uuid = ${userUuid}
        ORDER BY p.project_name
    `;

    sql:Client dbClient = check getDbClient();
    stream<ProjectWithAccess, sql:Error?> resultStream = dbClient->query(query);
    
    ProjectWithAccess[] projects = check from ProjectWithAccess project in resultStream
        select project;
    
    check resultStream.close();
    return projects;
}

// Get all environments accessible by a user (optionally filtered by project)
public function getUserEnvironments(string userUuid, string? projectUuid = ()) returns EnvironmentWithAccess[]|error {
    sql:ParameterizedQuery query;
    
    if projectUuid is string {
        query = `
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
            WHERE vuea.user_uuid = ${userUuid}
              AND e.project_uuid = ${projectUuid}
            ORDER BY e.env_name
        `;
    } else {
        query = `
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
            WHERE vuea.user_uuid = ${userUuid}
            ORDER BY vuea.project_name, e.env_name
        `;
    }

    sql:Client dbClient = check getDbClient();
    stream<EnvironmentWithAccess, sql:Error?> resultStream = dbClient->query(query);
    
    EnvironmentWithAccess[] environments = check from EnvironmentWithAccess env in resultStream
        select env;
    
    check resultStream.close();
    return environments;
}

// Check if user has access to a specific project
public function checkProjectAccess(string userUuid, string projectUuid) returns boolean|error {
    sql:ParameterizedQuery query = `
        SELECT COUNT(*) as count
        FROM v_user_project_access
        WHERE user_uuid = ${userUuid}
          AND project_uuid = ${projectUuid}
    `;

    sql:Client dbClient = check getDbClient();
    int count = check dbClient->queryRow(query);
    
    return count > 0;
}

// Check if user has access to a specific environment
public function checkEnvironmentAccess(string userUuid, string envUuid) returns boolean|error {
    sql:ParameterizedQuery query = `
        SELECT COUNT(*) as count
        FROM v_user_environment_access
        WHERE user_uuid = ${userUuid}
          AND env_uuid = ${envUuid}
    `;

    sql:Client dbClient = check getDbClient();
    int count = check dbClient->queryRow(query);
    
    return count > 0;
}

// Helper function to measure query execution time
public function measureQueryTime(function () returns any|error queryFn) returns [any|error, decimal] {
    time:Utc startTime = time:utcNow();
    any|error result = queryFn();
    time:Utc endTime = time:utcNow();
    
    // Calculate duration in milliseconds
    // time:Utc is [int, decimal] where [0] is seconds and [1] is fraction of second (0-1)
    decimal durationMs = (<decimal>(endTime[0] - startTime[0]) * 1000.0) + 
                         (<decimal>(endTime[1] - startTime[1]) * 1000.0);
    
    // Round to 2 decimal places to avoid scientific notation
    decimal roundedDuration = (<decimal>(<int>(durationMs * 100.0d))) / 100.0;
    
    return [result, roundedDuration];
}
