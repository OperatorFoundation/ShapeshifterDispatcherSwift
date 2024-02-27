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
    var routes = [AsyncRouter]()
    
    func handleListener(listener: AsyncListener, targetHost: String, targetPort: Int)
    {
        while true
        {
            appLog.debug("Async router listening for connections...")
            
            do
            {
                defer
                {
                    // Pause between accepting connections to throttle potential spamming
                    Thread.sleep(forTimeInterval: 0.1) // 100 milliseconds in seconds
                }
                
                let transportConnection = try AsyncAwaitThrowingSynchronizer<AsyncConnection>.sync
                {
                    let connection = try await listener.accept()
                    appLog.debug("Accepted a transport connection.")
                    return connection
                }
                
                Task
                {
                   do
                   {
                       let targetConnection = try await AsyncTcpSocketConnection(targetHost, targetPort, appLog)
                       appLog.debug("A target connection was created.")
                       let route = AsyncRouter(controller: self, transportConnection: transportConnection, targetConnection: targetConnection)
                       appLog.debug("ShapeshifterDispatcherSwift: new route created.")
                       routes.append(route)
                   }
                    catch (let targetConnectionError)
                    {
                        appLog.error("Failed to connect to the application server. Error: \(targetConnectionError)")
                        try await listener.close()
                        return
                    }
                }
            }
            catch AsyncDarkstarServerError.blackHoled
            {
                appLog.error("ShapeshifterDispatcher.handleListener: Failed to accept a new connection: blackHoled")
                continue
            }
            catch
            {
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

