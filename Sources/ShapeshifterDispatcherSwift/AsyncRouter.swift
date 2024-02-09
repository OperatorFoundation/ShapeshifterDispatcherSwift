//
//  AsyncRouter.swift
//  
//
//  Created by Mafalda on 12/6/23.
//

import Foundation

import TransmissionAsync

class AsyncRouter
{
    public let maxReadSize = 2048 // Could be tuned through testing in the future
    
    let transportConnection: AsyncConnection
    let targetConnection: AsyncConnection
    
    var targetToTransportTask: Task<(), Never>? = nil
    var transportToTargetTask: Task<(), Never>? = nil
    
    let lock = DispatchSemaphore(value: 0)
    let controller: AsyncRoutingController
    let uuid = UUID()
    
    var keepGoing = true
    
    init(controller: AsyncRoutingController, transportConnection: AsyncConnection, targetConnection: AsyncConnection)
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
    
    func transferTargetToTransport(transportConnection: AsyncConnection, targetConnection: AsyncConnection) async
    {
        print("💙 Target to Transport started")
        while keepGoing
        {
            print("💙 Target to Transport: Attempting to read from the target connection...")
            do
            {
                let dataFromTarget = try await targetConnection.readMinMaxSize(1, maxReadSize)

                guard dataFromTarget.count > 0 else
                {
                    appLog.debug("\nAsyncRouter - Read 0 bytes from the target connection.")
                    continue
                }
                print("💙 Target to Transport: AsyncRouter - Read \(dataFromTarget.count) bytes from the target connection.")
                
                do
                {
                    try await transportConnection.write(dataFromTarget)
                }
                catch (let writeError)
                {
                    appLog.debug("ShapeshifterDispatcherSwift: transferTargetToTransport: Unable to send target data to the transport connection. The connection was likely closed. Error: \(writeError)")
                    print("💙 Target to Transport: exited because of a write failure")
                    keepGoing = false
                    break
                }
                
                print("💙 Target to Transport: Wrote \(dataFromTarget.count) bytes to the transport connection.\n")
            }
            catch (let readError)
            {
                appLog.debug("Failed to read from the target connection. Error: \(readError).\n")
                print("💙 Target to Transport: exited because of a read failure")
                keepGoing = false
                break
            }
            
            await Task.yield() // Take turns
        }
        
        self.lock.signal()
        print("💙 Target to Transport loop finished.")
        await self.cleanup()
    }
    
    func transferTransportToTarget(transportConnection: AsyncConnection, targetConnection: AsyncConnection) async
    {
        print("💜 Transport to Target started")
        
        while keepGoing
        {
            print("💜 Transport to Target: Attempting to read from the client connection...")
            do
            {
                let dataFromTransport = try await transportConnection.readMinMaxSize(1, maxReadSize)
                
                guard dataFromTransport.count > 0 else
                {
                    appLog.error("\nRead 0 bytes from the transport connection.")
                    continue
                }
                
                print("💜 Transport to Target: Read \(dataFromTransport.count) bytes from the transport connection.")
                
                do
                {
                    try await targetConnection.write(dataFromTransport)
                }
                catch (let writeError)
                {
                    appLog.error("Failed to write to the target connection. Error: \(writeError)")
                    print("💜 Transport to Target: exited because of a write failure")
                    keepGoing = false
                    break
                }
                
                print("💜 Transport to Target: Wrote \(dataFromTransport.count) bytes to the target connection.\n")
            }
            catch (let readError)
            {
                appLog.error("Failed to read from the transport connection. Error: \(readError)\n")
                print("💜 Transport to Target: exited because of a read failure")
                keepGoing = false
                break
            }
            
            await Task.yield() // Take turns
        }
        
        self.lock.signal()
        print("💜 Transport to Target loop finished.")
        await self.cleanup()
    }
    
    func cleanup() async
    {
        await self.transportToTargetTask?.value
        
        if !keepGoing
        {
            print("Route clean up...")
            do
            {
                try await targetConnection.close()
                try await transportConnection.close()
            }
            catch (let closeError)
            {
                print("Received an error while trying to close a connection: \(closeError)")
            }
            
            self.controller.remove(route: self)
            self.targetToTransportTask?.cancel()
            self.transportToTargetTask?.cancel()
            print("Route clean up finished.")
        }
    }
}

extension AsyncRouter: Equatable
{
    static func == (lhs: AsyncRouter, rhs: AsyncRouter) -> Bool
    {
        return lhs.uuid == rhs.uuid
    }
}
