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
    static let configuration = CommandConfiguration(abstract: "Generate new config files for various transports supported by ShapeshifterDispatcher", subcommands: [Shadow.self])
    
    init() { }
}

struct Shadow: ParsableCommand
{
    @Option(name: .shortAndLong, help: "Specifies the <ip_address> of the Shadow server.")
    var host: String
    
    @Option(name: .shortAndLong, help: "Specifies the <port> the Shadow server should listen on.")
    var port: UInt16
    
    @Option(name: .shortAndLong, help: "Specifies the cipher the Shadow server should use, currently only DarkStar is supported.")
    var cipher: String = "DarkStar"
    
    @Option(name: .shortAndLong, help: "Specifies the directory the configs should be saved to.")
    var directory: String
    
    
    static let configuration = CommandConfiguration(abstract: "Generate new config files for the Shadow transport.")
    
    func validate() throws
    {
        guard CipherMode(rawValue: cipher) != nil else
        {
            print("\(cipher) is not a supported cipher mode.")
            throw ShadowError.cipherModeNotSupported
        }
        
        guard URL(fileURLWithPath: directory, isDirectory: true).isDirectory else
        {
            print("\(directory) is not a directory.")
            throw ShadowError.savePathIsNotDirectory
        }
    }
    
    func run() throws
    {
        print("Generating Shadow Configs...")
        
        let saveURL = URL(fileURLWithPath: directory, isDirectory: true)
        
        guard let cipherMode = CipherMode(rawValue: cipher) else
        {
            print("\(cipher) is not a supported cipher mode.")
            throw ShadowError.cipherModeNotSupported
        }
        
        let result = ShadowConfig.createNewConfigFiles(inDirectory: saveURL, serverIP: host, serverPort: port, cipher: cipherMode)
        
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

public enum ShadowError: Error
{
    case cipherModeNotSupported
    case savePathIsNotDirectory
}

ShapeshifterConfig.main()
