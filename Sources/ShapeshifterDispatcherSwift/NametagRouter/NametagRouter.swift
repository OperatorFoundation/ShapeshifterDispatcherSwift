//
//  NametagRouter.swift
//  
//
//  Created by Mafalda on 10/26/23.
//

import Foundation

import Transmission
import TransmissionNametag

actor NametagRouter
{
    static let maxReadSize = 2048 // Could be tuned through testing in the future
    let uuid = UUID()
    
    var cleaner: NametagRouterCleanup? = nil
    var serverPump: NametagPumpToServer? = nil
    var clientPump: NametagPumpToClient? = nil
    var connectionReaper: NametagConnectionReaper? = nil
    
    
    // MARK: Shared State
    
    var clientConnection: NametagServerConnection
    let targetConnection: Transmission.Connection
    let controller: NametagRoutingController
    var clientConnectionCount = 1
    var state: NametagRouterState = .active
    
    // MARK: End Shared State
    
    init(controller: NametagRoutingController, transportConnection: NametagServerConnection, targetConnection: Transmission.Connection) async
    {
        self.controller = controller
        self.clientConnection = transportConnection
        self.targetConnection = targetConnection

        self.cleaner = NametagRouterCleanup(router: self)
        self.serverPump = NametagPumpToServer(router: self)
        self.clientPump = NametagPumpToClient(router: self)
    }
    
    func clientConnected(connection: NametagServerConnection) async throws
    {
        switch state 
        {
            case .closing:
                print("ERROR: Currently closing new connections cannot be accepted.")
                connection.network.close()
                self.state = .closing
                throw NametagRouterError.connectionWhileClosing
                
            case .paused:
                self.clientConnection = connection
                self.state = .active
                self.connectionReaper = nil
                
            case .active:
                connection.network.close()
                self.state = .closing
                throw NametagRouterError.connectionWhileActive
        }
    }
    
    func clientClosed() async
    {
        switch state 
        {
            case .closing:
                state = .closing
            case .paused:
                state = .paused
            case .active:
                state = .paused
                self.connectionReaper = await NametagConnectionReaper(router: self)
        }
        
        await cleaner?.cleanup()
    }
    
    func serverClosed() async
    {
        state = .closing
        await cleaner?.cleanup()
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
