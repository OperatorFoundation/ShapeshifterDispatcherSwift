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
    public let maxReadSize = 2048 // Could be tuned through testing in the future
    
    let transportConnection: Transmission.Connection
    let targetConnection: Transmission.Connection
    
    var targetToTransportTask: Task<(), Never>? = nil
    var transportToTargetTask: Task<(), Never>? = nil
    
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
        
        self.transportToTargetTask = Task
        {
            await self.transferTransportToTarget(transportConnection: transportConnection, targetConnection: targetConnection)
        }
        
        self.targetToTransportTask = Task
        {
            await self.transferTargetToTransport(transportConnection: transportConnection, targetConnection: targetConnection)
        }

    }
    
    func transferTargetToTransport(transportConnection: Transmission.Connection, targetConnection: Transmission.Connection) async
    {
        print("Target to Transport started")
        while keepGoing
        {
            print("Attempting to read from the target connection...")
            guard let dataFromTarget = targetConnection.read(maxSize: maxReadSize) else
            {
                appLog.error("Read from the target connection returned a nil result.")
                print("Read from the target connection returned a nil result.")
                keepGoing = false
                break
            }

            guard dataFromTarget.count > 0 else
            {
                appLog.error("Read 0 bytes from the target connection.")
                print("Read 0 bytes from the target connection.")
                keepGoing = false
                break
            }
            print("Read \(dataFromTarget.count) bytes from the target connection.")
            
            print("transferTargetToTransport: writing to the transport connection...")

            guard transportConnection.write(data: dataFromTarget) else
            {
                print("Failed to write to the transport connection.")
                appLog.debug("ShapeshifterDispatcherSwift: transferTargetToTransport: Unable to send target data to the transport connection. The connection was likely closed.")
                keepGoing = false
                break
            }
            
            print("Wrote \(dataFromTarget.count) bytes to the transport connection.")
            
            await Task.yield() // Take turns
        }
        
        self.lock.signal()
        print("Target to Transport loop finished.")
        self.cleanup()
    }
    
    func transferTransportToTarget(transportConnection: Transmission.Connection, targetConnection: Transmission.Connection) async
    {
        print("Transport to Target started")
        
        while keepGoing
        {
            print("transferTransportToTarget: Attempting to read from the client connection...")
            guard let dataFromTransport = transportConnection.read(maxSize: maxReadSize) else
            {
                appLog.error("Read from the transport connection returned a nil result.")
                print("Read from the target connection returned a nil result.")
                keepGoing = false
                break
            }
            
            guard dataFromTransport.count > 0 else
            {
                print("Read 0 bytes from the transport connection.")
                appLog.error("Read 0 bytes from the transport connection.")
                keepGoing = false
                break
            }
            
            print("Read \(dataFromTransport.count) bytes from the transport connection.")
            
            guard targetConnection.write(data: dataFromTransport) else
            {
                print("Failed to write to the target connection.")
                appLog.debug("Failed to write to the target connection.")
                keepGoing = false
                break
            }
            
            print("Wrote \(dataFromTransport.count) bytes to the target connection.")
            
            await Task.yield() // Take turns
        }
        
        self.lock.signal()
        
        print("Transport to Target loop finished.")
        
        self.cleanup()
    }
    
    func cleanup()
    {
        // Wait for both transferTransportToTarget() and transferTargetToTransport
        // to Signal before proceeding
        self.lock.wait()
        self.lock.wait()
        
        if !keepGoing
        {
            print("Route clean up...")
            Task
            {
                targetConnection.close()
                transportConnection.close()
                
                self.controller.remove(route: self)
                self.targetToTransportTask?.cancel()
                self.transportToTargetTask?.cancel()
                print("Route clean up finished.")
            }
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
