#!/bin/bash

matlab -nodisplay -r "try, rtw.asap2SetAddress('hcu_main.a2l','fdc-bsp-m7.elf'), catch, quit(1), end, quit(0);";