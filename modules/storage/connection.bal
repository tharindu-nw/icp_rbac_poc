// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.

import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

// Database configuration
configurable string host = "localhost";
configurable int port = 3306;
configurable string name = "icp_rbac_poc";
configurable string username = "root";
configurable string password = "password";

// Connection pool configuration
configurable int maxOpenConnections = 10;
configurable int maxConnectionLifeTime = 1800;
configurable int minIdleConnections = 5;

final mysql:Options mysqlOptions = {
    connectTimeout: 10,
    socketTimeout: 10
};

final sql:ConnectionPool connectionPool = {
    maxOpenConnections: maxOpenConnections,
    maxConnectionLifeTime: <decimal>maxConnectionLifeTime,
    minIdleConnections: minIdleConnections
};

mysql:Client dbClient = check new (
    host = host,
    port = port,
    database = name,
    user = username,
    password = password,
    options = mysqlOptions,
    connectionPool = connectionPool
);

// Get database client
public function getDbClient() returns mysql:Client|error {
    return dbClient;
}

// Close database connection
public function closeDatabase() returns error? {
    if dbClient is mysql:Client {
        check dbClient.close();
    }
}
