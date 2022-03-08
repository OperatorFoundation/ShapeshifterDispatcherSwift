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
import ReplicantSwiftServerCore
import Transport

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
            
            let serverConfig = ServerConfig(withPort: NWEndpoint.Port(integerLiteral: 1234), andHost: NWEndpoint.Host.ipv4(IPv4Address("0.0.0.0")!))
            let routingController = RoutingController(logger: appLog)

            ///FIXME: User should control whether transport is enabled
            routingController.startListening(serverConfig: serverConfig, replicantConfig: serverReplicantConfig, replicantEnabled: true)
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
