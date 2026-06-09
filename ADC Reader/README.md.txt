# ADC Reader — LTC2308

Reads analog voltage from a potentiometer using the onboard
LTC2308 12-bit ADC via 4-wire SPI, displays result in millivolts
on a 4-digit 7-segment display.

## Specifications
- ADC: LTC2308 (onboard, 8-channel, 12-bit, 500 ksps)
- Interface: SPI (SCK, SDI, SDO, CONVST)
- Input range: 0 — 4.096V
- Display: 0000 — 4095 mV

## How it works
FPGA sends channel config (0xC0 = CH0, single-ended, unipolar)
over SPI, reads back 12-bit result, converts to mV, displays
on multiplexed 7-segment display.