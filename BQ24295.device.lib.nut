// MIT License

// Copyright 2019 Electric Imp

// SPDX-License-Identifier: MIT

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

// I2C Register Addresses
const BQ24295_IN_SRC_CTRL_REG           = 0x00;
const BQ24295_PWR_ON_CONFIG_REG         = 0x01;
const BQ24295_CRG_CURR_CTRL_REG         = 0x02;
const BQ24295_PCRG_TERM_CURR_CTRL_REG   = 0x03;
const BQ24295_CRG_VOLT_CTRL_REG         = 0x04;
const BQ24295_CRG_TERM_TMR_CTRL_REG     = 0x05;
const BQ24295_BOOST_VOLT_THERM_CTRL_REG = 0x06;
const BQ24295_MISC_OP_CTRL_REG          = 0x07;
const BQ24295_SYS_STAT_REG              = 0x08;
const BQ24295_NEW_FAULT_REG             = 0x09;
const BQ24295_VEN_PT_REV_STAT_REG       = 0x0A;

// Enum helper for getChargeStatus() output
enum BQ24295_CHARGING_STATUS {
    NOT_CHARGING            = 0x00, // reg bits 4-5 = 00
    PRE_CHARGE              = 0x10, // reg bits 4-5 = 01
    FAST_CHARGING           = 0x20, // reg bits 4-5 = 10
    CHARGE_TERMINATION_DONE = 0x30  // reg bits 4-5 = 11
}

// Enum helper for vbusStatus in getInputStatus() output table
enum BQ24295_VBUS_STATUS {
    UNKNOWN      = 0x00, // reg bits 7-8 = 00 (no input or DPDM detection incomplete)
    USB_HOST     = 0x40, // reg bits 7-8 = 01
    ADAPTER_PORT = 0x80, // reg bits 7-8 = 10
    OTG          = 0xC0  // reg bits 7-8 = 11
}

// Enum helper for chrgFault in getChargingFaults() output table
enum BQ24295_CHARGING_FAULT {
    NORMAL                  = 0x00, // reg bits 4-5 = 00
    INPUT_FAULT             = 0x10, // reg bits 4-5 = 01 (OVP or bad source)
    THERMAL_SHUTDOWN        = 0x20, // reg bits 4-5 = 10
    CHARGE_TIMER_EXPIRATION = 0x30  // reg bits 4-5 = 11
}

// Enum helper for ntcFault in getChargingFaults() output table
enum BQ24295_NTC_FAULT {
    NORMAL,  // 00
    TS_HOT,  // 01
    TS_COLD  // 10
}

const BQ24295_DEFAULT_VOLTAGE        = 4.208;
const BQ24295_DEFULAT_CHRG_CURR      = 1024;
const BQ24295_DEFULAT_CHRG_TERM_CURR = 256;

class BQ24295 {

    static VERSION = "1.0.0";

    _i2c = null;
    _addr = null;

    constructor(i2c, addr = 0xD4) {
        _i2c = i2c;
        _addr = addr;
    }

    // Initialize battery charger with the included settings, calling with no settings will 
    // set default voltage and charge current.
    function enable(settings = {}) {
        // Disable Watchdog, so settings remain even through sleep cycles
        _disableWatchdog();

        // Set CHG_CONFIG bit (4) to charge enable (1)
        _setRegBit(BQ24295_PWR_ON_CONFIG_REG, 4, 1);
        
        // Set charge voltage
        local voltage = ("voltage" in settings) ? settings.voltage : BQ24295_DEFAULT_VOLTAGE;
        _setChargeVoltage(voltage);

        // Set charge current
        local curr = ("current" in settings) ? settings.current : BQ24295_DEFULAT_CHRG_CURR;
        _setChargingCurrent(curr);

        // Set charge termination current
        local termCurr = ("setChargeTerminationCurrentLimit" in settings) ? settings.setChargeTerminationCurrentLimit : BQ24295_DEFULAT_CHRG_TERM_CURR;
        _setChargeTerminationCurrent(termCurr);
    }

    // Clear the enable charging bit, device will not charge until enableCharging() is called again
    function disable() {
        // Disable Watchdog, to keep charger disabled setting even through sleep cycles
        _disableWatchdog();
        // Set CHG_CONFIG bit (4) to charge disable (0)
        _setRegBit(BQ24295_PWR_ON_CONFIG_REG, 4, 0);
    }

    // Returns the target battery voltage in volts. Default: 4.208V, Range: 3.504V - 4.400V.
    function getChargeVoltage() {
        local rv = _getReg(BQ24295_CRG_VOLT_CTRL_REG);

        // VREG bits 2-7, Resolution 16mV, Offset 3.504V, Range 3.504V - 4.400V
        local chrgVLim = ((rv >> 2) * 16) + 3504;
        // Convert mV to Volts
        return chrgV / 1000.0;
    }

    // Returns a table with slots vbusStatus (charging mode) and inputCurrentLimit.
    function getInputStatus() {
        // From datasheet INLIM register values mapped to mA values
        // 000 = 100mA,  001 = 150mA,  010 = 500mA,  011 = 900mA, 
        // 100 = 1000mA, 101 = 1500mA, 110 = 2000mA, 111 = 3000mA
        local inCurrVals = [100, 150, 500, 900, 1000, 1500, 2000, 3000];

        // Read VBUS status reg
        local vbus_rv = _getReg(BQ24295_SYS_STAT_REG); 
        // Read input current limit reg 
        local incurr_rv = _getReg(BQ24295_IN_SRC_CTRL_REG);

        // Return table with: 
        // vbusStatus - integer, value of VBUS_STAT bits (7-8). BQ24295_VBUS_STATUS
        // enum contains human readable names for the integer.
        // inputCurrentLimit - integer, value in mA
        return {
            "vbusStatus"        : vbus_rv & 0xC0, 
            "inputCurrentLimit" : inCurrVals[incurr_rv & 0x07]
        }
    }

    // Returns integer, value of CHRG_STAT bits (4-5). BQ24295_CHARGING_STATUS enum 
    // contains human readable names for the return integer.
    function getChargingStatus() {
        local rv = _getReg(BQ24295_SYS_STAT_REG);
        return rv & 0x30;
    }

    // Returns a table with slots watchdogFault, boostFault, chrgFault, battFault and ntcFault.
    function getChargerFaults() {
        local rv = _getReg(BQ24295_NEW_FAULT_REG);

        // Return table with: 
        // watchdogFault - bool: f = normal, t = timer expired
        // boostFault - bool: f = normal, t = VBUS overload in OTG, vbus OVP, batt too low/cannot start boost
        // chrgFault - integer, value of CHRG_FAULT bits (4-5), enum BQ24295_CHARGING_FAULT contains 
        // human readable names for integer
        // battFault - bool, f = normal, t = battery OVP
        // ntcFault - integer, value of NTC_FAULT bits (0-1), enum BQ24295_NTC_FAULT contains human
        // readable names for integer
        return {
            "watchdogFault" : (rv & 0x80) == 0x80,
            "boostFault"    : (rv & 0x40) == 0x40,
            "chrgFault"     : rv & 0x30, 
            "battFault"     : (rv & 0x08) == 0x08, 
            "ntcFault"      : rv & 0x02
        }
    }

    // Software reset
    function reset() {
        // Set reset bit
        _setRegBit(BQ24295_PWR_ON_CONFIG_REG, 7, 1);
        imp.sleep(0.01);
        // Clear reset bit
        _setRegBit(BQ24295_PWR_ON_CONFIG_REG, 7, 0);
    }

    //-------------------- PRIVATE METHODS --------------------//

    // Sets charge voltage, param should be in Volts. Default: 4.208V, Range: 3.504V - 4.400V
    function _setChargeVoltage(vreg) {
        // Convert to V to mV, ensure value is within range 3504mV and 4400mV
        // and calculate value with offset: 3.504V and resolution: 16mV 
        vreg = (_limit(vreg * 1000, 3504, 4400) - 3504) / 16;

        // Get current register value
        local rv = _getReg(BQ24295_CRG_VOLT_CTRL_REG);
        // Clear Charge Voltage Limit (VREG) bits (2-7)
        rv = rv & 0x03;
        // Update register value with new VREG value;
        rv = rv | ((vreg.tointeger() << 2) & 0xFC);
        _setReg(BQ24295_CRG_VOLT_CTRL_REG, rv);
    }

    // Sets charge current limit, param should be in mA. Default: 1024mA, Range: 512mA - 3008mA
    function _setChargingCurrent(curr) {
        // Ensure value is within range 512mA and 3008mA and calculate
        // value with offset: 512mA and resolution: 64mA         
        curr = (_limit(curr, 512, 3008) - 512) / 64;

        // Get current register value
        local rv = _getReg(BQ24295_CRG_CURR_CTRL_REG);
        // Clear Charge Current Limit (ICHG) bits (2-7)
        rv = rv & 0x03;

        // Update register value with new current (ICHG) value;
        rv = rv | ((curr.tointeger() << 2) & 0xFC);
        _setReg(BQ24295_CRG_CURR_CTRL_REG, rv);
    }

    // Sets charge termination current limit, param should be in mA. Default: 256mA, Range: 128mA - 2048mA
    function _setChargeTerminationCurrent(iterm) {
        // Ensure value is within range 128mA and 2048mA and calculate
        // value with offset: 128mA and resolution: 128mA         
        iterm = (_limit(iterm, 128, 2048) - 128) / 128;

        // Get current register value
        local rv = _getReg(BQ24295_PCRG_TERM_CURR_CTRL_REG);
        // Clear Termination Current Limit (ITERM) bits (0-3)
        rv = rv & 0xF0;

        // Update register value with new termination current (ITERM) value;
        rv = rv | (iterm.tointeger() & 0x0F);
        _setReg(BQ24295_PCRG_TERM_CURR_CTRL_REG, rv);
    }

    // Disables watchdog timer
    function _disableWatchdog() {
        // Set WATCHDOG reg bits (4-5) to 00
        local rv = _getReg(BQ24295_CRG_TERM_TMR_CTRL_REG);
        _setReg(BQ24295_CRG_TERM_TMR_CTRL_REG, rv & 0xCF);
    }

    // Helper to limit value to within specified range
    function _limit(val, min, max) {
        if (val < min) return min;
        if (val > max) return max;
        return val;
    }

    // Helper to get a register value
    function _getReg(reg) {
        local result = _i2c.read(_addr, reg.tochar(), 1);
        if (result == null) {
            throw "I2C read error: " + _i2c.readerror();
        }
        return result[0];
    }

    // Helper to set a register value
    function _setReg(reg, val) {
        local result = _i2c.write(_addr, format("%c%c", reg, (val & 0xff)));
        if (result) {
            throw "I2C write error: " + result;
        }
        return result;
    }

    // Helper to set a single bit in a register
    function _setRegBit(reg, bit, state) {
        local val = _getReg(reg);
        if (state == 0) {
            val = val & ~(0x01 << bit);
        } else {
            val = val | (0x01 << bit);
        }
        return _setReg(reg, val);
    }

}
