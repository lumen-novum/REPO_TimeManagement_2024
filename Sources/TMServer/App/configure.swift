/*
VaporShell provides a minimal framework for starting Vapor projects.
Copyright (C) 2021, 2022 CoderMerlin.com
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import Vapor

// UNCOMMENT-DATABASE to configure database example
import Fluent
import FluentMySQLDriver
import Leaf

// Vapor Storage and StorageKey structs
struct VStorage {
    var databaseActive: Bool
}

struct VStorageKey: StorageKey {
    typealias Value = VStorage
}

extension Application {
    var vaporStorage: VStorage? {
        get {
            self.storage[VStorageKey.self]
        }
        set {
            self.storage[VStorageKey.self] = newValue
        }
    }
}

// configures your application
func configure(_ app: Application) throws {
    // UNCOMMENT-PUBLIC to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.views.use(.leaf)
    
    guard let dbName = Environment.get("DB_NAME") else {
        fatalError("Unable to find the server credentials! Are you sure you ran the script from 'server-run.sh'?")
    }
    var dbUsername: String? = nil
    var dbPassword: String? = nil

    let dbActive = dbName != "FRONT-END"
    app.vaporStorage = .init(databaseActive: dbActive)
    if !dbActive {
        app.logger.notice("Time Management is running without database access! No changes will be saved!")
        
    } else {
        guard let username = Environment.get("DB_USERNAME") else {
        fatalError("Unable to find the server credentials! Are you sure you ran the script from 'server-run.sh'?")
        }
        guard let password = Environment.get("DB_PASSWORD") else {
        fatalError("Unable to find the server credentials! Are you sure you ran the script from 'server-run.sh'?")
        }
        dbUsername = username
        dbPassword = password
    }
    
    var tls = TLSConfiguration.makeClientConfiguration()
    tls.certificateVerification = .none
    if dbName != "FRONT-END" {
        app.databases.use(.mysql(
                            hostname: "db",
                            port: MySQLConfiguration.ianaPortNumber,
                            username: dbUsername!,
                            password: dbPassword!,
                            database: dbName,
                            tlsConfiguration: tls
                          ), as: .mysql)
    }

    // Set local port
    guard let portString = Environment.get("VAPOR_LOCAL_PORT"),
          let port = Int(portString) else {
        fatalError("Failed to determine VAPOR LOCAL PORT from environment")
    }
    app.http.server.configuration.port = port

    // Set local host
    guard let hostname = Environment.get("VAPOR_LOCAL_HOST") else {
        fatalError("Failed to determine VAPOR LOCAL HOST from environment")
    }
    app.http.server.configuration.hostname = hostname

    // register routes
    try routes(app)
}
