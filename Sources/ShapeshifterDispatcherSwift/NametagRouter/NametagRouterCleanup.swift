//
//  NametagRouterCleanup.swift
//
//
//  Created by Mafalda on 10/31/23.
//

import Foundation

class NametagRouterCleanup
{
    var router: NametagRouter
    
    init(router: NametagRouter)
    {
        self.router = router
    }
    
    func cleanup() async
    {
        switch await router.state
        {
            case .closing:
                print("🧼 Route cleanup closing...")
                await router.clientConnection.network.close()
                await router.controller.remove(route: router)
                router.targetConnection.close()
                
            case .paused:
                print("🧼 Route cleanup paused...")
                await router.clientConnection.network.close()

            case .active:
                print("🧼 Route cleanup active, no cleanup needed.")
        }
    }
}
