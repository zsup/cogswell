// Requirements
var fs = require('fs');
var bb = require('../bonescript');
var SerialPort = require("serialport").SerialPort;
var net = require ('net');

// Instantiate the serial pins
var serialIn = bone.P9_26;
var serialOut = bone.P9_24;

// Instantiate the user LEDs, for feedback
var usrPin = bone.USR3;

// Serial info
var PORT = "/dev/ttyO1";
var BAUD_RATE = 9600;
var sp = new SerialPort(PORT, {
    baudrate: BAUD_RATE
});

// TCP info
var tcpPort = '1307';
// var tcpHost = 'www.swtch.co';
var tcpHost = '169.254.38.35';
    
// Buffers and helpers
var serialBuffer = "";
var clientBuffer = "";
var separator = "\n";
var devices = {};

ts = function() {
    var d = new Date().toTimeString();
    var index = d.indexOf(" GMT");
    return d.slice(0,index);
};

clog = function(msg) {
    console.log(ts() + ": " + msg);
};

setup = function() {
    pinMode(usrPin, OUTPUT);
    
    // Make sure the pinmux is mode 0 (TX/RX)
    // Really, this should be done using pinMode as above - but we can't use that for TX/RX yet
    var serialInMuxfile = fs.openSync("/sys/kernel/debug/omap_mux/" + serialIn.mux, "w");
    var serialOutMuxfile = fs.openSync("/sys/kernel/debug/omap_mux/" + serialOut.mux, "w");
    fs.writeSync(serialInMuxfile, "20", null);
    fs.writeSync(serialOutMuxfile, "0", null);
};

loop = function() {
    // sp.write("TEST");
    // clog('sent signal');
    // delay(1000);
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
    separatorIndex = clientBuffer.indexOf(separator);
    foundMessage = separatorIndex != -1;
    
    if (foundMessage) {
        var message = clientBuffer.slice(0, separatorIndex);
        clientProcess(message);
        clientBuffer = clientBuffer.slice(separatorIndex + 1);
        separatorIndex = clientBuffer.indexOf(separator);
    }
});

sp.on('data', function (chunk) {
    clog("From Serial: " + chunk);
    serialBuffer += chunk;
    separatorIndex = serialBuffer.indexOf(separator);
    foundMessage = separatorIndex != -1;
    
    if (foundMessage) {
        var message = serialBuffer.slice(0, separatorIndex);
        deviceProcess(message);
        serialBuffer = serialBuffer.slice(separatorIndex + 1);
        separatorIndex = serialBuffer.indexOf(separator);
    }
});

bb.run();

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
        sp.write(deviceid + ",dim" + msgobj.dimval + "\n");
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