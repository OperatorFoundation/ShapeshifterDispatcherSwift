//
//  RoutingController.swift
//  ShapeshifterDispatcherSwift
//
//  Created by Mafalda on 3/8/22.
//

import Foundation

import Chord
import Transmission

class RoutingController
{
    var routes = [Router]()
    
    func handleListener(listener: Transmission.Listener, targetHost: String, targetPort: Int)
    {
        while true
        {
            do
            {
                let transportConnection = try listener.accept()
                // Pause between accepting connections to throttle potential spamming
                Thread.sleep(forTimeInterval: 0.1) // 100 milliseconds in seconds
                
                appLog.debug("ShapeshifterDispatcherSwift: listener accepted a transport connection.")
                                
                guard let targetConnection = TransmissionConnection(host: targetHost, port: targetPort) else
                {
                    appLog.error("ShapeshifterDispatcher.handleListener: Failed to connect to the application server.")
                    listener.close()
                    continue
                }
                
                appLog.debug("ShapeshifterDispatcherSwift: target connection created.")
                
                let route = Router(controller: self, transportConnection: transportConnection, targetConnection: targetConnection)
                appLog.debug("ShapeshifterDispatcherSwift: new route created.")
                routes.append(route)
            }
            catch
            {
                appLog.error("ShapeshifterDispatcher.handleListener: Failed to accept a new connection: \(error)")
                continue
            }
        }
    }
    
    func remove(route: Router)
    {
        self.routes = self.routes.filter
        {
            otherRoute in
            
            otherRoute != route
        }
    }
}
