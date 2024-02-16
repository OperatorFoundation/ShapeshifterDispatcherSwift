//
//  AsyncRoutingController.swift
//  
//
//  Created by Mafalda on 12/6/23.
//

import Foundation

import Chord
import ShadowSwift
import TransmissionAsync

class AsyncRoutingController
{
    let verbose = false
    
    var routes = [AsyncRouter]()
    
    func handleListener(listener: AsyncListener, targetHost: String, targetPort: Int)
    {
        while true
        {
            if verbose
            {
                print("Async router listening for connections...")
            }
            
            do
            {
                let transportConnection = try AsyncAwaitThrowingSynchronizer<AsyncConnection>.sync
                {
                    let connection = try await listener.accept()
                    print("Accepted a transport connection.")
                    return connection
                }
                
                Task
                {
                   do
                   {
                       let targetConnection = try await AsyncTcpSocketConnection(targetHost, targetPort, appLog, verbose: verbose)
                       print("A target connection was created.")
                       let route = AsyncRouter(controller: self, transportConnection: transportConnection, targetConnection: targetConnection)
                       print("ShapeshifterDispatcherSwift: new route created.")
                       routes.append(route)
                   }
                    catch (let targetConnectionError)
                    {
                        print("Failed to connect to the application server. Error: \(targetConnectionError)")
                        appLog.error("Failed to connect to the application server. Error: \(targetConnectionError)")
                        try await listener.close()
                        return
                    }
                }
            }
            catch AsyncDarkstarServerError.blackHoled
            {
                print("The connection was blackHoled.)")
                appLog.error("ShapeshifterDispatcher.handleListener: Failed to accept a new connection: blackHoled")
                continue
            }
            catch
            {
                print("Failed to accept a new connection: \(error).")
                appLog.error("ShapeshifterDispatcher.handleListener: Failed to accept a new connection: \(error)")
                return
            }
        }
    }
    
    func remove(route: AsyncRouter)
    {
        self.routes = self.routes.filter
        {
            otherRoute in
            
            otherRoute != route
        }
    }
}

