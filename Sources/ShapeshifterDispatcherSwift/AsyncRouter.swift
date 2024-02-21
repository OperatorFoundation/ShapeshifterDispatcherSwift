//
//  AsyncRouter.swift
//  
//
//  Created by Mafalda on 12/6/23.
//

import Foundation

import Chord
import Straw
import TransmissionAsync

class AsyncRouter
{
    public let maxReadSize = 2048 // Could be tuned through testing in the future
    
    let transportConnection: AsyncConnection
    let targetConnection: AsyncConnection
    let batchBuffer = SynchronizedStraw()
    let lock = DispatchSemaphore(value: 0)
    let controller: AsyncRoutingController
    let uuid = UUID()
    
    var targetToBatchBuffer: Task<(), Never>? = nil
    var batchBufferToTransportTask: Task<(), Never>? = nil
    var transportToTargetTask: Task<(), Never>? = nil
    var keepGoing = true
    
    init(controller: AsyncRoutingController, transportConnection: AsyncConnection, targetConnection: AsyncConnection)
    {
        self.controller = controller
        self.transportConnection = transportConnection
        self.targetConnection = targetConnection
        
        appLog.debug("ShapeshifterDispatcherSwift: Router Received a new connection")
        
        self.transportToTargetTask = Task
        {
            await self.transferTransportToTarget()
        }

        self.targetToBatchBuffer = Task
        {
            await self.transferTargetToBatchBuffer()
        }
        
        self.batchBufferToTransportTask = Task
        {
            await self.transferBatchBufferToTransport()
        }
        
        Task
        {
            await self.cleanup()
        }

    }
    
    func transferTargetToBatchBuffer() async
    {
        while keepGoing
        {
            appLog.debug("💙 Target to Buffer: Attempting to read from the target connection...")
            do
            {
                let dataFromTarget = try await targetConnection.readMinMaxSize(1, maxReadSize)

                guard dataFromTarget.count > 0 else
                {
                    appLog.debug("\nAsyncRouter - Read 0 bytes from the target connection.")
                    continue
                }
                appLog.debug("💙 Target to Buffer: AsyncRouter - Read \(dataFromTarget.count) bytes from the target connection.")
                
                batchBuffer.write(dataFromTarget)
            }
            catch (let readError)
            {
                appLog.debug("Failed to read from the target connection. Error: \(readError).\n")
                keepGoing = false
                break
            }
            
            await Task.yield() // Take turns
        }
        
        self.lock.signal()
    }
    
    func transferBatchBufferToTransport() async
    {
        appLog.debug("🩵 Buffer to Transport started")
        
        
        let maxBatchSize =  250 // bytes
        let timeoutDuration: TimeInterval = 250 / 1000 // 250 milliseconds in seconds
        var timeToSleep = 1 // In milliseconds
        var lastPacketSentTime = Date() // now

        while keepGoing
        {
            let bufferSize = batchBuffer.count()

            if bufferSize > 0
            {
                var batchReady = false
                
                if bufferSize >= maxBatchSize
                {
                    batchReady = true
                }
                else
                {
                    print("🩵 Buffer to Transport buffer: 🍪‼️ Our batch is not big enough \(bufferSize) bytes in buffer, but we need \(maxBatchSize) bytes.")
                }
                
                let timeElapsed = Date().timeIntervalSince1970 - lastPacketSentTime.timeIntervalSince1970
                if  timeElapsed >= timeoutDuration
                {
                    batchReady = true
                }
                else
                {
                    print("🩵 Buffer to Transport buffer: 🍪‼️ The time elapsed \(timeElapsed) is not more than the timeout duration of \(timeoutDuration)")
                }
                
                if batchReady
                {
                    print("🩵 Buffer to Transport buffer size is \(batchBuffer.count()) bytes.")
                    let bufferData = batchBuffer.read()
                    print("🩵 Buffer to Transport buffer read \(bufferData.count) bytes from the buffer")
                    
                    do
                    {
                        try await transportConnection.write(bufferData)
                        print("🩵 Buffer to Transport buffer wrote \(bufferData.count) bytes to the transport connection")
                        lastPacketSentTime = Date()
                        timeToSleep = 1
                    }
                    catch (let writeError)
                    {
                        appLog.debug("🩵‼️ Buffer to Transport: Unable to send target data to the transport connection. The connection was likely closed. Error: \(writeError)")
                        keepGoing = false
                        break
                    }
                }
            }
            else
            {
                try? await Task.sleep(for: .milliseconds(timeToSleep))
                if timeToSleep < 1000
                {
                    timeToSleep = timeToSleep * 2
                }
            }
            
            await Task.yield() // Take turns
        }
        
        self.lock.signal()
    }
    
    func transferTransportToTarget() async
    {
        appLog.debug("💜 Transport to Target started")
        
        while keepGoing
        {
            appLog.debug("💜 Transport to Target: Attempting to read from the client connection...")
            do
            {
                let dataFromTransport = try await transportConnection.readMinMaxSize(1, maxReadSize)
                
                guard dataFromTransport.count > 0 else
                {
                    appLog.warning("\nRead 0 bytes from the transport connection.")
                    continue
                }
                
                appLog.debug("💜 Transport to Target: Read \(dataFromTransport.count) bytes from the transport connection.")
                
                do
                {
                    try await targetConnection.write(dataFromTransport)
                }
                catch (let writeError)
                {
                    appLog.error("💔 Failed to write to the target connection. Error: \(writeError)")
                    keepGoing = false
                    break
                }
                
                appLog.debug("💜 Transport to Target: Wrote \(dataFromTransport.count) bytes to the target connection.\n")
            }
            catch (let readError)
            {
                appLog.info("💔 Failed to read from the transport connection. Error: \(readError)\n")
                keepGoing = false
                break
            }
            
            await Task.yield() // Take turns
        }
        
        self.lock.signal()
    }
    
    func cleanup() async
    {
        await self.transportToTargetTask?.value
        
        if !keepGoing
        {
            appLog.debug("Route clean up...")
            do
            {
                try await targetConnection.close()
                try await transportConnection.close()
            }
            catch (let closeError)
            {
                appLog.warning("Received an error while trying to close a connection: \(closeError)")
            }
            
            self.controller.remove(route: self)
            self.targetToBatchBuffer?.cancel()
            self.batchBufferToTransportTask?.cancel()
            self.transportToTargetTask?.cancel()
            appLog.debug("Route clean up finished.")
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
