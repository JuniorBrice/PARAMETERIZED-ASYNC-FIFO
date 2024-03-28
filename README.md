# PARAMETERIZED-ASYNC-FIFO
A fully parameterized Asynchronous FIFO with a corresponding testbench, written in Verilog. The design is nearly full verified, but due to the nature of Asynchronous FIFOs and their extremely particular crossings, some transactions would have to either be verified by hand or modified into the current testbench. 

The testbench is very robust, and accounts for most read clock domain and write clock domain differences. However, there are some scenarios and timings that be result in the testbench incorrectly flagging a FIFO error. As such, all errors reported by the testbench must be verified, and have been listed as "Potential Errors to Inestigate" in the console log after simulation.
To my knowledge, the FIFO is operating entirely correctly.

## BLOCK DIAGRAM AND VARIABLE DEFINITIONS
![FIFO project diagram](https://github.com/JuniorBrice/PARAMETERIZED-ASYNC-FIFO/assets/79341423/73e9c6ea-5cf4-4c4c-a78e-d5ea3f5543f9)
