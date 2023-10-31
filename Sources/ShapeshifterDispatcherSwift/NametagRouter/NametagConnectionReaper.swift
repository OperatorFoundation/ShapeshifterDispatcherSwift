//
//  NametagConnectionReaper.swift
//
//
//  Created by Mafalda on 10/31/23.
//

import Foundation

class NametagConnectionReaper
{
    static let clientConnectionTimeout = 60.0 // Seconds
    let cleanupQueue = DispatchQueue(label: "ShapeshifterDispatcherSwift.cleanupQueue")
    
    var router: NametagRouter
    
    
    
    init(router: NametagRouter) async
    {
        self.router = router
        
        self.cleanupQueue.async
        {
            Task
            {
                let lastConnectionCount = await router.clientConnectionCount
                sleep(UInt32(NametagConnectionReaper.clientConnectionTimeout))
                
                if await router.clientConnectionCount == lastConnectionCount
                {
                    print("⏰ Client connection has been paused for more than \(NametagConnectionReaper.clientConnectionTimeout). Closing this connection.")
                    
                    await self.router.serverClosed()
                }
            }
        }
    }
}
