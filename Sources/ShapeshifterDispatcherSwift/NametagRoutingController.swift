//
//  NametagRoutingController.swift
//
//
//  Created by Mafalda on 10/26/23.
//

import Foundation

import DandelionServer
import Keychain
import Transmission


class NametagRoutingController
{
    var routes = [PublicKey: NametagRouter]()
    
    func handleListener(dandelionListener: DandelionServer, targetHost: String, targetPort: Int) async
    {
        print("ShapeshifterDispatcherSwift: RoutingController.handleListener()")
        
        while true
        {
            do
            {
                let transportConnection = try dandelionListener.accept()
                print("ShapeshifterDispatcherSwift: Dandelion listener accepted a transport connection.")
                
                if let existingRoute = routes[transportConnection.publicKey]
                {
                    try await existingRoute.clientConnected(connection: transportConnection)
                }
                else
                {
                    /// If the public key of the incoming connection is not in the table,
                    /// a new connection to the target application server is created.
                    
                    guard let targetConnection = TransmissionConnection(host: targetHost, port: targetPort) else
                    {
                        print("ShapeshifterDispatcherSwift: RoutingController.handleListener: Failed to connect to the target server.")
                        appLog.error("ShapeshifterDispatcher.handleListener: Failed to connect to the application server.")
                        transportConnection.network.close()
                        continue
                    }
                    
                    print("ShapeshifterDispatcherSwift: Dandelion target connection created.")
                    
                    /// While that incoming connection is open, data is pumped between the incoming connection and the newly opened target application server connection.
                    let route = await NametagRouter(controller: self, transportConnection: transportConnection, targetConnection: targetConnection)
                    print("ShapeshifterDispatcherSwift: new route created.")
                    
                    // We don't already have this public key, save it to our routes
                    routes[transportConnection.publicKey] = route
                }
            }
            catch
            {
                print("ShapeshifterDispatcherSwift: RoutingController.handleListener: Failed to accept a new connection: \(error).")
                appLog.error("ShapeshifterDispatcher.handleListener: Failed to accept a new connection: \(error)")
                continue
            }
        }
    }
    
    
    func remove(route: NametagRouter) async
    {
        await self.routes.removeValue(forKey: route.clientConnection.publicKey)
    }
}
