// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.

import ballerina/http;
import ballerina/log;
import icp_rbac_poc.storage;

configurable int servicePort = 9090;

// HTTP service for RBAC PoC
service /api/v1 on new http:Listener(servicePort) {

    // List all projects accessible by a user
    resource function get users/[string userId]/projects() returns storage:ProjectListResponse|storage:ErrorResponse {
        var [result, queryTime] = storage:measureQueryTime(function() returns storage:ProjectWithAccess[]|error {
            return storage:getUserProjects(userId);
        });

        if result is storage:ProjectWithAccess[] {
            storage:Project[] projects = from var p in result
                select {
                    project_uuid: p.project_uuid,
                    project_name: p.project_name,
                    org_uuid: p.org_uuid,
                    description: p.description
                };

            log:printInfo(string `Retrieved ${projects.length()} projects for user ${userId} in ${queryTime}ms`);

            return {
                projects: projects,
                count: projects.length(),
                query_time_ms: queryTime
            };
        } else if result is error {
            log:printError("Error retrieving projects", 'error = result);
            return {
                message: "Failed to retrieve projects",
                'error: result.message()
            };
        }

        return {
            message: "Unexpected error occurred",
            'error: "Unknown"
        };
    }

    // List all environments accessible by a user (optionally filtered by project)
    resource function get users/[string userId]/environments(string? project_id = ()) 
            returns storage:EnvironmentListResponse|storage:ErrorResponse {
        var [result, queryTime] = storage:measureQueryTime(function() returns storage:EnvironmentWithAccess[]|error {
            return storage:getUserEnvironments(userId, project_id);
        });

        if result is storage:EnvironmentWithAccess[] {
            storage:Environment[] environments = from var e in result
                select {
                    env_uuid: e.env_uuid,
                    env_name: e.env_name,
                    env_type: e.env_type,
                    project_uuid: e.project_uuid,
                    description: e.description
                };
            string? m = project_id;
            string filterMsg = "";
            if m is string {
                filterMsg = string ` for project ${m}`;
            }
            log:printInfo(string `Retrieved ${environments.length()} environments for user ${userId}${filterMsg} in ${queryTime}ms`);

            return {
                environments: environments,
                count: environments.length(),
                query_time_ms: queryTime
            };
        } else if result is error {
            log:printError("Error retrieving environments", 'error = result);
            return {
                message: "Failed to retrieve environments",
                'error: result.message()
            };
        }

        return {
            message: "Unexpected error occurred",
            'error: "Unknown"
        };
    }

    // Check if user has access to a specific project
    resource function get users/[string userId]/'check/project/[string projectId]() 
            returns storage:AccessCheckResponse|storage:ErrorResponse {
        var [result, queryTime] = storage:measureQueryTime(function() returns boolean|error {
            return storage:checkProjectAccess(userId, projectId);
        });

        if result is boolean {
            log:printInfo(string `Access check for user ${userId} to project ${projectId}: ${result} (${queryTime}ms)`);

            return {
                has_access: result,
                access_level: result ? "project" : (),
                query_time_ms: queryTime
            };
        } else if result is error {
            log:printError("Error checking project access", 'error = result);
            return {
                message: "Failed to check project access",
                'error: result.message()
            };
        }

        return {
            message: "Unexpected error occurred",
            'error: "Unknown"
        };
    }

    // Check if user has access to a specific environment
    resource function get users/[string userId]/'check/environment/[string envId]() 
            returns storage:AccessCheckResponse|storage:ErrorResponse {
        var [result, queryTime] = storage:measureQueryTime(function() returns boolean|error {
            return storage:checkEnvironmentAccess(userId, envId);
        });

        if result is boolean {
            log:printInfo(string `Access check for user ${userId} to environment ${envId}: ${result} (${queryTime}ms)`);

            return {
                has_access: result,
                access_level: result ? "environment" : (),
                query_time_ms: queryTime
            };
        } else if result is error {
            log:printError("Error checking environment access", 'error = result);
            return {
                message: "Failed to check environment access",
                'error: result.message()
            };
        }

        return {
            message: "Unexpected error occurred",
            'error: "Unknown"
        };
    }

    // Health check endpoint
    resource function get health() returns string {
        return "RBAC PoC Service is running";
    }
}
