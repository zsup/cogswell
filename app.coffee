# Requirements
fs = require 'fs'
bb = require '../bonescript'
SerialPort = require("serialport").SerialPort
net = require 'net'

# Instantiate the serial pins
serialIn = bone.P9_26
serialOut = bone.P9_24

# Instantiate the user LEDs, for feedback
usrPin = bone.USR3

# Serial info
PORT = "/dev/ttyO1"
BAUD_RATE = 9600
sp = new SerialPort PORT,
	baudrate: BAUD_RATE

# TCP info
tcpPort = '1307'
tcpHost = 'www.swtch.co'

setup = ->
    pinMode(usrPin, OUTPUT)
    
    # Make sure the pinmux is mode 0 (TX/RX)
    # Really, this should be done using pinMode as above - but we can't use that for TX/RX yet
    serialInMuxfile = fs.openSync "/sys/kernel/debug/omap_mux/#{serialIn.mux}", "w"
    serialOutMuxfile = fs.openSync "/sys/kernel/debug/omap_mux/#{serialOut.mux}", "w"
    fs.writeSync serialInMuxfile, "20", null
    fs.writeSync serialOutMuxfile, "0", null

loop = ->
    # sp.write("TEST");
    # console.log('sent signal');
    # delay(1000);

# TCP client
client = net.createConnection tcpPort, tcpHost, ->
    console.log 'client connected'

client.on 'data', (chunk) ->
    console.log "From TCP: #{chunk}"
    sp.write chunk

sp.on 'data', (chunk) ->
    console.log chunk)
    client.write chunk)

bb.run()
