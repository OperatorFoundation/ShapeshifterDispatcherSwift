//
//  StarbridgeController.swift
//  ShapeshifterDispatcherSwift
//
//  Created by Joshua on 7/29/22.
//

import Foundation
import Logging
import Crypto

import ReplicantSwift
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
        let starbridgeConfig = try StarbridgeServerConfig(path: configPath)
        let starbridge = Starbridge(logger: appLog)
        let starbridgeListener = try starbridge.listen(config: starbridgeConfig)
        let routingController = AsyncRoutingController()
               
        print("Starbridge server is now listening at \(starbridgeConfig.serverIP) on port \(starbridgeConfig.serverPort)...")
        
        routingController.handleListener(listener: starbridgeListener, targetHost: targetHost, targetPort: targetPort)
    }
}
