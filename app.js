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
var tcpPort = '1307',
    tcpHost = 'www.swtch.co';

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
    // console.log('sent signal');
    // delay(1000);
};

// TCP client
var client = net.createConnection(tcpPort, tcpHost, function() {
    console.log('client connected');
});

client.on('data', function (chunk) {
    console.log("From TCP: " + chunk);
    sp.write(chunk);
});

sp.on('data', function (chunk) {
    console.log(chunk);
    client.write(chunk);
});

bb.run();
