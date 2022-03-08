//
//  ShadowServerController.swift
//  ShapeshifterDispatcherSwift
//
//  Created by Mafalda on 3/2/22.
//

import Foundation
import Logging

import ShadowSwift
import Flower

struct ShadowServerController
{
    func startListening(shadowConfigPath: String)
    {
        guard let shadowConfig = ShadowConfig(path: shadowConfigPath) else
        {
            appLog.error("Failed to launch a ShadowServer, we were unable to parse the config at the provided path.")
            return
        }
        
        guard let shadowListener = ShadowServer(host: "127.0.0.1", port: 1234, config: shadowConfig, logger: appLog) else
        {
            appLog.error("Failed to initialize a ShadowServer with the config provided.")
            return
        }
        
        while true
        {
            guard let shadowConnection = shadowListener.accept() else
            {
                appLog.error("Failed to create a shadow connection.")
                return
            }
            
            print("👻 New Shadow Connection! 👻")
        }
    }
}

