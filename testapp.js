// Requirements
var SerialPort = require("serialport").SerialPort;

// Serial info
var PORT = "/dev/tty.usbserial-AH00SC1B";
var BAUD_RATE = 9600;
var sp = new SerialPort(PORT, {
    baudrate: BAUD_RATE
});

var msg = "Elroy,dim200\n";
sp.write(msg);

while (msg.length > 0) {
	setTimeout(function() { sp.write(msg.substring(0,1)) }, 100);
	console.log(msg.substring(0,1));
	msg = msg.substring(1);
}