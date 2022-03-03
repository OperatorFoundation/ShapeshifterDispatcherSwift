//
//  ShadowServerController.swift
//  ShapeshifterDispatcherSwift
//
//  Created by Mafalda on 3/2/22.
//

import Foundation
import Logging

import ShadowSwift

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
            let shadowConnection = shadowListener.accept()
            print("👻 New Shadow Connection! 👻")
        }
        
    //    guard let flowerListener = FlowerListener(port: port, replicantConfig: replicantConfig, logger: logger) else
    //    {
    //        print("unable to create Flower listener")
    //        return
    //    }
    //
    //    while true
    //    {
    //        let flowerConnection = flowerListener.accept()
    //        self.consoleIO.writeMessage("New Replicant Connection!")
    //        self.process(flowerConnection: flowerConnection, port: serverConfig.port)
    //    }
    }
}

