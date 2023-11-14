//
//  NametagPumpToClient.swift
//
//
//  Created by Mafalda on 10/31/23.
//

import Foundation

import Transmission
import TransmissionNametag


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
    
    func transferTargetToTransport(transportConnection: NametagServerConnection, targetConnection: Transmission.Connection) async
    {
        print("Target to Transport running...")
        
        
        while await router.state == .active
        {
            guard let dataFromTarget = targetConnection.read(maxSize: NametagRouter.maxReadSize) else
            {
                appLog.debug("ShapeshifterDispatcherSwift: transferTargetToTransport: Received no data from the target on read.")
                await router.serverClosed()
                break
            }

            guard dataFromTarget.count > 0 else
            {
                appLog.error("ShapeshifterDispatcherSwift: transferTargetToTransport: 0 length data was read - this should not happen")
                await router.serverClosed()
                break
            }
                        
            guard transportConnection.network.write(data: dataFromTarget) else
            {
                appLog.debug("ShapeshifterDispatcherSwift: transferTargetToTransport: Unable to send target data to the transport connection. The connection was likely closed.")
                await router.clientClosed()
                break
            }
        }
        
        print("Server to client loop finished.")
    }
}
