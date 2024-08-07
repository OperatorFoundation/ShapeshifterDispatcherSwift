### The Operator Foundation

[Operator](https://operatorfoundation.org) makes useable tools to help people around the world with censorship, security, and privacy.

## The Moonbounce Project
The Moonbounce Project is an initiative covering several clients, servers, and libraries. The goal of the project is to provide a simple VPN service that integrates
Pluggable Transport technology. This allows the Moonbounce VPN to operate on network with restrictive Internet censorship that blocks VPN protocols such as OpenVPN
and Wireguard. This project, Shapeshifter Dispatcher for Swift, is one of several components of the Moonbounce project.

# Shapeshifter Dispatcher for Swift

A Swift implementation of Shapeshifter Dispatcher designed to run on Linux machines as a command line tool.

Currently this implementation only supports running **Shadow**, **Starbridge**, **Omni**, and **Dandelion** transports in *server* mode.

## Running a Shadow Server

```
ShapeshifterDispatcherSwift -ptversion 3.0 -transport shadow -bindhost <server IP> -bindport <server port> -optionsfile <pathToTransportConfig> -server -targethost <target IP> -targetport <target port>
```

## Running a Starbridge Server

```
ShapeshifterDispatcherSwift -ptversion 3.0 -transport starbridge -bindhost <server IP> -bindport <server port> -optionsfile <pathToTransportConfig> -server -targethost <target IP> -targetport <target port>
```

# Shapeshifter Configs

Running the dispatcher requires an options file containing the configuration information for the chosen Pluggable Transport.

The ShapeshifterConfigs tool generates new config files for the transports supported by Shapeshifter Dispatcher for Swift.

Currently this implementation supports the creation of **Shadow** and **Starbridge** config files.

## Usage:

### Starbridge Config Generation

Running this command will generate a valid server and client config file pair, and save them to the directory of your choice.

Note that because Starbridge uses encryption, it is not possible to mix and match server and client configs. The server config that is generated will run a server that clients can connect to, ONLY if they use the client config information that was generated at the same time.
```
swift run ShapeshifterConfigs starbridge --host <serverIP> --port <serverPort> --directory <pathToSaveDirectory>
```

### Shadow Config Generation

Running this command will generate a valid server and client config file pair, and save them to the directory of your choice.

Note that because shadow uses encryption, it is not possible to mix and match server and client configs. The server config that is generated will run a server that clients can connect to, ONLY if they use the client config information that was generated at the same time.
```
swift run ShapeshifterConfigs shadow --host <serverIP> --port <serverPort> --directory <pathToSaveDirectory>
```
