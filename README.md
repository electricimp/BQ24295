# BQ24295 #

This library provides a driver for the [Texas Instruments BQ24295](http://www.ti.com/lit/ds/symlink/bq24295.pdf) switch-mode battery charge and system power management device for single-cell Li-Ion and Li-polymer batteries. The BQ24295 supports high input voltage fast charging and communicates over an I&sup2;C interface.

**To include this library in your project, add** `#require "BQ24295.device.lib.nut:1.0.0"` **at the top of your device code.**

## Class Usage ##

### Constructor: BQ24295(*i2cBus[, i2cAddress]*) ###

The constructor does not configure the battery charger. It is therefore strongly recommended that the [*enable()*](#enablesettings) method is called to configure the charger with settings for you battery immediately after calling the constructor and on cold boots.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *i2cBus* | imp i2c bus object | Yes | The imp I&sup2;C bus that the BQ24295 is connected to. The I&sup2;C bus **must** be pre-configured &mdash; the library will not configure the bus |
| *i2cAddress* | Integer | No | The BQ24295's I&sup2;C address. Default: 0xD6 |

#### Example ####

```squirrel
#require "BQ24295.device.lib.nut:1.0.0"

// Alias and configure an impC001 I2C bus
local i2c = hardware.i2cKL;
i2c.configure(CLOCK_SPEED_400_KHZ);

// Instantiate a BQ24295 object
batteryCharger <- BQ24295(i2c);
```

## Class Methods ##

### enable(*[settings]*) ###

This method configures and enables the battery charger with settings to perform a charging cycle when a battery is connected and an input source is available. It is recommended that this method is called immediately after the constructor and on cold boots with the settings for your battery. See [**Setting Up The BQ24295 Library For Your Battery**](./Examples/README.md) for guidance.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *settings* | Table | No | A table of settings &mdash; see [**Settings Options**](#settings-options), below |

##### Settings Options #####

| Key | Type | Description |
| --- | --- | --- |
| *voltage* | Float | The desired charge voltage in Volts. Range: 3.504V - 4.400V. Default: 4.208V. |
| *current* | Integer | The desired fast charge current limit in mA. Range: 512mA - 3008mA. Default: 1024mA. |
| *chrgTermLimit* | Integer | The current at which the charge cycle will be terminated when the battery voltage is above the recharge threshold. Range: 128mA - 2048mA. Default: 256mA |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
// Configure battery charger 4.2V to a maximum of 2000mA
local settings = { "voltage" : 4.2,
                   "current" : 2000 };
batteryCharger.enable(settings);
```

### disable() ###

This method disables the device's charging capabilities. The battery will not charge until [*enable()*](#enablesettings) is called.

#### Return Value ####

Nothing.

#### Example ####

```squirrel
// Disable charging
batteryCharger.disable();
```

### getChrgTermV() ###

This method gets the charge termination voltage for the battery.

#### Return Value ####

Float &mdash; The charge voltage limit in Volts.

#### Example ####

```squirrel
local voltage = batteryCharger.getChrgTermV();
server.log("Charge Termination Voltage: " + voltage + "V");
```

### getInputStatus() ###

This method reports the type of power source connected to the charger input as well as the resulting input current limit.

#### Return Value ####

Table &mdash; An input status report with the following keys:

| Key| Type | Description |
| --- | --- | --- |
| *vbus* | Integer| Possible input states &mdash; see [**V<sub>BUS</sub> Status**](#vsubbussub-status), below, for details |
| *currLimit* | Integer| 100-3000mA |

#### V<sub>BUS</sub> Status ####

| V<sub>BUS</sub> Status Constant | Value |
| --- | --- |
| *BQ24295_VBUS_STATUS.UNKNOWN* | 0x00 |
| *BQ24295_VBUS_STATUS.USB_HOST* | 0x40 |
| *BQ24295_VBUS_STATUS.ADAPTER_PORT* | 0x80 |
| *BQ24295_VBUS_STATUS.OTG* | 0xC0 |

#### Example ####

```squirrel
local inputStatus = batteryCharger.getInputStatus();
local msg = "";
switch(inputStatus.vbus) {
    case BQ24295_VBUS_STATUS.UNKNOWN:
        msg = "No input or DPDM detection incomplete";
        break;
    case BQ24295_VBUS_STATUS.USB_HOST:
        msg = "USB host";
        break;
    case BQ24295_VBUS_STATUS.ADAPTER_PORT:
        msg = "Adapter port";
        break;
    case BQ24295_VBUS_STATUS.OTG:
        msg = "OTG";
        break;
}

server.log("Charging mode: " + msg);
server.log("Input current limit: " + inputStatus.currLimit);
```

### getChrgStatus() ###

This method reports the battery charging status.

#### Return Value ####

Integer &mdash; A charging status constant:

| Charging Status Constant| Value |
| --- | --- |
| *BQ24295_CHARGING_STATUS.NOT_CHARGING* | 0x00 |
| *BQ24295_CHARGING_STATUS.PRE_CHARGE* | 0x10|
| *BQ24295_CHARGING_STATUS.FAST_CHARGE* | 0x20|
| *BQ24295_CHARGING_STATUS.CHARGE_TERMINATION_DONE* | 0x30 |

#### Example ####

```squirrel
local status = charger.getChrgStatus();
switch(status) {
    case BQ24295_CHARGING_STATUS.NOT_CHARGING:
        server.log("Battery is not charging");
        // Do something
        break;
    case BQ24295_CHARGING_STATUS.PRE_CHARGE:
        server.log("Battery pre-charging");
        // Do something
        break;
    case BQ24295_CHARGING_STATUS.FAST_CHARGING:
        server.log("Battery is fast charging");
        // Do something
        break;
    case BQ24295_CHARGING_STATUS.CHARGE_TERMINATION_DONE:
        server.log("Battery charge termination done");
        // Do something
        break;
}
```

### getChrgFaults() ###

This method reports possible charger faults.

#### Return Value ####

Table &mdash; A charger fault report with the following keys:

| Key/Fault | Type | Description |
| --- | --- | --- |
| *watchdog* | Bool | `true` if watchdog timer has expired, otherwise `false` |
| *boost* | Bool | `true` if V<sub>BUS</sub> overloaded in OTG, V<sub>BUS</sub> is OVP, or the battery is in any state that prevents the boost function from being started; otherwise `false` |
| *chrg* | Integer | A charging fault. See [**Charging Faults**](#charging-faults), below, for possible values |
| *batt* | Bool| `true` if battery OVP, otherwise `false` |
| *ntc* | Integer | An NTC fault. See [**NTC Faults**](#ntc-faults), below, for possible values |

#### Charging Faults ####

| Charging Fault Constant | Value |
| --- | --- |
| *BQ24295_CHARGING_FAULT.NORMAL* | 0x00 |
| *BQ24295_CHARGING_FAULT.INPUT_FAULT* | 0x10 |
| *BQ24295_CHARGING_FAULT.THERMAL_SHUTDOWN* | 0x20 |
| *BQ24295_CHARGING_FAULT.CHARGE_TIMER_EXPIRATION* | 0x30 |

#### NTC Faults ####

| NTC Fault Constant | Value |
| --- | --- |
| *BQ24295_NTC_FAULT.NORMAL* | 0x00 |
| *BQ24295_NTC_FAULT.TS_HOT* | 0x01 |
| *BQ24295_NTC_FAULT.TS_COLD* | 0x02 |

#### Example ####

```squirrel
local faults = batteryCharger.getChrgFaults();
server.log("Fault Report:");
server.log("-----------------------------------);
if (faults.watchdog) server.log("Watchdog Timer Fault reported");
if (faults.boost) server.log("Boost Fault reported");
if (faults.batt) server.log("VBAT too high");

switch(faults.chrg) {
    case BQ24295_CHARGING_FAULT.NORMAL:
        server.log("Charging OK");
        break;
    case BQ24295_CHARGING_FAULT.INPUT_FAULT:
        server.log("Charging NOT OK - Input Fault reported: OVP or bad source");
        break;
    case BQ24295_CHARGING_FAULT.THERMAL_SHUTDOWN:
        server.log("Charging NOT OK - Thermal Shutdown reported");
        break;
    case BQ24295_CHARGING_FAULT.CHARGE_TIMER_EXPIRATION:
        server.log("Charging NOT OK - Charge Timer expired");
        break;
}

switch(faults.ntc) {
    case BQ24295_NTC_FAULT.NORMAL:
        server.log("NTC OK");
        break;
    case BQ24295_NTC_FAULT.TS_COLD:
        server.log("NTC NOT OK - TS Cold");
        break;
    case BQ24295_NTC_FAULT.TS_HOT:
        server.log("NTC NOT OK - TS Hot");
        break;
}
server.log("-----------------------------------);
```

### reset() ###

This method provides a software reset which clears all of the BQ24295's register settings.

**Note** This will reset the charge voltage and current to the register defaults: 4.208V and 1024mA. Please ensure that you confirm these are suitable for your battery &mdash; see [**Setting Up The BQ24295 Library For Your Battery**](./cxamples/README.md) for guidance. If the defaults are not appropriate for your battery, make sure you call [*enable()*](#enablesettings) with the correct settings **immediately** after calling *reset()*.

#### Return Value ####

Nothing.

#### Example ####

```squirrel
// Reset the BQ24295
batteryCharger.reset();
```

## License ##

This library is licensed under the [MIT License](LICENSE).