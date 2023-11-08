//
//  main.swift
//  
//
//  Created by Mafalda on 9/20/22.
//

import ArgumentParser
import Foundation
import Logging

import Dandelion
import Keychain
import ReplicantSwift
import ShadowSwift
import Starbridge

struct ShapeshifterConfig: ParsableCommand
{
    static let configuration = CommandConfiguration(
        abstract: "Generate new config files for various transports supported by ShapeshifterDispatcher",
        subcommands: [ShadowConfigGenerator.self,
                      StarbridgeConfigGenerator.self,
                      ReplicantConfigGenerator.self,
                      DandelionConfigGenerator.self])
    
    struct Options: ParsableArguments
    {
        @Option(name: .shortAndLong, help: "Specifies the <ip_address> that the server will have.")
        var host: String
        
        @Option(name: .shortAndLong, help: "Specifies the <port> the server should listen on.")
        var port: UInt16
        
        @Option(name: .shortAndLong, help: "Specifies the directory the configs should be saved to.")
        var directory: String
        
        @Flag var toneburst = false
        @Flag var polish = false
    }
    
    @OptionGroup() var parentOptions: Options
    
    func validate() throws
    {
        guard URL(fileURLWithPath: parentOptions.directory, isDirectory: true).isDirectory else
        {
            throw ConfigError.savePathIsNotDirectory(savePath: parentOptions.directory)
        }
    }
    
    init() { }
}

extension ShapeshifterConfig
{
    struct ShadowConfigGenerator: ParsableCommand
    {
        static let configuration = CommandConfiguration(commandName: "shadow", abstract: "Generate new config files for the Shadow transport.")
        
        @OptionGroup() var parentOptions: Options
        
        @Option(name: .shortAndLong, help: "Specifies the cipher the Shadow server should use, currently only DarkStar is supported.")
        var cipher: String = "darkstar"
        
        func validate() throws
        {
            guard CipherMode(rawValue: cipher) != nil else
            {
                throw ShadowError.cipherModeNotSupported(cipherString: cipher)
            }
        }
        
        func run() throws
        {
            print("Generating Shadow configuration files...")
            
            let saveURL = URL(fileURLWithPath: parentOptions.directory, isDirectory: true)
            
            guard let cipherMode = CipherMode(rawValue: cipher) else
            {
                throw ShadowError.cipherModeNotSupported(cipherString: cipher)
            }
            
            let result = ShadowConfig.createNewConfigFiles(inDirectory: saveURL, serverAddress: "\(parentOptions.host):\(parentOptions.port)", cipher: cipherMode)
            
            if result.saved
            {
                print("New Shadow config files have been saved to \(saveURL)")
            }
            else
            {
                if let saveError = result.error
                {
                    print("Error generating new Shadow config files: \(saveError)")
                }
                else
                {
                    print("Failed to generate the requested Shadow config files.")
                }
            }
        }
    }
}

extension ShapeshifterConfig
{
    struct StarbridgeConfigGenerator: ParsableCommand
    {
        static let configuration = CommandConfiguration(commandName: "starbridge", abstract: "Generate new config files for the Starbridge transport.")
        
        @OptionGroup() var parentOptions: Options
        
        func run() throws
        {
             print("Generating Starbridge configuration files...")
            
            let saveURL = URL(fileURLWithPath: parentOptions.directory, isDirectory: true)
            let success = try Starbridge.createNewConfigFiles(inDirectory: saveURL, serverAddress: "\(parentOptions.host):\(parentOptions.port)")
    
            if success
            {
                print("New Starbridge config files have been saved to \(saveURL)")
            }
            else
            {
                print("Failed to generate the requested Starbridge config files.")
            }
        }
    }
}

extension ShapeshifterConfig
{
    struct ReplicantConfigGenerator: ParsableCommand
    {
        static let configuration = CommandConfiguration(commandName: "replicant", abstract: "Generate new config files for the Replicant transport.")
        
        @OptionGroup() var parentOptions: Options
        
        func run() throws
        {
            print("Generating Replicant configuration files...")
            
            let saveURL = URL(fileURLWithPath: parentOptions.directory, isDirectory: true)
            let success = ReplicantSwift.createNewConfigFiles(inDirectory: saveURL, serverAddress: "\(parentOptions.host):\(parentOptions.port)", polish: parentOptions.polish, toneburst: parentOptions.toneburst)
            
            if success
            {
                print("New Starbridge config files have been saved to \(saveURL)")
            }
            else
            {
                print("Failed to generate the requested Starbridge config files.")
            }
        }
    }
}

extension ShapeshifterConfig
{
    struct DandelionConfigGenerator: ParsableCommand
    {
        static let configuration = CommandConfiguration(commandName: "dandelion", abstract: "Generate new config files for the Dandelion transport.")
        
        @OptionGroup() var parentOptions: Options
        
//        @Option(name: .shortAndLong, help: "The Dandelion public encryption key.")
//        var key: String
        
        func run() throws
        {
            print("Generating Dandelion configuration files...")
            
            let saveURL = URL(fileURLWithPath: parentOptions.directory, isDirectory: true)
            
//            guard let publicKey = PublicKey(jsonString: key) else
//            {
//                // TODO: Throw
//                return
//            }
            
            try DandelionConfig.createNewConfigFiles(inDirectory: saveURL, serverAddress: "\(parentOptions.host):\(parentOptions.port)")
            print("New Dandelion config files have been saved to \(saveURL)")
            
        }
    }
}

public enum ConfigError: Error
{
    case savePathIsNotDirectory(savePath: String)
    
    public var description: String
    {
        switch self
        {
            case .savePathIsNotDirectory(let savePath):
                return "The provided path is not a directory: \(savePath)"
        }
    }
}

public enum ShadowError: Error
{
    case cipherModeNotSupported(cipherString: String)
    
    public var description: String
    {
        switch self
        {
            case .cipherModeNotSupported(let cipherString):
                return "The provided cipher mode is not supported: \(cipherString)"
        }
    }
}

ShapeshifterConfig.main()
