/*
VaporShell provides a minimal framework for starting Igis projects.
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

import Fluent
import FluentMySQLDriver

func routes(_ app: Application) throws {
    let userInfo = ["usernames": ["Not logged in"], "tasks": ["Nothing to do."]]
    let userController = UserController()

    // app.get -> GET request made
    // app.post -> POST request made
    app.post("create-account") { req in 
        let user = try req.content.decode(User.self)
        let username = user.username

        return try userController.createUser(req: req, username: username).map { creationResult in
            if creationResult.success {
                return req.view.render("creation-success", ["user": username, "code": creationResult.info])
            } 
            return req.view.render("failure-page", ["error": creationResult.info])
        }
    }

    app.post("login") { req in
        let user = try req.content.decode(User.self)
        let username = user.username
        
        guard let loginCode = user.loginCode else {
            return req.view.render("failure-page", ["error": "Malformed POST request. If this was not intentional, please contact an administrator."])
        }

        return try userController.login(req: req, username: username, loginCode: loginCode).flatMap { result in
            if result.success {
                var taskArray: [String] = ["Nothing to do."]
                if let userTasks = result.userModel!.tasks {
                    taskArray = userTasks.components(separatedBy: ";")
                }                
                return req.view.render("backend-test", ["usernames": [username], "tasks": taskArray])
            }
            return req.view.render("failure-page", ["error": result.info])
        }
    }
    
    app.get(":page") { req in
        let webpage = req.parameters.get("page")!
        return req.view.render(webpage)
    }
    
    app.get { req in
        return req.view.render("index")
    }
}
