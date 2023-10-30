//
//  NametagRouter.swift
//  
//
//  Created by Mafalda on 10/26/23.
//

import Foundation

import Transmission
import TransmissionNametag

class NametagRouter
{
    let maxReadSize = 2048 // Could be tuned through testing in the future
    
    var clientConnection: NametagServerConnection
    let targetConnection: Transmission.Connection
    
    var clientConnectionIsActive: Bool
    
    let targetToTransportQueue = DispatchQueue(label: "ShapeshifterDispatcherSwift.targetToTransportQueue")
    let transportToTargetQueue = DispatchQueue(label: "ShapeshifterDispatcherSwift.transportToTargetQueue")
    let cleanupQueue = DispatchQueue(label: "ShapeshifterDispatcherSwift.cleanupQueue")
    
    let lock = DispatchSemaphore(value: 0)
    let controller: NametagRoutingController
    let uuid = UUID()
    
    var keepGoing = true
    
    init(controller: NametagRoutingController, transportConnection: NametagServerConnection, targetConnection: Transmission.Connection)
    {
        self.controller = controller
        self.clientConnection = transportConnection
        self.clientConnectionIsActive = true
        self.targetConnection = targetConnection
        
        print("ShapeshifterDispatcherSwift: Router Received a new connection")

        self.targetToTransportQueue.async {
            self.transferTargetToTransport(transportConnection: transportConnection, targetConnection: targetConnection)
        }
        
        self.transportToTargetQueue.async {
            self.transferTransportToTarget(transportConnection: transportConnection, targetConnection: targetConnection)
        }
    }
    
    func transferTargetToTransport(transportConnection: NametagServerConnection, targetConnection: Transmission.Connection)
    {
        var connectionFinished = true
        print("Target to Transport running...")
        
        while keepGoing
        {
            guard let dataFromTarget = targetConnection.read(maxSize: maxReadSize) else
            {
                appLog.debug("ShapeshifterDispatcherSwift: transferTargetToTransport: Received no data from the target on read.")
                keepGoing = false
                connectionFinished = true
                break
            }

            guard dataFromTarget.count > 0 else
            {
                appLog.error("ShapeshifterDispatcherSwift: transferTargetToTransport: 0 length data was read - this should not happen")
                keepGoing = false
                connectionFinished = true
                break
            }
                        
            guard transportConnection.network.write(data: dataFromTarget) else
            {
                appLog.debug("ShapeshifterDispatcherSwift: transferTargetToTransport: Unable to send target data to the transport connection. The connection was likely closed.")
                keepGoing = false
                connectionFinished = false
                break
            }
        }
        
        self.lock.signal()
        
        print("Target to Transport finished!")
        
        self.cleanup(connectionFinished: connectionFinished)
    }
    
    func transferTransportToTarget(transportConnection: NametagServerConnection, targetConnection: Transmission.Connection)
    {
        var connectionFinished = true
        print("Transport to Target running...")
        
        while keepGoing
        {
            print("transferTransportToTarget: Attempting to read...")
            guard let dataFromTransport = transportConnection.network.read(maxSize: maxReadSize) else
            {
                appLog.debug("ShapeshifterDispatcherSwift: transferTransportToTarget: Received no data from the target on read.")
                keepGoing = false
                connectionFinished = false
                break
            }
            
            print("transferTransportToTarget: Finished reading.")
            
            guard dataFromTransport.count > 0 else
            {
                appLog.error("ShapeshifterDispatcherSwift: transferTransportToTarget: 0 length data was read - this should not happen")
                keepGoing = false
                connectionFinished = false
                break
            }
            
            guard targetConnection.write(data: dataFromTransport) else
            {
                appLog.debug("ShapeshifterDispatcherSwift: transferTransportToTarget: Unable to send target data to the target connection. The connection was likely closed.")
                keepGoing = false
                connectionFinished = true
                break
            }
        }
        
        self.lock.signal()
        
        print("Transport to Target finished!")
        
        self.cleanup(connectionFinished: connectionFinished)
    }
    
    func cleanup(connectionFinished: Bool)
    {
        self.lock.wait()
        
        if !keepGoing
        {
            print("Route clean up...")
            self.clientConnection.network.close()
            self.clientConnectionIsActive = false
            
            if connectionFinished
            {
                print("Connection is finished, closing target connection too.")
                self.controller.remove(route: self)
                self.targetConnection.close()
            }
            
            print("Route clean up finished.")
        }
    }
    
}

extension NametagRouter: Equatable
{
    static func == (lhs: NametagRouter, rhs: NametagRouter) -> Bool
    {
        return lhs.uuid == rhs.uuid
    }
}
