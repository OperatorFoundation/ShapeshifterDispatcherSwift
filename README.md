# ShapeshifterDispatcherSwift

A swift implementation of ShapeshifterDispatcher designed to run on Linux machines as a command line tool.

Currently this implementation only supports running **Shadow** and **Starbridge** transports in *server* mode.

### Usage:

#### Running a Starbridge Server

```
ShapeshifterDispatcherSwift -ptversion 3.0 -transport starbridge -bindhost <server IP> -bindport <server port> -optionsfile <pathToTransportConfig> -server
```

#### Running a Starbridge Server With a Target Host

```
ShapeshifterDispatcherSwift -ptversion 3.0 -transport starbridge -bindhost <server IP> -bindport <server port> -optionsfile <pathToTransportConfig> -server -targethost <target IP> -targetport <target port>
```

#### Running a Shadow Server
```
ShapeshifterDispatcherSwift -ptversion 3.0 -transport shadow -bindhost <server IP> -bindport <server port> -optionsfile <pathToTransportConfig> -server
```

#### Running a Shadow Server With a Target Host
```
ShapeshifterDispatcherSwift -ptversion 3.0 -transport shadow -bindhost <server IP> -bindport <server port> -optionsfile <pathToTransportConfig> -server -targethost <target IP> -targetport <target port>
```


# ShapeshifterConfigs

ShapeshifterConfigs generates new config files for the transports supported by ShapeshifterDispatcherSwift.

Currently this implementation supports the creation of **Shadow** and **Starbridge** config files.


### Usage:

#### Starbridge Config Generation

Running this command will generate a valid server and client config file pair, and save them to the directory of your choice.

Note that because Starbridge uses encryption, it is not possible to mix and match server and client configs. The server config that is generated will run a server that clients can connect to, ONLY if they use the client config information that was generated at the same time.
```
swift run ShapeshifterConfigs starbridge --host <serverIP> --port <serverPort> --directory <pathToSaveDirectory>
```

#### Shadow Config Generation

Running this command will generate a valid server and client config file pair, and save them to the directory of your choice.

Note that because shadow uses encryption, it is not possible to mix and match server and client configs. The server config that is generated will run a server that clients can connect to, ONLY if they use the client config information that was generated at the same time.
```
swift run ShapeshifterConfigs shadow --host <serverIP> --port <serverPort> --directory <pathToSaveDirectory>
```
