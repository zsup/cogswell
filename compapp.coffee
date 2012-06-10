# Requirements
SerialPort = require("serialport").SerialPort
net = require 'net'

# Serial info
PORT = "/dev/tty.usbserial-AH00SC1B"
BAUD_RATE = 9600
sp = new SerialPort PORT,
	baudrate: BAUD_RATE

# TCP info
tcpPort = '1307'
tcpHost = 'www.swtch.co'

# TCP client
client = net.createConnection tcpPort, tcpHost, ->
    console.log 'client connected'

client.on 'data', (chunk) ->
    console.log "From TCP: #{chunk}"
    sp.write chunk

sp.on 'data', (chunk) ->
    console.log chunk
    client.write chunk