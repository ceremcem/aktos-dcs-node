require! '../../protocol-actors/proxy/client': {ProxyClient}
require! '../../transports/tcp': {TcpTransport}

export class TcpDcsClient extends ProxyClient
    (@opts={}) ->
        transport = new TcpTransport do
            host: @opts.host or \127.0.0.1
            port: @opts.port or 5523

        super transport, do
            name: \TcpDcsClient
            forget-password: no

        @on \connected, ~>
            @log.log "Info: Connected to server..."

        @on \disconnect, ~>
            @log.log "Info: Disconnected."
