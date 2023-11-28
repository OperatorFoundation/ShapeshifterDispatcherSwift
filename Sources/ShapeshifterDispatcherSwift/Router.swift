//
//  Router.swift
//
//
//  Created by Mafalda on 10/26/23.
//

import Foundation

import Transmission

class Router
{
    let maxReadSize = 2048 // Could be tuned through testing in the future
    
    let transportConnection: Transmission.Connection
    let targetConnection: Transmission.Connection
    
    let targetToTransportQueue = DispatchQueue(label: "ShapeshifterDispatcherSwift.targetToTransportQueue")
    let transportToTargetQueue = DispatchQueue(label: "ShapeshifterDispatcherSwift.transportToTargetQueue")
    let cleanupQueue = DispatchQueue(label: "ShapeshifterDispatcherSwift.cleanupQueue")
    
    let lock = DispatchSemaphore(value: 0)
    let controller: RoutingController
    let uuid = UUID()
    
    var keepGoing = true
    
    init(controller: RoutingController, transportConnection: Transmission.Connection, targetConnection: Transmission.Connection)
    {
        self.controller = controller
        self.transportConnection = transportConnection
        self.targetConnection = targetConnection
        
        print("ShapeshifterDispatcherSwift: Router Received a new connection")

        self.targetToTransportQueue.async {
            self.transferTargetToTransport(transportConnection: transportConnection, targetConnection: targetConnection)
        }
        
        self.transportToTargetQueue.async {
            self.transferTransportToTarget(transportConnection: transportConnection, targetConnection: targetConnection)
        }
    }
    
    func transferTargetToTransport(transportConnection: Transmission.Connection, targetConnection: Transmission.Connection)
    {
        print("Target to Transport started")
        while keepGoing
        {
            print("transferTargetToTransport: Attempting to read from the target connection...")
            
            guard let dataFromTarget = targetConnection.read(maxSize: maxReadSize) else
            {
                appLog.debug("ShapeshifterDispatcherSwift: transferTargetToTransport: Received no data from the target on read.")
                keepGoing = false
                break
            }
            
            print("transferTargetToTransport: read \(dataFromTarget.count) bytes")

            guard dataFromTarget.count > 0 else
            {
                appLog.error("ShapeshifterDispatcherSwift: transferTargetToTransport: 0 length data was read - this should not happen")
                keepGoing = false
                break
            }
            
            print("transferTargetToTransport: writing to the transport connection...")
            guard transportConnection.write(data: dataFromTarget) else
            {
                appLog.debug("ShapeshifterDispatcherSwift: transferTargetToTransport: Unable to send target data to the transport connection. The connection was likely closed.")
                keepGoing = false
                break
            }
            
            print("transferTargetToTransport: wrote \(dataFromTarget.count) bytes to the transport connection.")
        }
        
        self.lock.signal()
        
        print("Target to Transport finished!")
        
        self.cleanup()
    }
    
    func transferTransportToTarget(transportConnection: Transmission.Connection, targetConnection: Transmission.Connection)
    {
        print("Transport to Target started")
        
        while keepGoing
        {
            print("transferTransportToTarget: Attempting to read from the client connection...")
            guard let dataFromTransport = transportConnection.read(maxSize: maxReadSize) else
            {
                appLog.debug("ShapeshifterDispatcherSwift: transferTransportToTarget: Received no data from the client on read.")
                keepGoing = false
                break
            }
            
            print("transferTransportToTarget: read \(dataFromTransport.count) bytes")
            
            guard dataFromTransport.count > 0 else
            {
                appLog.error("ShapeshifterDispatcherSwift: transferTransportToTarget: 0 length data was read - this should not happen")
                keepGoing = false
                break
            }
            
            print("transferTransportToTarget: writing to the target connection...")
            guard targetConnection.write(data: dataFromTransport) else
            {
                appLog.debug("ShapeshifterDispatcherSwift: transferTransportToTarget: Unable to send target data to the target connection. The connection was likely closed.")
                keepGoing = false
                
                break
            }
            
            print("transferTransportToTarget: wrote \(dataFromTransport.count) bytes to the target connection.")
        }
        
        self.lock.signal()
        
        print("Transport to Target finished!")
        
        self.cleanup()
    }
    
    func cleanup()
    {
        // Wait for both transferTransportToTarget() and transferTargetToTransport
        // to Signal before proceding
        self.lock.wait()
        self.lock.wait()
        
        if !keepGoing
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
