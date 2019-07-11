// MIT License
//
// Copyright 2015-19 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

// Stubbed i2c for imp006
class softi2c {
    scl = null;
    // Pins
    sda = null;
    delay = (1.0/400000);
    
    constructor(_scl, _sda) {
        scl = _scl;
        sda = _sda;
        
        scl.configure(DIGITAL_OUT_OD);
        sda.configure(DIGITAL_OUT_OD);
        
        // unjam
        _write(0xff);
        _stop();
    }
    
    function _start() {
        // SDA low then SCL
        imp.sleep(delay);
        sda.write(0);
        imp.sleep(delay);
        scl.write(0);
    }
    
    function _stop() {
        // SCL high then SDA
        imp.sleep(delay);
        scl.write(1);
        imp.sleep(delay);
        sda.write(1);
    }
    
    function _write(byte) {
        for(local a = 7; a >= 0; a--) {
            // Set data
            if (byte & (1<<a)) sda.write(1);
            else sda.write(0);
            
            // Clock high then low
            imp.sleep(delay);
            scl.write(1);
            imp.sleep(delay);
            scl.write(0);
        }
        
        // Read ACK
        sda.write(1);
        imp.sleep(delay);
        scl.write(1);
        imp.sleep(delay);
        local ack = sda.read()?false:true;
        scl.write(0);
        return ack;
    }
    
    function _read(ack) {
        local byte = 0;
        sda.write(1);
        for(local a = 7; a >=0; a--) {
            // Read just on rising edge of clock
            imp.sleep(delay);
            scl.write(1);
            byte += sda.read() ? (1<<a) : 0;
            imp.sleep(delay);
            scl.write(0);
        }
        
        // Send ACK
        sda.write(ack?0:1);
        imp.sleep(delay);
        scl.write(1);
        imp.sleep(delay);
        scl.write(0);
        sda.write(1);

        return byte;
    }
    
    function write(address, data) {
        //server.log(format("Writing addr %02x (len %d)", address, data.len()));
        
        _start();
        local error = 0;
        if (_write(address)) {
            // Send data
            foreach(b in data) {
                if (!_write(b)) {
                    server.log("NACK writing data");
                    error = -2;
                    break;
                }
            }
        } else {
            server.log("NACK address");
            error = -1;
        }
        _stop();
        
        return error;
    }

    function read(address, data, len) {
        local s="";
    
        //server.log(format("Reading addr %02x (len %d)", address, len));
        
        _start();
        if (_write(address&0xfe)) {
            // Send data
            foreach(b in data) {
                //server.log(format("writing %02x", b));
                if (!_write(b)) {
                    server.log("NACK writing data");
                    break;
                }
            }
        } else {
            server.log("NACK address (on write)");
        }
        _stop();
        
        _start();

        if (_write(address|1)) {
            // Read data
            for(local a=0;a<len;a++) {
                local b = _read(a!=(len-1));
                //server.log(format("read %02x", b));
                s+=b.tochar();
            }
        } else {
            server.log("NACK address (on read)");
        }
        _stop();
        
        return (s.len() > 0) ? s : null;
    }
    
    function configure(speed) {
        delay = (1.0/speed);
    }

    function readerror() {
        return -50;
    }
}