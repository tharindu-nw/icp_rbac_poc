// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.

import ballerina/log;
import ballerina/sql;
import ballerinax/h2.driver as _;
import ballerinax/java.jdbc;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

// Database type configuration
public enum DatabaseType {
    MYSQL = "mysql",
    H2 = "h2"
}

// Database type (storage module config)
configurable DatabaseType dbType = MYSQL;

// MySQL Configuration (storage module config)
configurable string host = "localhost";
configurable int port = 3306;
configurable string name = "icp_rbac_poc";
configurable string username = "localdbuser";
configurable string password = "admin";

// H2 Configuration (storage module config)
configurable string h2JdbcUrl = "jdbc:h2:./data/icp_rbac_poc;MODE=MySQL;AUTO_SERVER=TRUE;DB_CLOSE_DELAY=-1";
configurable string h2Username = "sa";
configurable string h2Password = "";

// Connection pool configuration (storage module config)
configurable int maxOpenConnections = 10;
configurable int maxConnectionLifeTime = 1800;
configurable int minIdleConnections = 5;

// Database client initialization
isolated function initDbClient() returns sql:Client|error {
    sql:ConnectionPool connectionPool = {
        maxOpenConnections: maxOpenConnections,
        maxConnectionLifeTime: <decimal>maxConnectionLifeTime,
        minIdleConnections: minIdleConnections
    };

    if dbType == MYSQL {
        log:printInfo("Initializing MySQL database connection...");
        
        mysql:Options mysqlOptions = {
            connectTimeout: 10,
            socketTimeout: 10
        };
        
        mysql:Client mysqlClient = check new (
            host = host,
            port = port,
            database = name,
            user = username,
            password = password,
            options = mysqlOptions,
            connectionPool = connectionPool
        );
        
        log:printInfo("MySQL database connection initialized successfully.");
        return mysqlClient;
        
    } else if dbType == H2 {
        log:printInfo("Initializing H2 database connection...");
        
        jdbc:Client h2Client = check new (
            url = h2JdbcUrl,
            user = h2Username,
            password = h2Password,
            connectionPool = connectionPool
        );
        
        log:printInfo("H2 database connection initialized successfully.");
        return h2Client;
        
    } else {
        return error(string `Unsupported database type: ${dbType}`);
    }
}

// Initialize the database client at module initialization
final sql:Client dbClient = check initDbClient();

// Get database client
public isolated function getDbClient() returns sql:Client {
    return dbClient;
}

// Close database connection
public function closeDatabase() returns error? {
    check dbClient.close();
    log:printInfo("Database connection closed.");
}