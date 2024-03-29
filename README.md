# PARAMETERIZED-ASYNC-FIFO
A fully parameterized Asynchronous FIFO with a corresponding testbench, written in Verilog. The design is nearly full verified, but due to the nature of Asynchronous FIFOs and their extremely particular crossings, some transactions would have to either be verified by hand or modified into the current testbench. 

The testbench is very robust, and accounts for most read clock domain and write clock domain differences. However, there are some scenarios and timings that be result in the testbench incorrectly flagging a FIFO error. As such, all errors reported by the testbench must be verified, and have been listed as "Potential Errors to Inestigate" in the console log after simulation.
To my knowledge, the FIFO is operating entirely correctly.

## BLOCK DIAGRAM AND VARIABLE DEFINITIONS
![FIFO project diagram](https://github.com/JuniorBrice/PARAMETERIZED-ASYNC-FIFO/assets/79341423/73e9c6ea-5cf4-4c4c-a78e-d5ea3f5543f9)

### **--- ^In the diagram above^ ---**

data_in : data being written into the FIFO, of a parameterized width

data_out: data being read from the FIFO, of a parameterized width

we : write enable

re : read enable

wclk : write domain clock

rclk : read domain clock

w_rstn : write domain negative reset

r_rstn : read domain negative reset

full : FIFO is full

empty : FIFO is empty

b_wptr : binary write pointer

g_wptr : gray code write pointer

g_wptr_s : gray code write pointer synched to read domain

b_rptr : binary read pointer

g_rptr : gray code read pointer

g_rptr_s : gray code read pointer synched to write domain

###**--- Others you will encounter in the design/testbench ---**

b_wptr_next : binary write pointer next address

g_wptr_next : gray code write pointer next address

b_rptr_next : binary read pointer next address

g_rptr_next : gray code read pointer next address

b_rptr_s : binary read pointer synched to write domain

b_wptr_s : binary write pointer synched to read domain
