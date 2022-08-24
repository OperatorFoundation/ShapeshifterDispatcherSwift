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
                
                guard let targetConnection = TransmissionConnection(host: targetHost, port: targetPort) else
                {
                    print("ShapeshifterDispatcher.handleListener: Failed to connect to the target server.")
                    appLog.error("Failed to connect to the application server.")
                    listener.close()
                    continue
                }
                
                let route = Router(controller: self, transportConnection: transportConnection, targetConnection: targetConnection)
                routes.append(route)
            }
            catch
            {
                print("ShapeshifterDispatcher.handleListener: Failed to accept a new connection: \(error).")
                appLog.error("Failed to accept a new connection: \(error)")
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

class Router
{
    let maxReadSize = 2048 // Could be tuned through testing in the future
    let transportConnection: Transmission.Connection
    let targetConnection: Transmission.Connection
    let targetToTransportQueue = DispatchQueue(label: "targetToTransportQueue")
    let transportToTargetQueue = DispatchQueue(label: "transportToTargetQueue")
    let cleanupQueue = DispatchQueue(label: "cleanupQueue")
    let lock = DispatchSemaphore(value: 2)
    let controller: RoutingController
    let uuid = UUID()
    
    var keepGoing = true
    
    init(controller: RoutingController, transportConnection: Transmission.Connection, targetConnection: Transmission.Connection)
    {
        self.controller = controller
        self.transportConnection = transportConnection
        self.targetConnection = targetConnection
        
        print("Dispatcher Router Received a new connection")
        
        targetToTransportQueue.async {
            self.transferTargetToTransport(transportConnection: transportConnection, targetConnection: targetConnection)
        }
        
        transportToTargetQueue.async {
            self.transferTransportToTarget(transportConnection: transportConnection, targetConnection: targetConnection)
        }
        
        cleanupQueue.async {
            self.cleanup()
        }
    }
    
    func transferTargetToTransport(transportConnection: Transmission.Connection, targetConnection: Transmission.Connection)
    {
        while keepGoing
        {
            guard let dataFromTarget = targetConnection.read(maxSize: maxReadSize) else
            {
                appLog.debug("transferTargetToTransport: Received no data from the target on read.")
                keepGoing = false
                break
            }

            guard dataFromTarget.count > 0 else
            {
                appLog.error("transferTargetToTransport: 0 length data was read - this should not happen")
                keepGoing = false
                break
            }
                        
            guard transportConnection.write(data: dataFromTarget) else
            {
                appLog.debug("transferTargetToTransport: Unable to send target data to the transport connection. The connection was likely closed.")
                keepGoing = false
                break
            }
        }
        
        lock.signal()
    }
    
    func transferTransportToTarget(transportConnection: Transmission.Connection, targetConnection: Transmission.Connection)
    {
        while keepGoing
        {
            print("transferTransportToTarget: Attempting to read...")
            guard let dataFromTransport = transportConnection.read(maxSize: maxReadSize) else
            {
                appLog.debug("transferTransportToTarget: Received no data from the target on read.")
                keepGoing = false
                break
            }
            print("transferTransportToTarget: Finished reading.")
            
            guard dataFromTransport.count > 0 else
            {
                appLog.error("transferTransportToTarget: 0 length data was read - this should not happen")
                keepGoing = false
                break
            }
            
            guard targetConnection.write(data: dataFromTransport) else
            {
                appLog.debug("transferTransportToTarget: Unable to send target data to the target connection. The connection was likely closed.")
                keepGoing = false
                break
            }
        }
        
        lock.signal()
    }
    
    func cleanup()
    {
        lock.wait()
        
        print("Dispatcher Route cleaning up...")
        controller.remove(route: self)
        targetConnection.close()
        transportConnection.close()
    }
}

extension Router: Equatable
{
    static func == (lhs: Router, rhs: Router) -> Bool
    {
        return lhs.uuid == rhs.uuid
    }
}
