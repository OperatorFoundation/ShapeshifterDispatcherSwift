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
    let verbose = true
    
    var configPath: String
    var targetHost: String
    var targetPort: Int
    var bindHost: String
    var bindPort: Int
    
    func runServer() throws
    {
        guard let shadowConfig = ShadowConfig.ShadowServerConfig(path: configPath) else
        {
            appLog.error("Failed to launch a ShadowServer, we were unable to parse the config at the provided path: \(configPath)")
            return
        }
        
        guard shadowConfig.serverIP == bindHost && shadowConfig.serverPort == bindPort else
        {
            
            throw ShadowError.ConflictingTargetAddress(configHost: shadowConfig.serverIP, configPort: Int(shadowConfig.serverPort), bindHost: bindHost, bindPort: bindPort)
        }
        
        print("Starting a shadow server using cipher mode: \(shadowConfig.mode)")
        do
        {
            let shadowListener = try AsyncDarkstarListener(config: shadowConfig, logger: appLog, verbose: verbose)
            let routingController = AsyncRoutingController()
            
            print("Listening at \(shadowConfig.serverIP) on port \(shadowConfig.serverPort)...")
            
            routingController.handleListener(listener: shadowListener, targetHost: targetHost, targetPort: targetPort)
        }
        catch (let shadowError)
        {
            appLog.error("Shapeshifter Failed to initialize a ShadowServer with the config provided. Error: \(shadowError)")
            return
        }
        
        
    }
    
    enum ShadowError: Error
    {
        case InvalidConfig(configPath: String)
        case ConflictingTargetAddress(configHost: String, configPort: Int, bindHost: String, bindPort: Int)
        
        var description: String
        {
            switch self {
                case .InvalidConfig(let configPath):
                    return "We were unable to parse the Shadow server config at the provided path. Is this file a valid Shadow server config in JSON format?\nconfig located at \(configPath)"
                case .ConflictingTargetAddress(let configHost, let configPort, let bindHost, let bindPort):
                    return "The selected bind address (\(bindHost):\(bindPort)) is different from the address provided in the Shadow config file (\(configHost):\(configPort)"
            }
        }
    }
}
