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
import TransmissionNametag


class NametagRoutingController
{
    var routes = [PublicKey: NametagRouter]()
    var connectionQueue = DispatchQueue(label: "NametagClientConnectionQueue")
    
    func handleListener(dandelionListener: DandelionServer, targetHost: String, targetPort: Int)
    {
        print("ShapeshifterDispatcherSwift: RoutingController.handleListener()")
        
        while true
        {
            do
            {
                let transportConnection = try dandelionListener.accept()
                
                connectionQueue.async 
                {
                    Task
                    {
                        do
                        {
                            try await self.handleConnection(clientConnection: transportConnection, targetHost: targetHost, targetPort: targetPort)
                        }
                        catch (let clientConnectionError)
                        {
                            print("Received an error while accepting a client connection: \(clientConnectionError)")
                        }
                    }
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
    
    func handleConnection(clientConnection: NametagServerConnection, targetHost: String, targetPort: Int) async throws
    {
        print("ShapeshifterDispatcherSwift: Dandelion listener accepted a transport connection.")
        
        if let existingRoute = routes[clientConnection.publicKey]
        {
            try await existingRoute.clientConnected(connection: clientConnection)
        }
        else
        {
            /// If the public key of the incoming connection is not in the table,
            /// a new connection to the target application server is created.
            
            guard let targetConnection = TransmissionConnection(host: targetHost, port: targetPort) else
            {
                print("ShapeshifterDispatcherSwift: RoutingController.handleListener: Failed to connect to the target server.")
                appLog.error("ShapeshifterDispatcher.handleListener: Failed to connect to the application server.")
                clientConnection.network.close()
                return
            }
            
            print("ShapeshifterDispatcherSwift: Dandelion target connection created.")
            
            /// While that incoming connection is open, data is pumped between the incoming connection and the newly opened target application server connection.
            let route = await NametagRouter(controller: self, transportConnection: clientConnection, targetConnection: targetConnection)
            print("ShapeshifterDispatcherSwift: new route created.")
            
            // We don't already have this public key, save it to our routes
            routes[clientConnection.publicKey] = route
        }
    }
    
    func remove(route: NametagRouter) async
    {
        await self.routes.removeValue(forKey: route.clientConnection.publicKey)
    }
}
