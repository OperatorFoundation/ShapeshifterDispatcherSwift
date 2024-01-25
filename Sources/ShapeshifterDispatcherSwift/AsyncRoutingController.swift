//
//  AsyncRoutingController.swift
//  
//
//  Created by Mafalda on 12/6/23.
//

import Foundation

import Chord
//import Transmission
import TransmissionAsync

class AsyncRoutingController
{
    let verbose = false
    
    var routes = [AsyncRouter]()
    
    func handleListener(listener: AsyncListener, targetHost: String, targetPort: Int)
    {
        while true
        {
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
            catch
            {
                print("Failed to accept a new connection: \(error).")
                appLog.error("ShapeshifterDispatcher.handleListener: Failed to accept a new connection: \(error)")
                return
            }
        }
    }
    
//    func handleListener(listener: Transmission.Listener, targetHost: String, targetPort: Int)
//    {
//        while true
//        {
//            do
//            {
//                let transportConnection = try listener.accept()
//                print("ShapeshifterDispatcherSwift: listener accepted a transport connection.")
//
//                guard let targetConnection = TransmissionConnection(host: targetHost, port: targetPort) else
//                {
//                    print("ShapeshifterDispatcherSwift: RoutingController.handleListener: Failed to connect to the target server.")
//                    appLog.error("ShapeshifterDispatcher.handleListener: Failed to connect to the application server.")
//                    listener.close()
//                    continue
//                }
//
//                print("ShapeshifterDispatcherSwift: target connection created.")
//                let route = Router(controller: self, transportConnection: transportConnection, targetConnection: targetConnection)
//                print("ShapeshifterDispatcherSwift: new route created.")
//                routes.append(route)
//            }
//            catch
//            {
//                print("ShapeshifterDispatcherSwift: RoutingController.handleListener: Failed to accept a new connection: \(error).")
//                appLog.error("ShapeshifterDispatcher.handleListener: Failed to accept a new connection: \(error)")
//                continue
//            }
//        }
//    }
    
    func remove(route: AsyncRouter)
    {
        self.routes = self.routes.filter
        {
            otherRoute in
            
            otherRoute != route
        }
    }
}

