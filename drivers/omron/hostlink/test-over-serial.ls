require! '../../../transports/serial-port': {SerialPortTransport}
require! './hostlink-protocol': {HostlinkProtocol}
require! '../../..': {Logger, sleep}

logger = new Logger 'Hostlink Test'

transport = new SerialPortTransport do
    baudrate: 9600baud
    port: '/dev/ttyUSB0'
    split-at: '\r'

protocol = new HostlinkProtocol transport

transport
    ..on \connect, ->
        logger.log "serial port is connected"

    ..on \data, (frame) ~>
        logger.log "frame received:", JSON.stringify frame

    ..on \disconnect, ~>
        logger.log "disconnected "


<~ transport.once \connect
<~ :lo(op) ~>
    err, res <~ protocol.write 'R92', 0
    logger.log "hostlink write, err: ", err, "res: ", res
    <~ sleep 1000ms
    err, res <~ protocol.write 'R92', [1]
    logger.log "hostlink write, err: ", err, "res: ", res
    <~ sleep 2000ms
    lo(op)
