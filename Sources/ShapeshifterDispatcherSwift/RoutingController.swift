//
//  RoutingController.swift
//  ShapeshifterDispatcherSwift
//
//  Created by Mafalda on 3/8/22.
//

import Foundation

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
                print("ShapeshifterDispatcherSwift: listener accepted a transport connection.")
                
                guard let targetConnection = TransmissionConnection(host: targetHost, port: targetPort) else
                {
                    print("ShapeshifterDispatcherSwift: RoutingController.handleListener: Failed to connect to the target server.")
                    appLog.error("ShapeshifterDispatcher.handleListener: Failed to connect to the application server.")
                    listener.close()
                    continue
                }
                
                print("ShapeshifterDispatcherSwift: target connection created.")
                
                let route = Router(controller: self, transportConnection: transportConnection, targetConnection: targetConnection)
                print("ShapeshifterDispatcherSwift: new route created.")
                routes.append(route)
            }
            catch
            {
                print("ShapeshifterDispatcherSwift: RoutingController.handleListener: Failed to accept a new connection: \(error).")
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
