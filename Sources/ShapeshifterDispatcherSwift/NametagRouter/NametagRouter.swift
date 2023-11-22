//
//  NametagRouter.swift
//  
//
//  Created by Mafalda on 10/26/23.
//

import Foundation

import TransmissionAsync
import TransmissionAsyncNametag

actor NametagRouter
{
    static let maxReadSize = 2048 // Could be tuned through testing in the future
    let uuid = UUID()
    
    var cleaner: NametagRouterCleanup? = nil
    var serverPump: NametagPumpToServer? = nil
    var clientPump: NametagPumpToClient? = nil
    var connectionReaper: NametagConnectionReaper? = nil
    
    
    // MARK: Shared State
    
    var clientConnection: AsyncNametagServerConnection
    let targetConnection: AsyncConnection
    let controller: NametagRoutingController
    var clientConnectionCount = 1
    var state: NametagRouterState = .active
    var bufferedDataForClient: Data? = nil
    
    // MARK: End Shared State
    
    init(controller: NametagRoutingController, transportConnection: AsyncNametagServerConnection, targetConnection: AsyncConnection, buffer: Data? = nil) async
    {
        self.controller = controller
        self.clientConnection = transportConnection
        self.targetConnection = targetConnection
        self.bufferedDataForClient = buffer

        self.cleaner = NametagRouterCleanup(router: self)
        self.serverPump = NametagPumpToServer(router: self)
        self.clientPump = NametagPumpToClient(router: self)
    }
    
    func clientConnected(connection: AsyncNametagServerConnection) async throws
    {
        switch state 
        {
            case .closing:
                print("ERROR: Currently closing new connections cannot be accepted.")
                self.state = .closing
                try await connection.network.close()
                throw NametagRouterError.connectionWhileClosing
                
            case .paused:
                self.clientConnection = connection
                self.state = .active
                self.connectionReaper = nil
                
            case .active:
                self.state = .closing
                try await connection.network.close()
                throw NametagRouterError.connectionWhileActive
        }
    }
    
    func clientClosed() async
    {
        print("NametagRouter: clientClosed() called.")
        switch state
        {
            case .closing:
                state = .closing
            case .paused:
                state = .paused
            case .active:
                state = .paused
//                self.connectionReaper = await NametagConnectionReaper(router: self)
        }
        
        guard let cleaner = cleaner else
        {
            print("Trying to cleanup but the cleaner is nil!")
            return
        }
        
        await cleaner.cleanup()
    }
    
    func serverClosed() async
    {
        print("NametagRouter: serverClosed() called.")
        state = .closing
        
        guard let cleaner = cleaner else
        {
            print("Trying to cleanup but the cleaner is nil!")
            return
        }
        
        await cleaner.cleanup()
    }
    
    func updateBuffer(data: Data?)
    {
        self.bufferedDataForClient = data
    }
}

extension NametagRouter: Equatable
{
    static func == (lhs: NametagRouter, rhs: NametagRouter) -> Bool
    {
        return lhs.uuid == rhs.uuid
    }
}

enum NametagRouterState
{
    case closing
    case paused
    case active
}

public enum NametagRouterError: Error
{
    case connectionWhileClosing
    case connectionWhileActive
    
    var description: String
    {
        switch self 
        {
            case .connectionWhileClosing:
                return "ERROR: Currently closing new connections cannot be accepted."
            case .connectionWhileActive:
                return "ERROR: Received a new client connection while a client connection to this target is already active."
        }
    }
}
