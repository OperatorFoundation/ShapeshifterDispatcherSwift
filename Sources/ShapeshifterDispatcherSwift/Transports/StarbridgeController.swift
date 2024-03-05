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
        guard let starbridgeConfig = StarbridgeServerConfig(withConfigAtPath: configPath) else
        {
            appLog.error("Failed to launch a Starbridge Server, we were unable to parse the config at the provided path.")
            return
        }
                        
        let starbridge = AsyncStarbridge(logger: appLog)
        let starbridgeListener = try starbridge.listen(config: starbridgeConfig)
        let routingController = AsyncRoutingController()
               
        print("Starbridge server is now listening at \(starbridgeConfig.serverIP) on port \(starbridgeConfig.serverPort)...")
        
        routingController.handleListener(listener: starbridgeListener, targetHost: targetHost, targetPort: targetPort)
    }
}
