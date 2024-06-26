//
//  StarbridgeController.swift
//  ShapeshifterDispatcherSwift
//

import Foundation
import Logging

import Starbridge

struct StarbridgeController
{
    var configPath: String
    
    var targetHost: String
    var targetPort: Int
    
    var bindHost: String
    var bindPort: Int
    
    func runServer() throws
    {
        let serverConfig = try StarbridgeServerConfig(path: configPath)
        let server = Starbridge(logger: appLog)
        let listener = try server.listen(config: serverConfig)
        let routingController = AsyncRoutingController()
               
        print("Starbridge server is now listening at \(serverConfig.serverIP) on port \(serverConfig.serverPort)...")
        
        routingController.handleListener(listener: listener, targetHost: targetHost, targetPort: targetPort)
    }
}
