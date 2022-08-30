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
        print("ShapeshifterDispatcherSwift: RoutingController.handleListener()")
        
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

class Router
{
    let maxReadSize = 2048 // Could be tuned through testing in the future
    
    let transportConnection: Transmission.Connection
    let targetConnection: Transmission.Connection
    
    let targetToTransportQueue = DispatchQueue(label: "ShapeshifterDispatcherSwift.targetToTransportQueue")
    let transportToTargetQueue = DispatchQueue(label: "ShapeshifterDispatcherSwift.transportToTargetQueue")
    let cleanupQueue = DispatchQueue(label: "ShapeshifterDispatcherSwift.cleanupQueue")
    
    let lock = DispatchSemaphore(value: 2)
    let controller: RoutingController
    let uuid = UUID()
    
    var keepGoing = true
    var transportToTargetComplete = false
    var targetToTransportComplete = false
    
    init(controller: RoutingController, transportConnection: Transmission.Connection, targetConnection: Transmission.Connection)
    {
        self.controller = controller
        self.transportConnection = transportConnection
        self.targetConnection = targetConnection
        
        print("ShapeshifterDispatcherSwift: Router Received a new connection")

        targetToTransportQueue.async {
            self.transferTargetToTransport(transportConnection: transportConnection, targetConnection: targetConnection)
        }
        
        transportToTargetQueue.async {
            self.transferTransportToTarget(transportConnection: transportConnection, targetConnection: targetConnection)
        }
                
//        cleanupQueue.async {
//            self.cleanup()
//        }
    }
    
    func transferTargetToTransport(transportConnection: Transmission.Connection, targetConnection: Transmission.Connection)
    {
        lock.wait()
        
        print("Target to Transport running...")
        while keepGoing
        {
            guard let dataFromTarget = targetConnection.read(maxSize: maxReadSize) else
            {
                appLog.debug("ShapeshifterDispatcherSwift: transferTargetToTransport: Received no data from the target on read.")
                keepGoing = false
                break
            }

            guard dataFromTarget.count > 0 else
            {
                appLog.error("ShapeshifterDispatcherSwift: transferTargetToTransport: 0 length data was read - this should not happen")
                keepGoing = false
                break
            }
                        
            guard transportConnection.write(data: dataFromTarget) else
            {
                appLog.debug("ShapeshifterDispatcherSwift: transferTargetToTransport: Unable to send target data to the transport connection. The connection was likely closed.")
                keepGoing = false
                break
            }
        }
        
        lock.signal()
        targetToTransportComplete = true
        print("Target to Transport finished!")
        cleanup()
    }
    
    func transferTransportToTarget(transportConnection: Transmission.Connection, targetConnection: Transmission.Connection)
    {
        lock.wait()
        
        print("Transport to Target running...")
        
        while keepGoing
        {
            print("transferTransportToTarget: Attempting to read...")
            guard let dataFromTransport = transportConnection.read(maxSize: maxReadSize) else
            {
                appLog.debug("ShapeshifterDispatcherSwift: transferTransportToTarget: Received no data from the target on read.")
                keepGoing = false
                break
            }
            print("transferTransportToTarget: Finished reading.")
            
            guard dataFromTransport.count > 0 else
            {
                appLog.error("ShapeshifterDispatcherSwift: transferTransportToTarget: 0 length data was read - this should not happen")
                keepGoing = false
                break
            }
            
            guard targetConnection.write(data: dataFromTransport) else
            {
                appLog.debug("ShapeshifterDispatcherSwift: transferTransportToTarget: Unable to send target data to the target connection. The connection was likely closed.")
                keepGoing = false
                break
            }
        }
        
        lock.signal()
        
        print("Transport to Target finished!")
        transportToTargetComplete = true
        cleanup()
    }
    
    func cleanup()
    {
        if !keepGoing, transportToTargetComplete, targetToTransportComplete
        {
            print("Route clean up...")
            self.controller.remove(route: self)
            self.targetConnection.close()
            self.transportConnection.close()
            print("Route clean up finished.")
        }
    }
}

extension Router: Equatable
{
    static func == (lhs: Router, rhs: Router) -> Bool
    {
        return lhs.uuid == rhs.uuid
    }
}
