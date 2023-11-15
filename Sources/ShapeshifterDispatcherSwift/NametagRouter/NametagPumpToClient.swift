//
//  NametagPumpToClient.swift
//
//
//  Created by Mafalda on 10/31/23.
//

import Foundation

import TransmissionAsync
import TransmissionAsyncNametag


class NametagPumpToClient
{
    let targetToTransportQueue = DispatchQueue(label: "ShapeshifterDispatcherSwift.targetToTransportQueue")
    
    var router: NametagRouter
    
    
    init(router: NametagRouter)
    {
        self.router = router
        
        self.targetToTransportQueue.async 
        {
            Task 
            {
                print("NametagPumpToClient: calling transferTargetToTransport()")
                await self.transferTargetToTransport(transportConnection: router.clientConnection, targetConnection: router.targetConnection)
            }
        }
    }
    
    func transferTargetToTransport(transportConnection: AsyncNametagServerConnection, targetConnection: AsyncConnection) async
    {
        print("Target to Transport running...")
        
        
        while await router.state == .active
        {
            do
            {
                let dataFromTarget = try await targetConnection.readMaxSize(NametagRouter.maxReadSize)
                
                guard dataFromTarget.count > 0 else
                {
                    appLog.error("ShapeshifterDispatcherSwift: transferTargetToTransport: 0 length data was read - this should not happen")
                    await router.serverClosed()
                    break
                }
                            
                do
                {
                    try await transportConnection.network.write(dataFromTarget)
                }
                catch (let error)
                {
                    appLog.debug("ShapeshifterDispatcherSwift: transferTargetToTransport: Unable to send target data to the transport connection. The connection was likely closed. Error: \(error)")
                    await router.clientClosed()
                    break
                }
            }
            catch (let error)
            {
                appLog.debug("ShapeshifterDispatcherSwift: transferTargetToTransport: Received no data from the target on read. Error: \(error)")
                await router.serverClosed()
                break
            }
        }
        
        print("Server to client loop finished.")
    }
}
