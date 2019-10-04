#!/bin/bash

hex2bin 0xFE00 acornMonitor-obj.hex acornMonitor-obj.bin
bin2hex 0x0000 acornMonitor-obj.bin acornMonitor-obj-0base.hex
