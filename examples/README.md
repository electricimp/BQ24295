# Setting Up The BQ24295 Library For Your Battery #

## Important Battery Parameters ##

In order to set up the BQ24295 battery charger properly there are two important parameters that you need know for your specific battery: the charging voltage and the charging current limit.

## Finding Charging Parameters ##

In this example we will be looking at a [3.7V 2000mAh battery from Adafruit](https://www.adafruit.com/product/2011?gclid=EAIaIQobChMIh7uL6pP83AIVS0sNCh1NNQUsEAQYAiABEgKFA_D_BwE). This battery is labelled 3.7V but this is the nominal voltage and not the voltage required for charging. The label also shows its capacity to be 2000mAh but provides no specific charging current. This is not enough information to determine our charging parameters, so we must look for more information in the battery's [datasheet](LiIon2000mAh37V.pdf).

In Section 3, Form 1 there is a table describing the battery's rated performance characteristics. Looking at the fourth row of the table, we can see the charging voltage is 4.2V. Row six shows the quick charge current is 1CA. The C represents the battery capacity. Row 1 shows that the capacity is 2000mAh. This means that the quick charge current = 1 * 2000mA = 2000mA.

It is very important to find the correct values for these two parameters as exceeding them can damage your battery.

## Default Settings ##

The default settings for the BQ24295 are 4.208V and 1024mA. As you can see, the default settings for the BQ24295 are not ideal for this battery, which requires settings of 4.2V and 2000mAh, as we determined above. Therefore you will want to enable the battery with the correct settings as soon as the device boots. You do this as follows:

```squirrel
// Import the BQ24295 driver
#require "BQ24295.device.lib.nut:1.0.0"

// Choose an imp006 I2C bus and configure it
local i2c = hardware.i2cLM;
i2c.configure(CLOCK_SPEED_400_KHZ);

// Instantiate a BQ24295 object
batteryCharger <- BQ24295(i2c);

// Configure the charger to charge at 4.2V to a maximum of 2000mA
local settings = { "voltage" : 4.2,
                   "current" : 2000 };
batteryCharger.enable(settings);
```
