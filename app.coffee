# Requirements
fs = require 'fs'
SerialPort = require("serialport").SerialPort
net = require 'net'

# Serial info
PORT = "/dev/ttyO1"
BAUD_RATE = 9600
sp = new SerialPort PORT,
	baudrate: BAUD_RATE

# TCP info
tcpPort = '1307'
tcpHost = 'www.swtch.co'

# Buffers and helpers
# TODO: Make these buffers into actual Node.js Buffers?
serialBuffer = ""
clientBuffer = ""
separator = '\n'
devices = {}
serialDelay = 5
serialReady = -1
clientReady = 0

ts = ->
	d = new Date().toTimeString()
	index = d.indexOf " GMT"
	return d.slice 0, index

clog = (msg) ->
	console.log "#{ts()}: #{msg}"
	
# Pinmuxing!
# This reprograms the serial pins so they can do serial
# communication, instead of being silly digital write pins.
# Serial comm > blinking lights.
# Make sure the pinmux is mode 0 (TX/RX), with recieving enabled for RX.
# When both the input and output pins are prepped, serialReady == 1. That means go.
path = "/sys/kernel/debug/omap_mux"
rxMode = new Buffer "20"
txMode = new Buffer "0"

# RX pinmuxing
fs.open "#{path}/uart1_rxd", "w", 0o0666, (err, fd) ->
	throw error if err
	clog "RX Mux file opened"
	fs.write fd, rxMode, null, null, null, (err, fd) ->
		throw error if err
		clog "RX file written"
		fs.close fd, ->
			clog "RX file closed"
			serialReady++

# TX pinmuxing
fs.open "#{path}/uart1_txd", "w", 0o0666, (err, fd) ->
	throw error if err
	clog "TX Mux file opened"
	fs.write fd, txMode, null, null, null, (err, fd) ->
		throw error if err
		clog "TX file written"
		fs.close fd, ->
			clog "TX file closed"
			serialReady++

# TCP client. When it connects to the server, clientReady == 1
client = net.createConnection tcpPort, tcpHost, ->
	clog 'Connected to server'
	clientReady++

# How to handle data from the server.
client.on 'data', (chunk) ->
	# When data is received from the server, store it in the buffer.
	clog "From TCP: #{chunk}"
	clientBuffer += chunk
	
	# Then, check the contents to see if the separator has been found.
	separatorIndex = clientBuffer.indexOf separator
	foundMessage = separatorIndex != -1
	
	# If the separator has been found, process the message, and save
	# the rest of the message back into the buffer
	if foundMessage
		message = clientBuffer.slice 0, separatorIndex
		clientProcess message
		clientBuffer = clientBuffer.slice(separatorIndex + 1)
		separatorIndex = clientBuffer.indexOf(separator)

# How to handle data from the serial connection (i.e. XBee)
sp.on 'data', (chunk) ->
	# When data is received, store it in the buffer.
	clog "From Serial: #{chunk}"
	serialBuffer += chunk
	
	# Then, check the contents to see if the separator has been found.
	separatorIndex = serialBuffer.indexOf(separator)
	foundMessage = separatorIndex != -1
	
	# If the separator has been found, process the message, and save
	# the rest of the message back into the buffer
	if foundMessage
		message = serialBuffer.slice(0, separatorIndex)
		deviceProcess message
		serialBuffer = serialBuffer.slice(separatorIndex + 1)
		separatorIndex = serialBuffer.indexOf(separator)
	
# Processes JSON messages received from the server
clientProcess = (message) ->
	message = message.trim()
	clog "Processing message: #{message}"
	failure = false
	
	try
		msgobj = JSON.parse message
	catch syntaxError
		failure = true
		clog "Failed to process - bad syntax"
		return
	
	enoughinfo = msgobj.hasOwnProperty 'deviceid'
	
	if !enoughinfo
		clog "Not enough info"
		return
	
	deviceid = msgobj.deviceid
	
	if !devices[deviceid]?
		clog "No device by the name of #{deviceid}"
		devices[deviceid] = msgobj
		return
		
	if devices[deviceid].devicestatus != msgobj.devicestatus
		message = "turn#{msgobj.devicestatus}"
		serialSend deviceid, message
		
	if devices[deviceid].dimval != msgobj.dimval
		message = "dim#{msgobj.dimval}"
		serialSend deviceid, message
		
	devices[deviceid] = msgobj

# Processes JSON messages from the devices.
# TODO: This should be made into byte-by-byte API calls
# Perhaps use the MIDI protocol?
deviceProcess = (message) ->
	message = message.trim()
	clog "Processing message: #{message}"
	failure = false
	
	try
		msgobj = JSON.parse message
	catch syntaxError
		failure = true
		clog "Failed to process - bad syntax"
		return
    
	enoughinfo = msgobj.hasOwnProperty 'deviceid'
	
	if !enoughinfo
		clog "Not enough info"
		return
	
	devices[msgobj.deviceid] = msgobj
	client.write JSON.stringify(msgobj)
	client.write separator

# Sends messages down the serial channel.
serialSend = (device, message) ->
	msg = "#{device},#{message}#{separator}"
	clog "Sending: #{msg}"
	recursiveSend msg

# Sends the message character by character.
# Done recursively so that a delay can be added.
recursiveSend = (msg) ->
	sp.write msg.substring(0,1)
	setTimeout recursiveSend, serialDelay, msg.substring(1)