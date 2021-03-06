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
        while true
        {
            do
            {
                let transportConnection = try listener.accept()
                
                guard let targetConnection = TransmissionConnection(host: targetHost, port: targetPort) else
                {
                    print("ShapeshifterDispatcher.handleListener: Failed to connect to the target server.")
                    appLog.error("Failed to connect to the application server.")
                    listener.close()
                    continue
                }
                
                print("Received a new connection 🌷")
                let targetToTransportQueue = DispatchQueue(label: "targetToTransportQueue")
                let transportToTargetQueue = DispatchQueue(label: "transportToTargetQueue")
                
                targetToTransportQueue.async {
                    self.transferTargetToTransport(transportConnection: transportConnection, targetConnection: targetConnection)
                }
                
                transportToTargetQueue.async {
                    self.transferTransportToTarget(transportConnection: transportConnection, targetConnection: targetConnection)
                }
            }
            catch
            {
                print("ShapeshifterDispatcher.handleListener: Failed to accept a new connection: \(error).")
                appLog.error("Failed to accept a new connection: \(error)")
                continue
            }
        }
    }
    
    func transferTargetToTransport(transportConnection: Transmission.Connection, targetConnection: Transmission.Connection)
    {
        while true
        {
            guard let dataFromTarget = targetConnection.read(maxSize: maxReadSize) else
            {
                appLog.debug("transferTargetToTransport: Received no data from the target on read.")
                return
            }

            guard dataFromTarget.count > 0 else
            {
                appLog.error("transferTargetToTransport: 0 length data was read - this should not happen")
                return
            }
                        
            guard transportConnection.write(data: dataFromTarget) else
            {
                appLog.debug("transferTargetToTransport: Unable to send target data to the transport connection. The connection was likely closed.")
                return
            }
        }
    }
    
    func transferTransportToTarget(transportConnection: Transmission.Connection, targetConnection: Transmission.Connection)
    {
        while true
        {
            print("transferTransportToTarget: Attempting to read...")
            guard let dataFromTransport = transportConnection.read(maxSize: maxReadSize) else
            {
                appLog.debug("transferTransportToTarget: Received no data from the target on read.")
                return
            }
            print("transferTransportToTarget: Finished reading.")
            
            guard dataFromTransport.count > 0 else
            {
                appLog.error("transferTransportToTarget: 0 length data was read - this should not happen")
                return
            }
            
            guard targetConnection.write(data: dataFromTransport) else
            {
                appLog.debug("transferTransportToTarget: Unable to send target data to the target connection. The connection was likely closed.")
                return
            }
        }
    }
}
