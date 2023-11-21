//
//  NametagRoutingController.swift
//
//
//  Created by Mafalda on 10/26/23.
//

import Foundation
import Logging

import Chord
import DandelionServer
import Keychain
import TransmissionAsync
import TransmissionAsyncNametag


class NametagRoutingController
{
    var routes = [PublicKey: NametagRouter]()
    var connectionQueue = DispatchQueue(label: "NametagClientConnectionQueue")
    var logger: Logger
    
    init(logger: Logger)
    {
        self.logger = logger
    }
    
    func handleListener(dandelionListener: DandelionServer, targetHost: String, targetPort: Int)
    {
        print("ShapeshifterDispatcherSwift: RoutingController.handleListener()")
        
        while true
        {
            do
            {
                let transportConnection = try AsyncAwaitThrowingSynchronizer<AsyncConnection>.sync
                {
                    let connection = try await dandelionListener.accept()
                    print("Accepted a connection.")
                    return connection
                }
                
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
            catch
            {
                print("ShapeshifterDispatcherSwift: RoutingController.handleListener: Failed to accept a new connection: \(error).")
                appLog.error("ShapeshifterDispatcher.handleListener: Failed to accept a new connection: \(error)")
                continue
            }
        }
    }
    
    func handleConnection(clientConnection: AsyncNametagServerConnection, targetHost: String, targetPort: Int) async throws
    {
        print("ShapeshifterDispatcherSwift: Dandelion listener accepted a transport connection.")
        
        if let existingRoute = routes[clientConnection.publicKey]
        {
            print("Handling a connection from an existing route...")
            try await existingRoute.clientConnected(connection: clientConnection)
            
            /// While that incoming connection is open, data is pumped between the incoming connection and the newly opened target application server connection.
            let route = await NametagRouter(controller: self, transportConnection: clientConnection, targetConnection: existingRoute.targetConnection, buffer: existingRoute.bufferedDataForClient)
            print("ShapeshifterDispatcherSwift: an existing route has been updated.")
            
            // We don't already have this public key, save it to our routes
            routes[clientConnection.publicKey] = route
        }
        else
        {
            /// If the public key of the incoming connection is not in the table,
            /// a new connection to the target application server is created.
            do
            {
                let targetConnection = try await AsyncTcpSocketConnection(targetHost, targetPort, logger)
                print("ShapeshifterDispatcherSwift: Dandelion target connection created.")
                
                /// While that incoming connection is open, data is pumped between the incoming connection and the newly opened target application server connection.
                let route = await NametagRouter(controller: self, transportConnection: clientConnection, targetConnection: targetConnection)
                print("ShapeshifterDispatcherSwift: new route created.")
                
                // We don't already have this public key, save it to our routes
                routes[clientConnection.publicKey] = route
            }
            catch (let error)
            {
                print("ShapeshifterDispatcherSwift: RoutingController.handleListener: Failed to connect to the target server. Error: \(error)")
                appLog.error("ShapeshifterDispatcher.handleListener: Failed to connect to the application server. Error: \(error)")
                try await clientConnection.network.close()
                return
            }
        }
    }
    
    func remove(route: NametagRouter) async
    {
        await self.routes.removeValue(forKey: route.clientConnection.publicKey)
    }
}
