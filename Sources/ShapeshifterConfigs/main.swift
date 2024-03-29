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
import Gardener
import Omni
import ReplicantSwift
import ShadowSwift
import Starbridge

struct ShapeshifterConfig: ParsableCommand
{
    static let configuration = CommandConfiguration(
        abstract: "Generate new config files for various transports supported by ShapeshifterDispatcher",
        subcommands: [ShadowConfigGenerator.self,
                      StarbridgeConfigGenerator.self,
                      OmniConfigGenerator.self,
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

// MARK: Shadow
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
            
            try ShadowConfig.createNewConfigFiles(inDirectory: saveURL, serverAddress: "\(parentOptions.host):\(parentOptions.port)", cipher: cipherMode)
            print("New Shadow config files have been saved to \(saveURL)")
        }
    }
}

// MARK: Starbridge
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
            try StarbridgeConfig.createNewConfigFiles(inDirectory: saveURL, serverAddress: "\(parentOptions.host):\(parentOptions.port)")
        }
    }
}

// MARK: Dandelion
extension ShapeshifterConfig
{
    struct DandelionConfigGenerator: ParsableCommand
    {
        static let configuration = CommandConfiguration(commandName: "dandelion", abstract: "Generate new config files for the Dandelion transport.")
        
        @OptionGroup() var parentOptions: Options
        @Flag(help: "Whether or not to overwrite any existing config files and encryption keys.")
        var overwrite = false
        
        func run() throws
        {
            print("Generating Dandelion configuration files...")
            
            let saveURL = URL(fileURLWithPath: parentOptions.directory, isDirectory: true)
            let keychainDirectoryURL = File.homeDirectory().appendingPathComponent(".Dandelion-server")
            let keychainLabel = "DandelionServer.KeyAgreement"
            
            try DandelionConfig.generateNewConfigFiles(inDirectory: saveURL, serverAddress: "\(parentOptions.host):\(parentOptions.port)", keychainURL: keychainDirectoryURL, keychainLabel: keychainLabel, overwriteKey: overwrite)

            print("New Dandelion config files have been saved to \(saveURL)")
        }
    }
}

// MARK: Omni
extension ShapeshifterConfig
{
    struct OmniConfigGenerator: ParsableCommand
    {
        static let configuration = CommandConfiguration(commandName: "omni", abstract: "Generate new config files for the Omni transport.")
        
        @OptionGroup() var parentOptions: Options
        
        func run() throws
        {
             print("Generating Omni configuration files...")
            
            let saveURL = URL(fileURLWithPath: parentOptions.directory, isDirectory: true)
            try OmniConfig.createNewConfigFiles(inDirectory: saveURL, serverAddress: "\(parentOptions.host):\(parentOptions.port)")
        }
    }
}

// MARK: Errors
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
