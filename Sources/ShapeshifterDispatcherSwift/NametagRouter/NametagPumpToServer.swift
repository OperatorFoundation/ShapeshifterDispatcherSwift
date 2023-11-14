//
//  NametagPumpToServer.swift
//
//
//  Created by Mafalda on 10/31/23.
//

import Foundation

import Transmission
import TransmissionNametag

class NametagPumpToServer
{
    let transportToTargetQueue = DispatchQueue(label: "ShapeshifterDispatcherSwift.transportToTargetQueue")
    
    var router: NametagRouter
    
    
    init(router: NametagRouter)
    {
        self.router = router
        
        self.transportToTargetQueue.async 
        {
            Task
            {
                print("NametagPumpToServer: calling transferTransportToTarget()")
                await self.transferTransportToTarget(transportConnection: router.clientConnection, targetConnection: router.targetConnection)
            }
        }
    }
    
    func transferTransportToTarget(transportConnection: NametagServerConnection, targetConnection: Transmission.Connection) async
    {
        print("Transport to Target running...")
        
        while await router.state == .active
        {
            print("transferTransportToTarget: Attempting to read...")
            guard let dataFromTransport = transportConnection.network.read(maxSize: NametagRouter.maxReadSize) else
            {
                appLog.debug("ShapeshifterDispatcherSwift: transferTransportToTarget: Received no data from the target on read.")
                await router.clientClosed()
                break
            }
            
            print("transferTransportToTarget: Finished reading.")
            
            guard dataFromTransport.count > 0 else
            {
                appLog.error("ShapeshifterDispatcherSwift: transferTransportToTarget: 0 length data was read - this should not happen")
                await router.clientClosed()
                break
            }
            
            guard targetConnection.write(data: dataFromTransport) else
            {
                appLog.debug("ShapeshifterDispatcherSwift: transferTransportToTarget: Unable to send target data to the target connection. The connection was likely closed.")
                await router.serverClosed()
                break
            }
        }
    }
}
