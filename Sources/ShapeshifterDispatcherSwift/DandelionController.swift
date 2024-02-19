//
//  DandelionController.swift
//  
//
//  Created by Mafalda on 9/26/23.
//

import Foundation
import Logging

import Dandelion
import DandelionServer

struct DandelionController
{
    var dandelionLog = Logger(label: "DandelionLogger")
    var configPath: String
    
    var targetHost: String
    var targetPort: Int
    
    var bindHost: String
    var bindPort: Int
    
    func runServer() throws
    {
        guard let serverConfig = DandelionConfig.ServerConfig(path: configPath) else
        {
            throw DandelionError.InvalidConfig(configPath: configPath)
        }
        
        guard serverConfig.serverIP == bindHost && serverConfig.serverPort == bindPort else
        {
            
            throw DandelionError.ConflictingTargetAddress(configHost: serverConfig.serverIP, configPort: Int(serverConfig.serverPort), bindHost: bindHost, bindPort: bindPort)
        }
        
        appLog.debug("Starting a Dandelion server.")
        
        guard let dandelionServer = DandelionServer(config: serverConfig, logger: dandelionLog) else
        {
            return
        }
        
        let routingController = DandelionRoutingController(logger: dandelionLog)
        print("Listening on port \(serverConfig.serverPort)...")

        routingController.handleListener(
            dandelionListener: dandelionServer,
            targetHost: targetHost,
            targetPort: targetPort)
    }
    
    enum DandelionError: Error
    {
        case InvalidConfig(configPath: String)
        case ConflictingTargetAddress(configHost: String, configPort: Int, bindHost: String, bindPort: Int)
        
        var description: String
        {
            switch self {
                case .InvalidConfig(let configPath):
                    return "We were unable to parse the Dandelion server config at the provided path. Is this file a valid Dandelion server config in JSON format?\nconfig located at \(configPath)"
                case .ConflictingTargetAddress(let configHost, let configPort, let bindHost, let bindPort):
                    return "The selected bind address (\(bindHost):\(bindPort)) is different from the address provided in the config file (\(configHost):\(configPort)"
            }
        }
    }
}
