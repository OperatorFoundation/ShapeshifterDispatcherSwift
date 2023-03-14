//
//  ShadowController.swift
//  ShapeshifterDispatcherSwift
//
//  Created by Mafalda on 3/2/22.
//

import Foundation
import Logging
import Crypto

import ShadowSwift

struct ShadowController
{
    var configPath: String
    
    var targetHost: String
    var targetPort: Int
    
    var bindHost: String
    var bindPort: Int
    
    func runServer() throws
    {
        guard let shadowConfig = ShadowConfig.ShadowServerConfig(path: configPath) else
        {
            appLog.error("Failed to launch a ShadowServer, we were unable to parse the config at the provided path.")
            return
        }
        
        print(shadowConfig.mode)
        print(shadowConfig.serverAddress)
        
        let serverPersistentPrivateKey = shadowConfig.serverPrivateKey 
        
        guard let shadowListener = ShadowServer(host: bindHost, port: bindPort, config: shadowConfig, logger: appLog) else
        {
            appLog.error("Shapeshifter Failed to initialize a ShadowServer with the config provided.")
            return
        }
        
        let routingController = RoutingController()
        
        print("Listening...")
        
        routingController.handleListener(listener: shadowListener, targetHost: targetHost, targetPort: targetPort)
    }
}
