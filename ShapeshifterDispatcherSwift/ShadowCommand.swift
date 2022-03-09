//
//  ShadowCommand.swift
//  ShapeshifterDispatcherSwift
//
//  Created by Mafalda on 3/2/22.
//

import ArgumentParser
import Foundation
import Logging

import ShadowSwift

extension Command
{
    struct ShadowCommand: ParsableCommand
    {
        static var configuration: CommandConfiguration
        {
            .init(
                commandName: "shadow",
                abstract: "Launches a DarkStar Shadow server."
            )
        }
        
        @Argument(help: "The path to the Shadow config file.")
        var configPath: String
        
        @Argument(help: "")
        var targetHost = "127.0.0.1"
        @Argument(help: "")
        var targetPort = 9999
        
        @Argument(help: "")
        var bindHost = "0.0.0.0"
        @Argument(help: "")
        var bindPort = 1234
        
        func run() throws
        {
            #if canImport(WASILibc)
            // Logger is already setup
            #else
            // Setup the logger
            LoggingSystem.bootstrap(StreamLogHandler.standardError)
            appLog.logLevel = .debug
            #endif
            
            guard let shadowConfig = ShadowConfig(path: configPath) else
            {
                appLog.error("Failed to launch a ShadowServer, we were unable to parse the config at the provided path.")
                return
            }
            
            guard let shadowListener = ShadowServer(host: bindHost, port: bindPort, config: shadowConfig, logger: appLog) else
            {
                appLog.error("Failed to initialize a ShadowServer with the config provided.")
                return
            }
            
            let routingController = RoutingController()
            
            routingController.handleListener(listener: shadowListener, targetHost: targetHost, targetPort: targetPort)
        }
    }
}
