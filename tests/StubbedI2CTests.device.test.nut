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

@include __PATH__+ "/StubbedI2C.device.nut"

const BQ24295_DEFAULT_I2C_ADDR = 0xD4;

class StubbedHardwareTests extends ImpTestCase {
    
    _i2c    = null;
    _charger = null;

    function _cleari2cBuffers() {
        // Clear all buffers
        _i2c._clearWriteBuffer();
        _i2c._clearReadResp();
    }

    function setUp() {
        _i2c = StubbedI2C();
        _i2c.configure(CLOCK_SPEED_400_KHZ);
        _charger = BQ24295(_i2c);
        return "Stubbed hardware test setup complete.";
    }    

    function testConstructorDefaultParams() {
        assertEqual(BQ24295_DEFAULT_I2C_ADDR, _charger._addr, "Defult i2c address did not match expected");
        return "Constructor default params test complete.";
    }

    function testConstructorOptionalParams() {
        local customAddr = 0xBA;
        local charger = BQ24295(_i2c, customAddr);
        assertEqual(customAddr, charger._addr, "Non default i2c address did not match expected");
        return "Constructor optional params test complete.";
    }

    function testEnableDefaults() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();
        // Set readbuffer values
        // BQ24295_CRG_TERM_TMR_CTRL_REG to 0x9C
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_CRG_TERM_TMR_CTRL_REG.tochar(), "\x9C");    
        // BQ24295_PWR_ON_CONFIG_REG to 0x2B
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_PWR_ON_CONFIG_REG.tochar(), "\x2B");
        // BQ24295_CRG_VOLT_CTRL_REG to 0x82, 
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_CRG_VOLT_CTRL_REG.tochar(), "\x82");
        // BQ24295_CRG_CURR_CTRL_REG to 0x00,
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_CRG_CURR_CTRL_REG.tochar(), "\x00");
        // BQ24295_PCRG_TERM_CURR_CTRL_REG to 0x10
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_PCRG_TERM_CURR_CTRL_REG.tochar(), "\x10");

        // Test empty settings table
        _charger.enable();

        // Write commands in enable:
            // (BQ24295_CRG_TERM_TMR_CTRL_REG toggle bits 4-5 to 0, Expected: 0x8C) Disable watchdog 
            // (BQ24295_PWR_ON_CONFIG_REG toggle bit 4 to 1, Expected: 0x3B) Set CHG_CONFIG to enable charging 
            // (BQ24295_CRG_VOLT_CTRL_REG update bits 2-7, Expected: 0xB2) Set charge voltage, 4.208
            // (BQ24295_CRG_CURR_CTRL_REG update bits 2-7, Expected: 0x20) Set charge current, 1024
            // (BQ24295_PCRG_TERM_CURR_CTRL_REG update bits 0-3, Expected: 0x11) Set charge termination current, 256
        local expected = format("%c%s%c%s%c%s%c%s%c%s", 
            BQ24295_CRG_TERM_TMR_CTRL_REG, "\x8C", 
            BQ24295_PWR_ON_CONFIG_REG, "\x3B",
            BQ24295_CRG_VOLT_CTRL_REG, "\xB2",
            BQ24295_CRG_CURR_CTRL_REG, "\x20",
            BQ24295_PCRG_TERM_CURR_CTRL_REG, "\x11"     
        );
        local actual = _i2c._getWriteBuffer(BQ24295_DEFAULT_I2C_ADDR);
        assertEqual(expected, actual, "Enable with defualt params did not match expected results");
        
        _cleari2cBuffers();
        return "Enable with defualt params test passed";
    }

    function testEnableCustomVoltAndCurr() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();
        // Set readbuffer values
        // BQ24295_CRG_TERM_TMR_CTRL_REG to 0x9C
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_CRG_TERM_TMR_CTRL_REG.tochar(), "\x9C");    
        // BQ24295_PWR_ON_CONFIG_REG to 0x2B
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_PWR_ON_CONFIG_REG.tochar(), "\x2B");
        // BQ24295_CRG_VOLT_CTRL_REG to 0x82, 
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_CRG_VOLT_CTRL_REG.tochar(), "\x82");
        // BQ24295_CRG_CURR_CTRL_REG to 0x00,
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_CRG_CURR_CTRL_REG.tochar(), "\x00");
        // BQ24295_PCRG_TERM_CURR_CTRL_REG to 0x10
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_PCRG_TERM_CURR_CTRL_REG.tochar(), "\x10");

        // Test that defaults are not set and current and voltage settings are configured
        _charger.enable({
            "voltage" : 4.2,
            "current" : 2000
        });

        // Write commands in enable:
            // (BQ24295_CRG_TERM_TMR_CTRL_REG toggle bits 4-5 to 0, Expected: 0x8C) Disable watchdog 
            // (BQ24295_PWR_ON_CONFIG_REG toggle bit 4 to 1, Expected: 0x3B) Set CHG_CONFIG to enable charging 
            // (BQ24295_CRG_VOLT_CTRL_REG update bits 2-7, Expected: 0xAE) Set charge voltage, 4.2
            // (BQ24295_CRG_CURR_CTRL_REG update bits 2-7, Expected: 0x5C) Set charge current, 2000
            // (BQ24295_PCRG_TERM_CURR_CTRL_REG update bits 0-3, Expected: 0x11) Set charge termination current, 256
        local expected = format("%c%s%c%s%c%s%c%s%c%s",
            BQ24295_CRG_TERM_TMR_CTRL_REG, "\x8C",          
            BQ24295_PWR_ON_CONFIG_REG, "\x3B",
            BQ24295_CRG_VOLT_CTRL_REG, "\xAE",
            BQ24295_CRG_CURR_CTRL_REG, "\x5C",
            BQ24295_PCRG_TERM_CURR_CTRL_REG, "\x11"       
        );
        local actual = _i2c._getWriteBuffer(BQ24295_DEFAULT_I2C_ADDR);
        assertEqual(expected, actual, "Enable with custom voltage and current params did not match expected results");
        
        _cleari2cBuffers();
        return "Enable with custom voltage and current params test passed";
    }

    function testEnableSetChargeTerminationCurrentLimit() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();
        // Set readbuffer values
        // BQ24295_CRG_TERM_TMR_CTRL_REG to 0x9C
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_CRG_TERM_TMR_CTRL_REG.tochar(), "\x9C");    
        // BQ24295_PWR_ON_CONFIG_REG to 0x2B
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_PWR_ON_CONFIG_REG.tochar(), "\x2B");
        // BQ24295_CRG_VOLT_CTRL_REG to 0x82, 
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_CRG_VOLT_CTRL_REG.tochar(), "\x82");
        // BQ24295_CRG_CURR_CTRL_REG to 0x00,
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_CRG_CURR_CTRL_REG.tochar(), "\x00");
        // BQ24295_PCRG_TERM_CURR_CTRL_REG to 0x10
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_PCRG_TERM_CURR_CTRL_REG.tochar(), "\x10");

        // Test setChargeCurrentOptimizer in range
        _charger.enable({
            "setChargeTerminationCurrentLimit" : 500
        });

        // Write commands in enable:
            // (BQ24295_CRG_TERM_TMR_CTRL_REG toggle bits 4-5 to 0, Expected: 0x8C) Disable watchdog 
            // (BQ24295_PWR_ON_CONFIG_REG toggle bit 4 to 1, Expected: 0x3B) Set CHG_CONFIG to enable charging 
            // (BQ24295_CRG_VOLT_CTRL_REG update bits 2-7, Expected: 0xB2) Set charge voltage, 4.208
            // (BQ24295_CRG_CURR_CTRL_REG update bits 2-7, Expected: 0x20) Set charge current, 1024
            // (BQ24295_PCRG_TERM_CURR_CTRL_REG update bits 0-3, Expected: 0x11) Set charge termination current, 256
        local expected = format("%c%s%c%s%c%s%c%s%c%s", 
            BQ24295_CRG_TERM_TMR_CTRL_REG, "\x8C", 
            BQ24295_PWR_ON_CONFIG_REG, "\x3B",
            BQ24295_CRG_VOLT_CTRL_REG, "\xB2",
            BQ24295_CRG_CURR_CTRL_REG, "\x20",
            BQ24295_PCRG_TERM_CURR_CTRL_REG, "\x12"     
        );
        local actual = _i2c._getWriteBuffer(BQ24295_DEFAULT_I2C_ADDR);
        assertEqual(expected, actual, "Enable setting charge termination current limit in range did not match expected results");
        
        _cleari2cBuffers();
        return "Enable setting charge termination current limit test passed";
    }

    function testEnableOutOfRangeLow() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();
        // Set readbuffer values
        // BQ24295_CRG_TERM_TMR_CTRL_REG to 0x8C
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_CRG_TERM_TMR_CTRL_REG.tochar(), "\x8C");    
        // BQ24295_PWR_ON_CONFIG_REG to 0x2B
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_PWR_ON_CONFIG_REG.tochar(), "\x2B");
        // BQ24295_CRG_VOLT_CTRL_REG to 0x82, 
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_CRG_VOLT_CTRL_REG.tochar(), "\x82");
        // BQ24295_CRG_CURR_CTRL_REG to 0x10,
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_CRG_CURR_CTRL_REG.tochar(), "\x10");
        // BQ24295_PCRG_TERM_CURR_CTRL_REG to 0x11
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_PCRG_TERM_CURR_CTRL_REG.tochar(), "\x11");

        // Test setChargeCurrentOptimizer in range
        _charger.enable({
            "voltage" : 3.0,
            "current" : 500,
            "setChargeTerminationCurrentLimit" : 100
        });

        // Write commands in enable:
            // (BQ24295_CRG_TERM_TMR_CTRL_REG toggle bits 4-5 to 0, Expected: 0x8C) Disable watchdog 
            // (BQ24295_PWR_ON_CONFIG_REG toggle bit 4 to 1, Expected: 0x3B) Set CHG_CONFIG to enable charging 
            // (BQ24295_CRG_VOLT_CTRL_REG update bits 2-7, Expected: 0x02) Set charge voltage, 3.504
            // (BQ24295_CRG_CURR_CTRL_REG update bits 2-7, Expected: 0x00) Set charge current, 512
            // (BQ24295_PCRG_TERM_CURR_CTRL_REG update bits 0-3, Expected: 0x10) Set charge termination current, 128
        local expected = format("%c%s%c%s%c%s%c", 
            BQ24295_CRG_TERM_TMR_CTRL_REG, "\x8C", 
            BQ24295_PWR_ON_CONFIG_REG, "\x3B",
            BQ24295_CRG_VOLT_CTRL_REG, "\x02",
            BQ24295_CRG_CURR_CTRL_REG
        ) + "\x00" + format("%c%s", BQ24295_PCRG_TERM_CURR_CTRL_REG, "\x10");

        local actual = _i2c._getWriteBuffer(BQ24295_DEFAULT_I2C_ADDR);
        assertEqual(expected, actual, "Enable settings with voltage, current and charge termination out of range low did not match expected results");
        
        _cleari2cBuffers();
        return "Enable settings with voltage, current and charge termination out of range low test passed";
    }

    function testEnableOutOfRangeHigh() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();
        // Set readbuffer values
        // BQ24295_CRG_TERM_TMR_CTRL_REG to 0xEC
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_CRG_TERM_TMR_CTRL_REG.tochar(), "\xEC");    
        // BQ24295_PWR_ON_CONFIG_REG to 0x3B
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_PWR_ON_CONFIG_REG.tochar(), "\x3B");
        // BQ24295_CRG_VOLT_CTRL_REG to 0x82, 
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_CRG_VOLT_CTRL_REG.tochar(), "\x82");
        // BQ24295_CRG_CURR_CTRL_REG to 0x10,
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_CRG_CURR_CTRL_REG.tochar(), "\x10");
        // BQ24295_PCRG_TERM_CURR_CTRL_REG to 0x11
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_PCRG_TERM_CURR_CTRL_REG.tochar(), "\x11");

        // Test setChargeCurrentOptimizer in range
        _charger.enable({
            "voltage" : 5.0,
            "current" : 3500,
            "setChargeTerminationCurrentLimit" : 2500
        });

        // Write commands in enable:
            // (BQ24295_CRG_TERM_TMR_CTRL_REG toggle bits 4-5 to 0, Expected: 0xCC) Disable watchdog 
            // (BQ24295_PWR_ON_CONFIG_REG toggle bit 4 to 1, Expected: 0x3B) Set CHG_CONFIG to enable charging 
            // (BQ24295_CRG_VOLT_CTRL_REG update bits 2-7, Expected: 0xE2) Set charge voltage, 4.400
            // (BQ24295_CRG_CURR_CTRL_REG update bits 2-7, Expected: 0x9C) Set charge current, 3008
            // (BQ24295_PCRG_TERM_CURR_CTRL_REG update bits 0-3, Expected: 0x1F) Set charge termination current, 2048
        local expected = format("%c%s%c%s%c%s%c%s%c%s", 
            BQ24295_CRG_TERM_TMR_CTRL_REG, "\xCC", 
            BQ24295_PWR_ON_CONFIG_REG, "\x3B",
            BQ24295_CRG_VOLT_CTRL_REG, "\xE2",
            BQ24295_CRG_CURR_CTRL_REG, "\x9C", 
            BQ24295_PCRG_TERM_CURR_CTRL_REG, "\x1F"
        );

        local actual = _i2c._getWriteBuffer(BQ24295_DEFAULT_I2C_ADDR);
        assertEqual(expected, actual, "Enable settings with voltage, current and charge termination out of range high did not match expected results");
        
        _cleari2cBuffers();
        return "Enable settings with voltage, current and charge termination out of range high test passed";
    }

    function testDisable() {
        // Note: Limitation of stubbed class, all read values are set before enable
        // so 2 set bit calls back to back are not effected by register write commands
        _cleari2cBuffers();
        // BQ24295_CRG_TERM_TMR_CTRL_REG to 0xCC
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_CRG_TERM_TMR_CTRL_REG.tochar(), "\xCC");    
        // BQ24295_PWR_ON_CONFIG_REG to 0x3B
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_PWR_ON_CONFIG_REG.tochar(), "\x3B");

        // Test setChargeCurrentOptimizer in range
        _charger.disable();

        // Write commands in enable:
            // (BQ24295_CRG_TERM_TMR_CTRL_REG set bits 4-5 to 0, Expected: 0xCC) Disable watchdog 
            // (BQ24295_PWR_ON_CONFIG_REG set bit 4 to 1, Expected: 0x2B) Set CHG_CONFIG to enable charging  
        local expected = format("%c%s%c%s", 
            BQ24295_CRG_TERM_TMR_CTRL_REG, "\xCC",
            BQ24295_PWR_ON_CONFIG_REG, "\x2B"
        );
        local actual = _i2c._getWriteBuffer(BQ24295_DEFAULT_I2C_ADDR);
        assertEqual(expected, actual, "Disable did not match expected results");
        
        _cleari2cBuffers();
        return "Disable test passed";
    }

    function testGetChargeVoltage() {
        // Test that BQ24295_CRG_VOLT_CTRL_REG set to known val, getChargeVoltage returns expected value
        _cleari2cBuffers();
        // Set readbuffer values
        // BQ24295_CRG_VOLT_CTRL_REG to 0xD6
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_CRG_VOLT_CTRL_REG.tochar(), "\xD6");

        local expected = 4.352;
        local actual = _charger.getChargeVoltage();
        assertEqual(expected, actual, "Get charge voltage did not match expected results");
        
        _cleari2cBuffers();
        return "Get charge voltage test passed";
    }

    function testGetInputStatus() {
        // Test that BQ24295_SYS_STAT_REG & BQ24295_IN_SRC_CTRL_REG set to known vals, getInputStatus returns expected value
        _cleari2cBuffers();
        // Set readbuffer values
        // BQ24295_SYS_STAT_REG to 0xFF
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_SYS_STAT_REG.tochar(), "\xFF");
        // BQ24295_IN_SRC_CTRL_REG to 0x5B
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_IN_SRC_CTRL_REG.tochar(), "\x5B");

        local expectedVBus   = BQ24295_VBUS_STATUS.OTG;
        local expectedInCurr = 900;
        local actual = _charger.getInputStatus();
        assertTrue(("vbusStatus" in actual && "inputCurrentLimit" in actual) "Get input status did return expected table slots");
        assertEqual(expectedVBus, actual.vbusStatus, "Get input status VBUS status did not match expected results");
        assertEqual(expectedInCurr, actual.inputCurrentLimit, "Get input status input current limit did not match expected results");

        _cleari2cBuffers();
        return "Get input status test passed";
    }

    function testGetChargingStatus() {
        // Test that BQ24295_SYS_STAT_REG set to known val, getChargingStatus returns expected value
        _cleari2cBuffers();
        // Set readbuffer values
        // BQ24295_SYS_STAT_REG to 0xAF
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_SYS_STAT_REG.tochar(), "\xAF");

        local expected = BQ24295_CHARGING_STATUS.FAST_CHARGING;
        local actual = _charger.getChargingStatus();
        assertEqual(expected, actual, "Get charging status did not match expected results");

        _cleari2cBuffers();
        return "Get charging status test passed";
    }

    function testGetChargerFaults() {
        // Test that BQ24295_NEW_FAULT_REG set to known val, getChargerFaults returns expected value
        _cleari2cBuffers();
        // Set readbuffer values
        // BQ24295_NEW_FAULT_REG to 0xFA
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_NEW_FAULT_REG.tochar(), "\xFA");

        local expectedWatchdog   = true;
        local expectedBoostFault = true;
        local expectedChrgFault  = BQ24295_CHARGING_FAULT.CHARGE_TIMER_EXPIRATION;
        local expectedBattFault  = true;
        local expectedNtcFault   = BQ24295_NTC_FAULT.TS_COLD;
        local actual = _charger.getChargerFaults();

        assertTrue("watchdogFault" in actual, "Get charging faults table missing watchdog slot");
        assertTrue("boostFault" in actual, "Get charging faults table missing boost slot");
        assertTrue("chrgFault" in actual, "Get charging faults table missing charge slot");
        assertTrue("battFault" in actual, "Get charging faults table missing battery slot");
        assertTrue("ntcFault" in actual, "Get charging faults table missing NTC slot");
        assertEqual(expectedWatchdog, actual.watchdogFault, "Get charging faults watchdog did not match expected results");
        assertEqual(expectedBoostFault, actual.boostFault, "Get charging faults boost did not match expected results");
        assertEqual(expectedChrgFault, actual.chrgFault, "Get charging faults charge did not match expected results");
        assertEqual(expectedBattFault, actual.battFault, "Get charging faults battery did not match expected results");
        assertEqual(expectedNtcFault, actual.ntcFault, "Get charging faults NTC did not match expected results");

        _cleari2cBuffers();
        return "Get charging faults test passed";
    }

    function testReset() {
        // Note: Limitation of stubbed class, all read values are set before method is called, if inside the 
        // method a value is updated and read again (ie set reg bit called on the same register 2X) the second
        // read will not reflect the updates made by the setter inside the function.
        _cleari2cBuffers();
        // Set read buffer for a read of bit 7 in BQ24295_PWR_ON_CONFIG_REG
        _i2c._setReadResp(BQ24295_DEFAULT_I2C_ADDR, BQ24295_PWR_ON_CONFIG_REG.tochar(), "\x01");

        // Call reset
        _charger.reset();

        // Write commands in reset:
            // (BQ24295_PWR_ON_CONFIG_REG bit 7 to 1) Set reset bit
            // (BQ24295_PWR_ON_CONFIG_REG bit 7 to 0) Clear reset bit
        local expected = format("%c%s%c%s", 
            BQ24295_PWR_ON_CONFIG_REG, "\x81",
            BQ24295_PWR_ON_CONFIG_REG, "\x01"
        );

        local actual = _i2c._getWriteBuffer(BQ24295_DEFAULT_I2C_ADDR);
        assertEqual(expected, actual, "Reset did not match expected results");
        
        _cleari2cBuffers();
        return "Reset test passed";
    }

    function tearDown() {
        return "Stubbed hardware tests finished.";
    }

}