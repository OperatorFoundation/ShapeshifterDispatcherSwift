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
        
        guard serverConfig.serverAddress == bindHost && serverConfig.serverPort == bindPort else
        {
            
            throw DandelionError.ConflictingTargetAddress(configPath: configPath, targetHost: targetHost, targetPort: targetPort)
        }
        
        print("Starting a Dandelion server.")
        
        guard let dandelionServer = DandelionServer(config: serverConfig, logger: appLog) else
        {
            return
        }
    }
    
    enum DandelionError: Error
    {
        case InvalidConfig(configPath: String)
        case ConflictingTargetAddress(configPath: String, targetHost: String, targetPort: Int)
        
        var description: String
        {
            switch self {
                case .InvalidConfig(let configPath):
                    return "We were unable to parse the Dandelion server config at the provided path. Is this file a valid Dandelion server config in JSON format?\nconfig located at \(configPath)"
                case .ConflictingTargetAddress(let configPath, let targetHost, let targetPort):
                    return "The selected target address (\(targetHost):\(targetPort)) is different from the address provided in the config file at \(configPath)"
            }
        }
    }
}
