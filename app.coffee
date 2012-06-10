# Requirements
fs = require 'fs'
# bb = require '../bonescript'
SerialPort = require("serialport").SerialPort
net = require 'net'

# Instantiate the serial pins
# serialIn = bone.P9_26
# serialOut = bone.P9_24

# Instantiate the user LEDs, for feedback
# usrPin = bone.USR3

# Serial info
PORT = "/dev/ttyO1"
BAUD_RATE = 9600
sp = new SerialPort PORT,
	baudrate: BAUD_RATE

# TCP info
tcpPort = '1307'
tcpHost = 'www.swtch.co'

# Buffers and helpers
serialBuffer = ""
clientBuffer = ""
separator = '\n'
devices = {}

ts = ->
	d = new Date().toTimeString()
	index = d.indexOf " GMT"
	return d.slice 0,index

clog = (msg) ->
	console.log "#{ts()}: #{msg}"

# setup = ->
#	pinMode usrPin, OUTPUT
	
	# Make sure the pinmux is mode 0 (TX/RX)
	# Really, this should be done using pinMode as above - but we can't use that for TX/RX yet
	# serialInMuxfile = fs.openSync "/sys/kernel/debug/omap_mux/#{serialIn.mux}", "w"
	# serialOutMuxfile = fs.openSync "/sys/kernel/debug/omap_mux/#{serialOut.mux}", "w"
	# fs.writeSync serialInMuxfile, "20", null
	# fs.writeSync serialOutMuxfile, "0", null

# TCP client
client = net.createConnection tcpPort, tcpHost, ->
	clog 'client connected'

client.on 'data', (chunk) ->
	clog "From TCP: #{chunk}"
	clientBuffer += chunk
	
	separatorIndex = clientBuffer.indexOf separator
	foundMessage = separatorIndex != -1
	
	if foundMessage
		message = clientBuffer.slice 0, separatorIndex
		clientProcess message
		clientBuffer = clientBuffer.slice(separatorIndex + 1)
		separatorIndex = clientBuffer.indexOf(separator)

sp.on 'data', (chunk) ->
	clog "From Serial: #{chunk}"
	serialBuffer += chunk
	
	separatorIndex = serialBuffer.indexOf(separator)
	foundMessage = separatorIndex != -1
		
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
	sp.write msg

# bb.run()
