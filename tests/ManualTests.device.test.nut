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

// When these test were written impOS i2c support was not available for the 
// imp006, so SofwareI2C class was used to bit bang i2c.
@include __PATH__+ "/SoftwareI2C.device.nut"

// From data sheet watchdog timer: default is 40s, max is 160s
const WATCHDOG_TEST_EXP_TIME_SEC = 165;

// NOTE: This test takes ~3m to run.
// This test requires hardware. Test currently configured for a imp006 breakout board
// rev1.0 with BQ24295 battery charger on i2cLM with no battery connected. Status test
// expected results may fail if battery is connected. 
class ManualWatchdogTest extends ImpTestCase {
    
    _i2c     = null;
    _charger = null;
    _hb      = null;
    _wdTimeoutStartTime = null;

    function setUp() {
        // imp006 breakout board, using bit bang i2c class
        // No battery connected - values in test may change if battery is attached
        // or imp is powered in a different way
        _i2c = softi2c(hardware.pinL, hardware.pinM);
        _i2c.configure(CLOCK_SPEED_400_KHZ);
        _charger = BQ24295(_i2c);

        _charger.reset();
        _charger.enable();
        return "Watchdog test setup complete.";
    }

    // Helper to let user know test is still running
    function heartbeat() {
        cancelHearbeat();
        logPercentWdTestDone();
        _hb = imp.wakeup(10, heartbeat.bindenv(this));
    }

    function logPercentWdTestDone() {
        local testRunTime = time() - _wdTimeoutStartTime;
        local percentDone = 100 * testRunTime /  WATCHDOG_TEST_EXP_TIME_SEC;
        info("Watchdog test running. Test " + percentDone + "% done.");
    }

    // Helper to stop heartbeat log
    function cancelHearbeat() {
        if (_hb != null) {
            imp.cancelwakeup(_hb);
            _hb = null;
        }
    }

    // Tests
    // ----------------------------------------------------------

    function testWatchdog() {
        // Maker sure the charger's has default settings
        _charger.reset();
        // Store default charge voltage (before enable)
        local defaultVoltage = _charger.getChrgTermV();
        // Enable with non-default settings
        _charger.enable({"voltage" : 3.0});

        // Check settings have changed after enable
        local userSetVoltage = _charger.getChrgTermV();
        assertTrue(defaultVoltage != userSetVoltage, "User set charge voltage should not match default voltage");
        
        // Wait to ensure watchdog timer has time to expire 
        return Promise(function(resolve, reject) {
            // Create a hearbeat log, so user sees that test is still running
            _wdTimeoutStartTime = time();
            heartbeat();
            // Check settings after watchdog would have reset (default is 40s, max is 160s)
            imp.wakeup(WATCHDOG_TEST_EXP_TIME_SEC, function() {
                cancelHearbeat();
                logPercentWdTestDone();
                local afterTimerVoltage = _charger.getChrgTermV();
                assertTrue(defaultVoltage != afterTimerVoltage, "User set charge voltage should not match default voltage");
                assertEqual(userSetVoltage, afterTimerVoltage, "User set charge voltage should be the same after " + WATCHDOG_TEST_EXP_TIME_SEC + "s");
                return resolve("Watchdog test passed");
            }.bindenv(this))
        }.bindenv(this))
    }

    function testEnable() {
        local voltage = 3.504;
        _charger.enable({"voltage" : voltage});
        local actual = _charger.getChrgTermV();

        assertEqual(voltage, actual, "Expected charge termination value of " + voltage + ", actual value: " + actual);

        return "Enable test passed.";
    }

    function testInputStatus() {
        local expCurr = 1000;
        local expVBUS = BQ24295_VBUS_STATUS.ADAPTER_PORT // UNKNOWN, USB_HOST, ADAPTER_PORT, OTG

        local actual = _charger.getInputStatus();

        assertEqual(expVBUS, actual.vbus, "Expected VBUS input status " + expVBUS + ", actual value: " + actual.vbus);
        assertEqual(expCurr, actual.currLimit, "Expected input current limit " + expCurr + ", actual value: " + actual.currLimit);

        return "Input status test passed.";
    }

    function testChargeFaults() {
        local expWatchdog = false;
        local expboost = false
        local charge = BQ24295_CHARGING_FAULT.NORMAL;   // NORMAL, INPUT_FAULT, THERMAL_SHUTDOWN, CHARGE_TIMER_EXPIRATION
        local battery = false;
        local ntc = BQ24295_NTC_FAULT.TS_COLD;           // NORMAL, TS_HOT, TS_COLD

        local actual = _charger.getChrgFaults();

        assertEqual(expWatchdog, actual.watchdog, "Expected watchdog fault " + expWatchdog + ", actual value: " + actual.watchdog);
        assertEqual(expboost, actual.boost, "Expected boost fault " + expboost + ", actual value: " + actual.boost);
        assertEqual(charge, actual.chrg, "Expected charge fault " + charge + ", actual value: " + actual.chrg);
        assertEqual(battery, actual.batt, "Expected battery fault " + battery + ", actual value: " + actual.batt);
        assertEqual(ntc, actual.ntc, "Expected ntc fault " + ntc + ", actual value: " + actual.ntc);

        return "Charge fault test passed.";
    }

    function testChargingStatus() {
        local expected = BQ24295_CHARGING_STATUS.NOT_CHARGING // NOT_CHARGING, PRE_CHARGE, FAST_CHARGING, CHARGE_TERMINATION_DONE

        local actual = _charger.getChrgStatus();

        assertEqual(expected, actual, "Expected VBUS input status " + expected + ", actual value: " + actual);

        return "Charging status test passed.";
    }

    // ----------------------------------------------------------

    function tearDown() {
        return "Watchdog tests finished.";
    }

}