//
//  main.swift
//  
//
//  Created by Mafalda on 9/20/22.
//

import ArgumentParser
import Foundation
import Logging

import ShadowSwift

struct ShapeshifterConfig: ParsableCommand
{
    static let configuration = CommandConfiguration(abstract: "Generate new config files for various transports supported by ShapeshifterDispatcher", subcommands: [Shadow.self, Starbridge.self])
    
    struct Options: ParsableArguments
    {
        @Option(name: .shortAndLong, help: "Specifies the <ip_address> of the Shadow server.")
        var host: String
        
        @Option(name: .shortAndLong, help: "Specifies the <port> the Shadow server should listen on.")
        var port: UInt16
        
        @Option(name: .shortAndLong, help: "Specifies the directory the configs should be saved to.")
        var directory: String
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
    struct Shadow: ParsableCommand
    {
        static let configuration = CommandConfiguration(abstract: "Generate new config files for the Shadow transport.")
        
        @OptionGroup() var parentOptions: Options
        
        @Option(name: .shortAndLong, help: "Specifies the cipher the Shadow server should use, currently only DarkStar is supported.")
        var cipher: String = "DarkStar"
        
        func validate() throws
        {
            guard CipherMode(rawValue: cipher) != nil else
            {
                throw ShadowError.cipherModeNotSupported(cipherString: cipher)
            }
        }
        
        func run() throws
        {
            print("Generating Shadow Configs...")
            
            let saveURL = URL(fileURLWithPath: parentOptions.directory, isDirectory: true)
            
            guard let cipherMode = CipherMode(rawValue: cipher) else
            {
                throw ShadowError.cipherModeNotSupported(cipherString: cipher)
            }
            
            let result = ShadowConfig.createNewConfigFiles(inDirectory: saveURL, serverIP: parentOptions.host, serverPort: parentOptions.port, cipher: cipherMode)
            
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
    struct Starbridge: ParsableCommand
    {
        static let configuration = CommandConfiguration(abstract: "Generate new config files for the Starbridge transport.")
        
        @OptionGroup() var parentOptions: Options
        
        @Option(name: .shortAndLong, help: "Specifies the cipher the Shadow server should use, currently only DarkStar is supported.")
        var cipher: String = "DarkStar"
        
        func validate() throws
        {
            guard CipherMode(rawValue: cipher) != nil else
            {
                throw ShadowError.cipherModeNotSupported(cipherString: cipher)
            }
        }
        
        func run() throws
        {
            print("Starbridge config generation is not yet supported.")
            // print("Generating Starbridge Configs...")
            
            let saveURL = URL(fileURLWithPath: parentOptions.directory, isDirectory: true)
            
            guard let cipherMode = CipherMode(rawValue: cipher) else
            {
                throw ShadowError.cipherModeNotSupported(cipherString: cipher)
            }
            
    //        let result = ShadowConfig.createNewConfigFiles(inDirectory: saveURL, serverIP: host, serverPort: port, cipher: cipherMode)
    //
    //        if result.saved
    //        {
    //            print("New Starbridge config files have been saved to \(saveURL)")
    //        }
    //        else
    //        {
    //            if let saveError = result.error
    //            {
    //                print("Error generating new Starbridge config files: \(saveError)")
    //            }
    //            else
    //            {
    //                print("Failed to generate the requested Starbridge config files.")
    //            }
    //        }
        }
    }
}

public enum ConfigError: Error
{
    case savePathIsNotDirectory(savePath: String)
}

extension ConfigError: CustomStringConvertible
{
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
}

extension ShadowError: CustomStringConvertible
{
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
