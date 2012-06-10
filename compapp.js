// Requirements
var SerialPort = require("serialport").SerialPort;
var net = require ('net');

// Serial info
var PORT = "/dev/tty.usbserial-AH00SC1B";
var BAUD_RATE = 9600;
var sp = new SerialPort(PORT, {
    baudrate: BAUD_RATE
	
});

// TCP info
var tcpPort = '1307';
var tcpHost = 'www.swtch.co';
// var tcpHost = '169.254.38.35';
    
// Buffers and helpers
var serialBuffer = "";
var clientBuffer = "";
var separator = '\n';
var devices = {};
var foundSerialMessage = false;
var foundClientMessage = false;
var serialSeparatorIndex = -1;
var clientSeparatorIndex = -1;

ts = function() {
    var d = new Date().toTimeString();
    var index = d.indexOf(" GMT");
    return d.slice(0,index);
};

clog = function(msg) {
    console.log(ts() + ": " + msg);
};



loop = function() {
    if (clientBuffer != "") {
        
    }
    if (serialBuffer != "") {
        
    }
};

// TCP client
var client = net.createConnection(tcpPort, tcpHost, function() {
    clog('client connected');
});

// When data is received, look for an endline character. If it exists, process the data.
// Otherwise, keep it in the buffer and look for more.
client.on('data', function (chunk) {
    clog("From TCP: " + chunk);
    clientBuffer += chunk;
	clientSeparatorIndex = clientBuffer.indexOf(separator);
    foundClientMessage = clientSeparatorIndex != -1;

    if (foundClientMessage) {
        var message = clientBuffer.slice(0, clientSeparatorIndex);
        clientProcess(message);
        clientBuffer = clientBuffer.slice(clientSeparatorIndex + 1);
        clientSeparatorIndex = clientBuffer.indexOf(separator);
    }
});

sp.on('data', function (chunk) {
    clog("From Serial: " + chunk);
    serialBuffer += chunk;
	serialSeparatorIndex = serialBuffer.indexOf(separator);
    foundSerialMessage = serialSeparatorIndex != -1;

    if (foundSerialMessage) {
		clog("Found message");
        var message = serialBuffer.slice(0, serialSeparatorIndex);
        deviceProcess(message);
        serialBuffer = serialBuffer.slice(serialSeparatorIndex + 1);
        serialSeparatorIndex = serialBuffer.indexOf(separator);
    }
});

// Processes JSON messages received from the server
clientProcess = function(message) {
    message = message.trim();
    clog("Processing message: " + message);
    var failure = false;
    
    try {
        var msgobj = JSON.parse(message);
    }
    catch (syntaxError) {
        failure = true;
        clog("Failed to process - bad syntax");
        return;
    }
    
    var enoughinfo = msgobj.hasOwnProperty('deviceid');
    
    if (!enoughinfo) {
        clog("Not enough info");
        return;
    }
    
    var deviceid = msgobj.deviceid;
    
    if (!devices[deviceid]) {
        clog("No device by the name of " + deviceid);
        devices[deviceid] = msgobj;
        return;
    }
    
    if (devices[deviceid].devicestatus != msgobj.devicestatus) {
        sp.write(deviceid + ",turn" + msgobj.devicestatus + "\n");
    }
    
    if (devices[deviceid].dimval != msgobj.dimval) {
		var msg = deviceid + ",dim" + msgobj.dimval + "\n";
		clog("Sending message: " + msg);
		sp.write(msg);
    }
    
    devices[deviceid] = msgobj;
}

// Processes JSON messages from the devices.
// TODO: This should be made into byte-by-byte API calls
deviceProcess = function(message) {
    message = message.trim();
    clog("Processing message: " + message);
    var failure = false;
    
    try {
        var msgobj = JSON.parse(message);
    }
    catch (syntaxError) {
        failure = true;
        clog("Failed to process - bad syntax");
        return;
    }
    
    var enoughinfo = msgobj.hasOwnProperty('deviceid');
    
    if (!enoughinfo) {
        clog("Not enough info");
        return;
    }
    
    devices[msgobj.deviceid] = msgobj;
    client.write(JSON.stringify(msgobj));
    client.write("\n");
}