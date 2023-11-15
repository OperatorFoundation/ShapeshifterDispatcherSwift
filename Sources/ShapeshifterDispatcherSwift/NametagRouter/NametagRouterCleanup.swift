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
                
                do
                {
                    try await router.clientConnection.network.close()
                }
                catch (let error)
                {
                    print("Received an error while trying to close a client connection: \(error)")
                }
                
                await router.controller.remove(route: router)
                
                do
                {
                    try await router.targetConnection.close()
                }
                catch (let error)
                {
                    print("Received an error while trying to close a target connection: \(error)")
                }
                
            case .paused:
                print("🧼 Route cleanup paused...")
                do
                {
                    try await router.clientConnection.network.close()
                }
                catch (let error)
                {
                    print("Received an error while trying to close a client connection: \(error)")
                }

            case .active:
                print("🧼 Route cleanup active, no cleanup needed.")
        }
    }
}
