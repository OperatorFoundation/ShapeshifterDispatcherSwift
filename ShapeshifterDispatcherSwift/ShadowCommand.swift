//
//  ShadowCommand.swift
//  ShapeshifterDispatcherSwift
//
//  Created by Mafalda on 3/2/22.
//

import ArgumentParser
import Foundation
import Logging

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
        
        func run() throws
        {
            #if canImport(WASILibc)
            // Logger is already setup
            #else
            // Setup the logger
            LoggingSystem.bootstrap(StreamLogHandler.standardError)
            appLog.logLevel = .debug
            #endif
            
            ShadowServerController().startListening(shadowConfigPath: configPath)
            
        }
    }
}
