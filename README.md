# PARAMETERIZED-ASYNC-FIFO
A fully parameterized Asynchronous FIFO with a corresponding testbench, written in Verilog. The design is nearly full verified, but due to the nature of Asynchronous FIFOs and their extremely particular crossings, some transactions would have to either be verified by hand or modified into the current testbench. 

The testbench is very robust, and accounts for most read clock domain and write clock domain differences. However, there are some scenarios and timings that may result in the testbench incorrectly flagging a FIFO error. As such, all errors reported by the testbench must be verified, and have been listed as "Potential Errors to Inestigate" in the console log after simulation.

After much testing, I believe the FIFO to be operating within specification.

**All code is fully commented.** If something isn't mentioned/covered in the readme, please have a look and hopefully it answers any questions.

## BLOCK DIAGRAM AND BASIC OVERVIEW
![Fifo project diagram final](https://github.com/JuniorBrice/PARAMETERIZED-ASYNC-FIFO/assets/79341423/c41f3b52-9828-40ec-9c91-8b5442670705)

### Fifo Memory

Memory module (dual port circular memory) controlled by the read and write pointer control blocks, and is responsible for outputing data_out. The width and depth of this module can be customized in the top level module.

### Read and Write Pointer Controls

Responsible for keeping track of where the read and write pointers are, and transferring that information to Fifo Memory in binary format. These two blocks also communicate with one another, and are constantly being updated with the other's current position. This is done by transmitting their current pointer locations to one another in gray code (as to avoid glitches), and synchronizing that information to their current clock domain. The location information is used by each block to determine important varaibles like fifo_count (how many items are in the fifo), wrap_around (the fifo wrap around bit), h_full, full, and the empty flag. Each pointer control block is also equipped with its own gray to binary convertor.

### Synchronizers

Basic synchronizers used to facilitate communication between the pointer control blocks.

## VARIABLE DEFINITIONS

### *_--- ^In the block diagram shown previously^ ---_*

Outputs are red, inputs are black.

**data_in :** data being written into the FIFO, of a parameterized width

**data_out :** data being read from the FIFO, of a parameterized width

**we :** write enable

**re :** read enable

**wclk :** write domain clock

**rclk :** read domain clock

**w_rstn :** write domain negative reset

**r_rstn :** read domain negative reset

**h_full :** FIFO is half full

**full :** FIFO is full

**empty :** FIFO is empty

**b_wptr :** binary write pointer

**g_wptr :** gray code write pointer

**g_wptr_s :** gray code write pointer synched to read domain

**b_rptr : **binary read pointer

**g_rptr :** gray code read pointer

**g_rptr_s :** gray code read pointer synched to write domain

### *_--- Others you will encounter in the design/testbench ---_*

**b_wptr_next :** binary write pointer next address

**g_wptr_next :** gray code write pointer next address

**b_rptr_next :** binary read pointer next address

**g_rptr_next :** gray code read pointer next address

**b_rptr_s :** binary read pointer synched to write domain

**b_wptr_s :** binary write pointer synched to read domain

**max_ptr :** the maximum possible value storable in either pointer

**wrap_around :** FIFO wrap around indicator

**fifo_count :** the number of items currently in the FIFO

**recently_empty :** the FIFO has been recently empty

## Vivado Elaboration (Dataflow Design Feature enabled)

![image](https://github.com/JuniorBrice/PARAMETERIZED-ASYNC-FIFO/assets/79341423/b229bc8d-3756-4209-93cc-9357810286c1)

## TESTBENCH OUTPUTS

### General Warning

**Reminder:** Due to the nature of CDCs, building an accurate testbench from scratch was difficult. While I think it is very robust even when presented with peculiar scenarios, there is a chance any errors it detects may be due to the slight missing of a variable change or something of that nature. As such, all errors are listed as _Potenial Errors to be investigated_., and require further testing/probing to see if it is truly a malfunction.

As the read and write clocks get farther and farther away from each other (giving the testbench time to catch all events), the more accurate the testbench becomes. In my experience **the FIFO is operating as intended**, and the testbench only trips up (may throw a false error) when the clock periods are within 5 ns (0.2 GHz) of one another but not equal, or when it runs into some other unforseen limitation. All investigations/inspections of waveforms concluded proper functionality! 

### General Explanation

The following output logs are relatively self explanatory, except for "Mode". The "Mode" of the Fifo/testbench just indicates whether the FIFO is doing a read operation, a write operation, or both. The MSB of "Mode" goes high when a write operation is being performed. The LSB goes high for a read operation. So,

Mode : 10 --> Fifo is only writing
Mode : 01 --> Fifo is only reading
Mode : 11 --> Fifo is both reading and writing

Here are some results.

### Results

### Write clock >> Read clock: 

![image](https://github.com/JuniorBrice/PARAMETERIZED-ASYNC-FIFO/assets/79341423/84ba2943-6799-493b-a04f-98bba3266f71)

#### Test case: 

wclk period = 13 ns (77 Mhz)

rclk period = 20 ns (50 Mhz)

Iterations: 20

Operation distribution --> Read 33.3%, Write 33.3%, Read & Write 33.3%.

**This log can be found in the testbench folder as "write_grt_read.txt"**

### Read clock >> Write clock: 

![image](https://github.com/JuniorBrice/PARAMETERIZED-ASYNC-FIFO/assets/79341423/b5854b4c-1137-4500-af28-159ec1dd9d58)

#### Test case: 

wclk period = 22 ns (45 Mhz)

rclk period = 17 ns (59 Mhz)

Iterations: 20

Operation distribution --> Read 40%, Write 40%, Read & Write 20%.

**This log can be found in the testbench folder as "read_grt_write.txt"**

### Read clock = Write clock: 

![image](https://github.com/JuniorBrice/PARAMETERIZED-ASYNC-FIFO/assets/79341423/88c3a888-28bd-497f-befb-fe6453acd311)

#### Test case: 

wclk period = 7 ns (142 Mhz)

rclk period = 7 ns (142 Mhz)

Iterations: 20

Operation distribution --> Read10%, Write 80%, Read & Write 10%.

**This log can be found in the testbench folder as "write_eq_read.txt"**



