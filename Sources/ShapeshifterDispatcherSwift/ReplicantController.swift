//
//  ReplicantController.swift
//  ShapeshifterDispatcherSwift
//
//  Created by Mafalda on 3/7/22.
//

import Foundation

import Logging
import Net
import ReplicantSwift
import Transport
import Transmission

struct ReplicantController
{
    var configPath:String
    var targetHost = "127.0.0.1"
    var targetPort = 9999
    var bindHost = "0.0.0.0"
    var bindPort = 1234
    
    func runServer() throws
    {
        guard let serverReplicantConfig = ReplicantServerConfig(withConfigAtPath: configPath)
        else
        {
            throw Error.configError
        }
        
        // TODO: ReplicantListener should take a BindHost Argument
        let replicant = Replicant(logger: appLog, osLogger: nil)
        
        
        guard let replicantListener = try? replicant.listen(address: bindHost, port: bindPort, config: serverReplicantConfig) else
        {
            appLog.error("\(Error.listenerError.errorDescription)")
            throw Error.listenerError
        }
        
        let routingController = RoutingController()
        routingController.handleListener(listener: replicantListener, targetHost: targetHost, targetPort: targetPort)
    }
    
    enum Error: LocalizedError
    {
        case configError
        case listenerError
        
        var errorDescription: String
        {
            switch self
            {
                case .configError:
                    return "We were unable to generate valid configuration settings for the server."
                case .listenerError:
                    return "We were unable to create a Replicant listener."
            }
        }
    }
}
