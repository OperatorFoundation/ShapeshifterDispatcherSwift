//
//  RoutingController.swift
//  ShapeshifterDispatcherSwift
//
//  Created by Mafalda on 3/8/22.
//

import Foundation

import Transmission

class RoutingController
{
    // Could be tuned through testing in the future
    let maxReadSize = 2048
    
    func handleListener(listener: Transmission.Listener, targetHost: String, targetPort: Int)
    {
        let targetToTransportQueue = DispatchQueue(label: "targetToTransportQueue")
        let transportToTargetQueue = DispatchQueue(label: "transportToTargetQueue")
        
        while true
        {
            do
            {
                let transportConnection = try listener.accept()
                
                guard let targetConnection = TransmissionConnection(host: targetHost, port: targetPort) else
                {
                    // TODO: close the replicant connection
                    // TODO: log error that we failed to connect to the application server
                    continue
                }
                
                targetToTransportQueue.async {
                    self.transferTargetToTransport(transportConnection: transportConnection, targetConnection: targetConnection)
                }
                
                transportToTargetQueue.async {
                    self.transferTransportToTarget(transportConnection: transportConnection, targetConnection: targetConnection)
                }
            }
            catch
            {
                
                appLog.error("Failed to accept new connections.")
                return
            }
        }
    }
    
    func transferTargetToTransport(transportConnection: Transmission.Connection, targetConnection: Transmission.Connection)
    {
        while true
        {
            guard let dataFromTarget = targetConnection.read(maxSize: 2048) else
            {
                appLog.debug("Received no data from the target on read.")
                return
            }
            
            guard transportConnection.write(data: dataFromTarget) else
            {
                appLog.debug("Unable to send target data to the transport connection. The connection was likely closed.")
                return
            }
        }
    }
    
    func transferTransportToTarget(transportConnection: Transmission.Connection, targetConnection: Transmission.Connection)
    {
        while true
        {
            guard let dataFromTransport = transportConnection.read(maxSize: 2048) else
            {
                appLog.debug("Received no data from the target on read.")
                return
            }
            
            guard targetConnection.write(data: dataFromTransport) else
            {
                appLog.debug("Unable to send target data to the target connection. The connection was likely closed.")
                return
            }
        }
    }
}