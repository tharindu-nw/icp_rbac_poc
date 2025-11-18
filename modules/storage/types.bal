// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.

// Record types for database entities

public type User record {|
    string user_uuid;
    string username;
    string display_name;
    string created_at?;
    string updated_at?;
|};

public type Project record {|
    string project_uuid;
    string project_name;
    string org_uuid;
    string description?;
    string created_at?;
    string updated_at?;
|};

public type Environment record {|
    string env_uuid;
    string env_name;
    string env_type; // 'production' or 'non-production'
    string project_uuid;
    string description?;
    string created_at?;
    string updated_at?;
|};

public type Role record {|
    string role_id;
    string role_name;
    string description?;
|};

public type Permission record {|
    string permission_id;
    string permission_name;
    string permission_domain;
    string resource_type;
    string action;
    string description?;
|};

// Extended types with additional context for responses

public type ProjectWithAccess record {|
    *Project;
    string access_level; // 'org' or 'project'
    string role_id;
|};

public type EnvironmentWithAccess record {|
    *Environment;
    string project_name;
    string org_uuid;
    string access_level; // 'org', 'project', or 'environment'
    string role_id;
|};

// API Response types

public type ProjectListResponse record {|
    Project[] projects;
    int count;
    decimal query_time_ms;
|};

public type EnvironmentListResponse record {|
    Environment[] environments;
    int count;
    decimal query_time_ms;
|};

public type AccessCheckResponse record {|
    boolean has_access;
    string? access_level;
    decimal query_time_ms;
|};

public type ErrorResponse record {|
    string message;
    string 'error;
|};

