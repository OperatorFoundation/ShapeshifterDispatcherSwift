//
//  main.swift
//  ShapeshifterDispatcherSwift
//
//  Created by Mafalda on 2/18/22.
//

import ArgumentParser
import Foundation
#if os(macOS) || os(iOS)
import os.log
#else
import Logging
#endif

import ShadowSwift

let supportedPTVersion = "3.0"
#if os(macOS) || os(iOS)
var appLog = Logger(subsystem: "ShapeshifterDispatcherSwift", category: "main")
#else
var appLog = Logger(label: "ShapeshifterDispatcherSwift")
#endif

// TODO: Refactor to use the exact arguments that dispatcher needs according to the spec
struct ShapeshifterDispatcher: ParsableCommand
{
    
    /** -ptversion
     Specifies the versions of the Pluggable Transport specification the parent process supports, delimited by commas. All PTs MUST accept any well-formed list, as long as a compatible version is present.
     
     Valid versions MUST consist entirely of non-whitespace, non-comma printable ASCII characters.

     The version of the Pluggable Transport specification as of this document is "3.0".

     Examples:
     shapeshifter -dispatcher -ptversion 1,1a,2.2,this_is_a_valid_version */
    // TODO: Accept a list of versions
    @Option(name: .customLong("ptversion", withSingleDash: true), help: "Specifies the versions of the Pluggable Transport specification the parent process supports, delimited by commas. All PTs MUST accept any well-formed list, as long as a compatible version is present.")
    var ptVersion: String
    
    /** -state
     Specifies a path to a directory where the PT is allowed to store state that will be persisted across invocations. This can be either an absolute path or a relative path. If a relative path is used, it is assumed to be relative to the current directory. The directory is not required to exist when the PT is launched, however PT implementations SHOULD be able to create it as required.
     
     If -state flag is not specified, PT proxies MUST use the current working directory of the PT process as the state location.

     PTs MUST only store files in the path provided, and MUST NOT create or modify files elsewhere on the system.
     
     Examples:
     shapeshifter-dispatcher -state /var/lib/pt_state/ */
    @Option(name: .customLong("state", withSingleDash: true), help: "Specifies a path to a directory where the PT is allowed to store state.", completion: .directory)
    var stateDir: String = FileManager.default.currentDirectoryPath
    
    
    /** -exit-on-stdin-close
     Specifies that the parent process will close the PT proxy's standard input (stdin) stream to indicate that the PT proxy should gracefully exit.

     PTs MUST NOT treat a closed stdin as a signal to terminate unless this flag is present and is set to "1".

     PTs SHOULD treat stdin being closed as a signal to gracefully terminate if this flag is set to "1".

     Example:
     shapeshifter-dispatcher -exit-on-stdin-close
     */
    @Flag(name: .customLong("exit-on-stdin-close", withSingleDash: true), help: "Specifies that the parent process will close the PT proxy's standard input (stdin) stream to indicate that the PT proxy should gracefully exit.")
    var exitOnStdinClose = false
    
    // TODO: ipcLogLevel
    /**
     -ipcLogLevel
     Controls what log messages are sent from the dispatcher to the application using LOG messages.
     The log level MUST be one of the following:

     NONE
     ERROR
     WARN
     INFO
     DEBUG

     Logging at the same log level or above will be sent. For instance, if the -ipcLogLevel is set to ERROR then only ERROR messages will be sent to the application, whereas if the -ipcLogLevel is set to INFO then ERROR, WARN, and INFO (but not DEBUG) messages will be sent to the application. The NONE log level is a special case which indicates that no LOG messages should be sent to the application.

     The default log level is NONE.

     Example:
     -ipcLogLevel DEBUG
     */
    
    /** -transport
     Specifies the name of the PT to use.

     The application MUST set either a single transport with -transport or a list of transports with -transports. The application MUST NOT set both a single transport and a list of transports simultaneously.

     Example:
     shapeshifter-dispatcher -transport shadow
     */
    enum TransportType: String, CaseIterable, ExpressibleByArgument {
           case replicant, shadow, starbridge
    }
    @Option(name: .customLong("transport", withSingleDash: true), help: "Specifies the name of the PT to use.")
    var transport: TransportType
    
    /**
     -optionsFile
     Specifies the path to a file containing the transport options. This path can be either an absolute path or a relative path. If a relative path is used, it is relative to the current directory.

     The contents of the file MUST be in the same format as the argument to the -options parameter.
     The application MUST NOT specify both -options and -optionsFile simultaneously.
     */
    @Option(name: .customLong("optionsfile", withSingleDash: true), help: "Specifies the path to a file containing the transport options.", completion: .directory)
    var optionsDir: String
    
    // TODO: options
    /**
     -options

     Specifies per-PT protocol configuration directives, as a JSON string value with options that are to be passed to the transport.
     If there are no arguments that need to be passed to any of PT transport protocols, -options MAY be omitted.

     If a PT Client requires a server address, then this can be communicated by way of the transport options. For consistency, transports SHOULD name this option "serverAddress" and it SHOULD have a format of <address>:<port>. Unless otherwise specified in the documentation of the specific transport being used, the address can be an IPv4 IP address, an IPv6 IP address, or a domain name. Not all transports require a server address and some will require multiple server addresses, so this convention only applies to the case where the transport requires a single server address.

     The application MUST NOT specify both -options and -optionsFile simultaneously.

     Example:
     shapeshifter-dispatcher -options "{shadow: {password: \”password\”, cipherName: \"AES-128-GC<\”}}”
     */
    
    // TODO: mode
    /** -mode
     Sets the proxy <mode>.

     The mode MUST be one of the following:

     transparent-TCP
     transparent-UDP
     socks5
     STUN

     The default if no mode is specified is socks5.
     */
    
    // TODO: client
    /**-client
     Specifies that the PT proxy should run in client mode.

     If neither -client or -server is specified, the PT proxy MUST launch in client mode.

     Example

     shapeshifter-dispatcher -client
     */
    
    // TODO: transports
    /**
     -transports
     
     Specifies the PT protocols the client proxy should initialize, as a comma separated list of PT names.
     PTs SHOULD ignore PT names that it does not recognize.

     The application MUST set either a single transport with -transport or a list of transports with -transports. The application MUST NOT set both a single transport and a list of transports simultaneously.

     Example:
     shapeshifter-dispatcher -transports obfs2,obfs4
     */
    
    // TODO: proxylistenaddr
    /**
     -proxylistenaddr

     This flag specifies the <address>:<port> on which the dispatcher client should listen for incoming application client connections. When this flag is used, the dispatcher client will use this address and port instead of making its own choice.

     The <address>:<port> combination MUST be an IP address supported by bind(), and MUST NOT be a host name.

     Applications MUST NOT set more than one <address>:<port> pair.

     A combined address and port can be set using -proxylistenaddr. Alternatively, -proxylistenhost and -proxylistenport can be used to separately set the address and port respectively. If a combined address and port is specified then a separate host and port cannot be specified and vice versa.

     Example:
     shapeshifter-dispatcher -proxylistenaddr 127.0.0.1:5555
     */
    
    // TODO: proxylistenhost
    /**
     -proxylistenhost

     This flag specifies the

     on which the dispatcher client should listen for incoming application client connections. When this flag is used, the dispatcher client will use this address instead of making its own choice.
     The

     combination MUST be an IP address supported by bind(), and MUST NOT be a host name.
     Applications MUST NOT set more than one

     : pair.
     A combined address and port can be set using -proxylistenaddr. Alternatively, -proxylistenhost and -proxylistenport can be used to separately set the address and port respectively. If a combined address and port is specified then a separate host and port cannot be specified and vice versa.

     Example
     shapeshifter-dispatcher -proxylistenhost 127.0.0.1 -proxylistenport 5555
     */
    
    // TODO: proxylistenport
    /**
     -proxylistenport

     This flag specifies the <port> on which the dispatcher client should listen for incoming application client connections. When this flag is used, the dispatcher client will use this port instead of making its own choice.

     The <address>:<port> combination MUST be an IP address supported by bind(), and MUST NOT be a host name.

     Applications MUST NOT set more than one <address>:<port> pair.

     A combined address and port can be set using -proxylistenaddr. Alternatively, -proxylistenhost and -proxylistenport can be used to separately set the address and port respectively. If a combined address and port is specified then a separate host and port cannot be specified and vice versa.

     Example:
     shapeshifter-dispatcher -proxylistenhost 127.0.0.1 -proxylistenport 5555
     */
    
    // TODO: proxy
    /**
     -proxy

     Specifies an upstream proxy that the PT MUST use when making outgoing network connections. It is a URI [RFC3986] of the format:

     <proxy_type>://[<user_name>[:<password>][@]<ip>:<port>.

     The -proxy command line flag is OPTIONAL and MUST be omitted if there is no need to connect via an upstream proxy.

     Examples:
     shapeshifter-dispatcher -proxy http://198.51.100.3:443
     */
    
    /**
     -server

     Specifies that the PT proxy should run in server mode.
     If neither -client or -server is specified, the PT proxy MUST launch in client mode.

     Example:
     shapeshifter-dispatcher -server
     */
    @Flag(name: .customLong("server", withSingleDash: true), help: "Specifies that the PT proxy should run in server mode. If neither -client or -server is specified, the PT proxy MUST launch in client mode.")
    var serverMode = false
    
    // TODO: bindaddr
    /**
     -bindaddr

     A comma separated list of <key>-<value> pairs, where <key> is a PT name and <value> is the <address>:<port> on which it should listen for incoming client connections.

     The keys holding transport names MUST be in the same order as they appear in -transports.

     The <address> MAY be a locally scoped address as long as port forwarding is done externally.

     The <address>:<port> combination MUST be an IP address supported by bind(), and MUST NOT be a host name.

     Applications MUST NOT set more than one <address>:<port> pair per PT name.

     The bind address MUST be set, either using a combined -bindaddr flag or in separate parts using -transport, -bindhost, and -bindport.

     If a combined -bindaddr is used then -transport, -bindhost, and -bindport MUST NOT be used. Similarly, if -transport, -bindhost, or -bindport is used then -bindaddr MUST NOT be used.

     Example:
     shapeshifter-dispatcher -bindaddr obfs4-198.51.100.1:1984,shadow-127.0.0.1:4891
     */
    
    /**
     -bindhost

     Specifies the <address> part of the server bind address when used in conjunction with -transport and -bindport.
     
     The <address> MAY be a locally scoped address as long as port forwarding is done externally.
     The <address> MUST be an IP address supported by bind(), and MUST NOT be a host name.

     Applications MUST NOT set more than one <address> using -bindhost.
     The bind address MUST be set, either using a combined -bindaddr flag or in separate parts using -transport, -bindhost, and -bindport.
     
     If a combined -bindaddr is used then -transport, -bindhost, and -bindport MUST NOT be used. Similarly, if -transport, -bindhost, or -bindport is used then -bindaddr MUST NOT be used.
     If -bindhost is specified, then -transport and -bindport must also be used.
     */
    @Option(name: .customLong("bindhost", withSingleDash: true), help: "Specifies the <address> part of the server bind address when used in conjunction with -transport and -bindport. If -bindhost is specified, then -transport and -bindport must also be used.")
    var bindHost: String
    
    /**
     -bindport

     Specifies the <port> part of the server bind address when used in conjunction with -transport and -bindhost.

     Applications MUST NOT set more than one <port> using -bindport.
     The bind port MUST be set, either using a combined -bindaddr flag or in separate parts using -transport, -bindhost, and -bindport.

     If a combined -bindaddr is used then -transport, -bindhost, and -bindport MUST NOT be used. Similarly, if -transport, -bindhost, or -bindport is used then -bindaddr MUST NOT be used.
     If -bindport is specified, then -transport and -bindhost must also be used.
     */
    @Option(name: .customLong("bindport", withSingleDash: true), help: "Specifies the <port> part of the server bind address when used in conjunction with -transport and -bindhost.")
    var bindPort: Int
    
    // TODO: target
    /**
     -target

     Specifies the destination that the PT reverse proxy should forward traffic to after transforming it as appropriate, as an <address>:<port>. Unless otherwise specified in the documentation of the specific transport being used, the address can be an IPv4 IP address, an IPv6 IP address, or a domain name.

     Connections to the target destination MUST only contain application payload. If the parent process requires the actual source IP address of client connections (or other metadata), it should set -extorport instead.

     The target destination MUST be set. A combined address and port can be set using -target. Alternatively, -targethost and -targetport can be used to separately set the address and port respectively. If a combined address and port is specified then a separate host and port cannot be specified and vice versa.

     Examples:
     shapeshifter-dispatcher -target 127.0.0.1:9001
     shapeshifter-dispatcher -target 93.184.216.34:9001
     shapeshifter-dispatcher -target [2001:0db8:85a3:0000:0000:8a2e:0370:7334]:1122
     shapeshifter-dispatcher -target example.com:9922
     */
    
    /**
     -targethost

     Specifies the <address> of the destination that the PT reverse proxy should forward traffic to after transforming it as appropriate. Unless otherwise specified in the documentation of the specific transport being used, the address can be an IPv4 IP address, an IPv6 IP address, or a domain name.

     Connections to the target destination MUST only contain application payload. If the parent process requires the actual source IP address of client connections (or other metadata), it should set -extorport instead.

     The target destination MUST be set. A combined address and port can be set using -target. Alternatively, -targethost and -targetport can be used to separately set the address and port respectively. If a combined address and port is specified then a separate host and port cannot be specified and vice versa.

     If -targethost is specified, then -targetport must also be specified.

     Example

     shapeshifter-dispatcher -targethost 93.184.216.34 -targetport 9001
     */
    @Option(name: .customLong("targethost", withSingleDash: true), help: "Specifies the <address> of the destination that the PT reverse proxy should forward traffic to after transforming it as appropriate. Unless otherwise specified in the documentation of the specific transport being used, the address can be an IPv4 IP address, an IPv6 IP address, or a domain name.")
    var targetHost: String
    
    
    /**
     -targetport

     Specifies the <port> of the destination that the PT reverse proxy should forward traffic to after transforming it as appropriate.

     Connections to the target destination MUST only contain application payload. If the parent process requires the actual source IP address of client connections (or other metadata), it should set -extorport instead.

     The target destination MUST be set. A combined address and port can be set using -target. Alternatively, -targethost and -targetport can be used to separately set the address and port respectively. If a combined address and port is specified then a separate host and port cannot be specified and vice versa.

     If -targetport is specified, then -targethost must also be specified.

     Example:
     shapeshifter-dispatcher -targethost 93.184.216.34 -targetport 9001
     */
    @Option(name: .customLong("targetport", withSingleDash: true), help: "Specifies the <port> of the destination that the PT reverse proxy should forward traffic to after transforming it as appropriate.")
    var targetPort: Int
    
    func validate() throws
    {
        guard (ptVersion == supportedPTVersion) else
        {
            appLog.error("\(Error.ptVersion.localizedDescription)")
            throw Error.ptVersion
        }
    }
    
    func run() throws
    {
        #if canImport(WASILibc)
        // Logger is already setup
        #else
        // Setup the logger
            #if !os(macOS)
                LoggingSystem.bootstrap(StreamLogHandler.standardError)
                appLog.logLevel = .debug
            #endif
        #endif
                
        switch (transport)
        {
            case .shadow:
                let shadowController = ShadowController(configPath: optionsDir, targetHost: targetHost, targetPort: targetPort, bindHost: bindHost, bindPort: bindPort)
                
                if serverMode
                {
                    try shadowController.runServer()
                }
                else
                {
                    appLog.error("Currently only server mode is supported.")
                    return
                }
                
                
            case .replicant:
                let replicantController = ReplicantController(configPath: optionsDir, targetHost: targetHost, targetPort: targetPort, bindHost: bindHost, bindPort: bindPort)
                
                if serverMode
                {
                    try replicantController.runServer()
                }
                else
                {
                    appLog.error("Currently only server mode is supported.")
                    return
                }
                
            case .starbridge:
                let starbridgeController = StarbridgeController(configPath: optionsDir, targetHost: targetHost, targetPort: targetPort, bindHost: bindHost, bindPort: bindPort)
                
                if serverMode
                {
                    try starbridgeController.runServer()
                }
                else
                {
                    appLog.error("Currently only server mode is supported.")
                    return
                }
        }
    }
    
    enum Error: LocalizedError
    {
        case ptVersion
        
        var errorDescription: String?
        {
            switch self
            {
                case .ptVersion:
                    return "Currently this application only supports Pluggable Transports version \(supportedPTVersion)"

            }
        }
    }
}

ShapeshifterDispatcher.main()

