//
//  ReplicantCommand.swift
//  ShapeshifterDispatcherSwift
//
//  Created by Mafalda on 3/7/22.
//

import Foundation
import ArgumentParser

import Logging
import Net
import ReplicantSwift
import Transport
import Transmission

extension Command
{
    struct ReplicantCommand: ParsableCommand
    {
        static var configuration: CommandConfiguration
        {
            .init(
                commandName: "replicant",
                abstract: "Launches a Replicant server"
            )
        }
        
        @Argument(help: "The path to the Replicant config file.")
        var configPath:String
        
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
            
            // FIXME: Currently everything is just hard-coded defaults
            // Configs should be provided by the user
            guard let serverReplicantConfig = ReplicantServerConfig(withConfigAtPath: configPath)
            else
            {
                throw Error.configError
            }
            
            // TODO: ReplicantListener should take a BindHost Argument
            guard let replicantListener = ReplicantListener(port: bindPort, replicantConfig: serverReplicantConfig, logger: appLog) else { return } // TODO: Throw
            
            let routingController = RoutingController()
            routingController.handleListener(listener: replicantListener, targetHost: targetHost, targetPort: targetPort)
        }
        
        enum Error: LocalizedError
        {
            case configError
            
            var errorDescription: String?
            {
                switch self
                {
                    case .configError:
                        return "We were unable to generate valid configuration settings for the server."
                }
            }
        }
    }
}
