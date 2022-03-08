//
//  main.swift
//  ShapeshifterDispatcherSwift
//
//  Created by Mafalda on 2/18/22.
//

import ArgumentParser
import Foundation
import Logging

var appLog = Logger(label: "org.OperatorFoundation.ReplicantSwiftServer.Linux")

enum Command {}

extension Command
{
    struct Main: ParsableCommand
    {
        static var configuration: CommandConfiguration
        {
            .init(
                commandName: "Dispatcher",
                abstract: "A program for launching transport servers.",
                subcommands: [
                    Command.ShadowCommand.self,
                    Command.ReplicantCommand.self
                ]
            )
        }
    }
}

