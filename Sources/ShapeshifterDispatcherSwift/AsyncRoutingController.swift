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
            appLog.debug("Listening for connections...")
            
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
                    appLog.debug("ShapeshifterDispatcher.handleListener: Accepted a transport connection.")
                    return connection
                }
                
                Task
                {
                   do
                   {
                       let targetConnection = try await AsyncTcpSocketConnection(targetHost, targetPort, appLog)
                       appLog.debug("ShapeshifterDispatcher.handleListener: Created a connection to the target host.")
                       let route = AsyncRouter(controller: self, transportConnection: transportConnection, targetConnection: targetConnection)
                       appLog.debug("ShapeshifterDispatcher.handleListener: Created a new route.")
                       routes.append(route)
                   }
                    catch (let targetConnectionError)
                    {
                        appLog.warning("ShapeshifterDispatcher.handleListener: A client connection could not be accepted, we failed to connect to the application server. Reason: \(targetConnectionError)")
                    }
                }
            }
            catch AsyncDarkstarServerError.blackHoled
            {
                appLog.warning("ShapeshifterDispatcher.handleListener: Failed to accept a new connection: blackHoled")
                continue
            }
            catch
            {
                appLog.warning("ShapeshifterDispatcher.handleListener: Failed to accept a new connection: \(error)")
                continue
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

