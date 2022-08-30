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
        guard let shadowConfig = ShadowConfig(path: configPath) else
        {
            appLog.error("Failed to launch a ShadowServer, we were unable to parse the config at the provided path.")
            return
        }
        
        print(shadowConfig.mode)
        print(shadowConfig.serverIP)
        print(shadowConfig.port)
        
        guard let serverPersistentPrivateKeyData = Data(hex: shadowConfig.password) else
        {
            appLog.error("ShapeshifterDispatcher Failed to parse password from config.")
            return
        }
        
        guard let serverPersistentPrivateKey = try? P256.KeyAgreement.PrivateKey(rawRepresentation: serverPersistentPrivateKeyData) else
        {
            appLog.error("ShapeshifterDispatcher Failed to generate key from data.")
            return
        }
        
        print("Server public key: \(serverPersistentPrivateKey.publicKey.compactRepresentation?.hex ?? "Failed to get a compact representation of the public key.")")
        
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
