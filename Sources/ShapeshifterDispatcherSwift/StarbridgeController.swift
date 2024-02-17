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
                        
        let starbridge = Starbridge(logger: appLog)
        
        guard let starbridgeListener = try? starbridge.listen(config: starbridgeConfig) else
        {
            appLog.error("Failed to create a Starbridge listener.")
            return
        }
               
        print("Starbridge server is now listening at \(starbridgeConfig.serverIP) on port \(starbridgeConfig.serverPort)...")
        
        let routingController = RoutingController()
        routingController.handleListener(listener: starbridgeListener, targetHost: targetHost, targetPort: targetPort)
    }
}
