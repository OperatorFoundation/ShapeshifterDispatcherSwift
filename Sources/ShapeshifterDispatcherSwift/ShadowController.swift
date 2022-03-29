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
        
        print("Created a config from JSON:")
        print(shadowConfig.mode)
        print(shadowConfig.serverIP)
        print(shadowConfig.port)
        
        guard let serverPersistentPrivateKeyData = Data(hex: shadowConfig.password) else
        {
            //.error("ShShD Failed to parse password from config.")
            return
        }
        print("ShShD Parsed a config file and got some key data.")
        
        guard let serverPersistentPrivateKey = try? P256.KeyAgreement.PrivateKey(rawRepresentation: serverPersistentPrivateKeyData) else
        {
            //logger.error("ShShD Failed to generate key from data.")
            return
        }
        print("ShShD Generated a public key from some data \(serverPersistentPrivateKey.publicKey.compactRepresentation!.hex)")
        
        guard let shadowListener = ShadowServer(host: bindHost, port: bindPort, config: shadowConfig, logger: appLog) else
        {
            appLog.error("ShShD Failed to initialize a ShadowServer with the config provided.")
            return
        }
        
        let routingController = RoutingController()
        
        routingController.handleListener(listener: shadowListener, targetHost: targetHost, targetPort: targetPort)
    }
}
