parameter DATA_WIDTH = 8; // data witdh that will be passed to FIFO

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//TRANSACTION CLASS ----------------------------------------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class transaction;
   
    rand bit [1:0] mode; /*will be used to set the current operation mode of the fifo. the MSB will
                            control the write enable signal, the LSB the read enable. */
   
    //fifo inputs
    bit we, re;                 
    bit [DATA_WIDTH-1:0] data_in;
    //fifo outputs 
    bit [DATA_WIDTH-1:0] data_out;
    bit h_full, full, empty;
    
    /*basic constraint to ensure the fifo is reading and writing in every possible combination an equal
    amount of time*/
    constraint mode_ctrl {
        mode dist {2'b01 :=0, 2'b10 := 0, 2'b11 := 1 };
    }
    
    //deep copy method if needed
    virtual function transaction copy();
        copy = new();
        copy.we = this.we;
        copy.re = this.re;
        copy.data_in = this.data_in;
        copy.data_out = this.data_out;
        copy.h_full = this.h_full;
        copy.full = this.full;
        copy.empty = this.empty;
    endfunction     
endclass

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//INTERFACE ------------------------------------------------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

interface async_fifo_if (input rclk, input wclk);
    
    logic we;
    logic w_rstn;
    logic re;
    logic r_rstn;                 
    logic [DATA_WIDTH-1:0] data_in;
    logic [DATA_WIDTH-1:0] data_out;
    logic h_full;
    logic full;
    logic empty;
     
endinterface

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//GENERATOR CLASS ------------------------------------------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class generator;
    transaction trans;
    mailbox #(transaction) mbx;
    event next; //event coming from scoreboard signaling to continue generating stimuli
    event done; //event to aid in the completion of the simulation
    
    int count = 0; /*this count will be responsible for keeping track of the number of stimuli we
                    will send to the DUT*/
    
    int i = 0; // this count is just to keep track of the current iteration.
    
    //custom contructor where we expect the mailbox argument from tb_top
    function new (mailbox #(transaction) mbx);
        this.mbx = mbx;
        trans = new();
    endfunction
    
    task main;
        repeat(count)begin
                assert(trans.randomize) else $error("Randomization Failed at time %0d", $time);
                    i++;
                    mbx.put(trans);
                    $display("[GEN] : Mode : %b, Iteration: %0d", trans.mode, i);
                    @(next); //waiting for the scoreboard to give us the go ahead to continue.     
        end
        -> done;
    endtask
    
endclass

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//DRIVER CLASS ---------------------------------------------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class driver;
    virtual async_fifo_if afifo_if; /*interface declared outside of the driver hence virtual
                                       keyword. Will be connecting the interface in top tb*/
    transaction data;
    mailbox #(transaction) mbx;
    
    //custom contructor where we expect the mailbox argument from tb_top                
    function new (mailbox #(transaction) mbx);
        this.mbx = mbx;
    endfunction
    
    //task to reset the FIFO 
    task reset();
        afifo_if.r_rstn <= 1'b0;
        afifo_if.w_rstn <= 1'b0;
        afifo_if.re <= 1'b0;
        afifo_if.we <= 1'b0;
        afifo_if.data_in <= 0;
        fork 
            repeat (5) @(posedge afifo_if.wclk);
            repeat (5) @(posedge afifo_if.rclk);        
        join
        afifo_if.w_rstn <= 1'b1;
        afifo_if.r_rstn <= 1'b1;
        $display("[DRV] : DUT Reset Complete");
        $display("-----------------------------------------------------------------------------------------");
    endtask
    
    //task to write a random byte of data into the fifo
    task write();
        @(posedge afifo_if.wclk);
        afifo_if.w_rstn <= 1'b1;
        afifo_if.we <= 1'b1;
        afifo_if.data_in <= $urandom_range(0, 255);
        @(posedge afifo_if.wclk);
        afifo_if.we <= 1'b0;      
        $display("[DRV] : Data written to fifo, Data : %0d", afifo_if.data_in);  
        repeat (3)@(posedge afifo_if.wclk);
    endtask
    
    //task to read a byte of data from the fifo
    task read();  
        @(posedge afifo_if.rclk);
        afifo_if.r_rstn <= 1'b1;
        afifo_if.re <= 1'b1;
        @(posedge afifo_if.rclk);
        afifo_if.re <= 1'b0;      
        $display("[DRV] : Data read from fifo.");  
         repeat (3)@(posedge afifo_if.rclk);
  endtask
    
    //main generator task
    task main();
        forever begin
          
          //getting our mail
          mbx.get(data);
          
          // Using "mode" from the transaction class to apply a random stimulus to the DUT
            if (data.mode == 2'b01)begin
                read();
            end else if (data.mode == 2'b10)begin
                write();
            end else if (data.mode == 2'b11) begin
                fork
                    write();
                    read();
                join
            end  
        end  
    endtask   
endclass

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//MONITOR CLASS --------------------------------------------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class monitor;
 
    virtual async_fifo_if afifo_if; /*interface declared outside of the monitor hence virtual
                                       keyword. Will be connecting the interface in top tb*/
    transaction trans;
    mailbox #(transaction) mbx;
    
    //custom contructor where we expect the mailbox argument from tb_top                
    function new (mailbox #(transaction) mbx);
        this.mbx = mbx;
    endfunction
    
    task write_monitor();
            repeat (2) @(posedge afifo_if.wclk);
            trans.we = afifo_if.we;
            trans.data_in = afifo_if.data_in;
            trans.h_full = afifo_if.h_full;
            trans.full = afifo_if.full;
             repeat (3)@(posedge afifo_if.wclk);
    endtask
    
    task read_monitor();
            repeat (2) @(posedge afifo_if.rclk);
            trans.re = afifo_if.re;
            trans.empty = afifo_if.empty; 
            @(posedge afifo_if.rclk);
            trans.data_out = afifo_if.data_out;
            repeat (2) @(posedge afifo_if.rclk);
    endtask
 
    task main();
        trans = new();
        
        forever begin
            
            fork
                write_monitor();
                read_monitor();
            join
            
            mbx.put(trans);
            $display("[MON] : we: %0d, re: %0d, data_in: %0d, data_out: %0d, h_full: %0d, full: %0d, empty: %0d", 
                        trans.we, trans.re, trans.data_in, trans.data_out, trans.h_full, trans.full, trans.empty);            
        end
    
    endtask
  
endclass

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//SCOREBOARD CLASS ----------------------------------------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class scoreboard;
  
    mailbox #(transaction) mbx; 
    transaction trans;  
    event next;
    
    bit wclk_faster_than_rclk; /*This variable informs the scoreboard which clock of the DUT is faster.
                                 It is necesary to be able generate an accurate ground truth/golden data.
                                 The scoreboard will use it to determine which queue operation to perform
                                 first. pop_back or push_front.*/
    bit [7:0] din[$]; // queue to store written data
    bit [7:0] temp;   // temporary reg
    int err = 0;      // error count

    
    function new(mailbox #(transaction) mbx, input bit wclk_faster_than_rclk);
        this.mbx = mbx;
        this.wclk_faster_than_rclk = wclk_faster_than_rclk;  
    endfunction;


 
  task main();
    forever begin
      mbx.get(trans);
      $display("[SCO] : we: %0d, re: %0d, data_in: %0d, data_out: %0d, h_full: %0d, full: %0d, empty: %0d", 
                    trans.we, trans.re, trans.data_in, trans.data_out, trans.h_full, trans.full, trans.empty);
                  
        if(trans.we == 0 && trans.re == 1)begin //checking the write enable and read enable signals of our DUT
        //if just read, do this
                if (trans.empty == 1'b0) begin 
                    
                    /*Accounting for 1. Async fifo snchronization delay (necessary for two domains with very similar clock speeds), and 
                    2. The nature of operation for my d_out signal in the "fifo_memory.sv" module.  */
                        temp = din.pop_back();
                    
                    if (trans.data_out == temp)begin
                        $display("[SCO] : DATA MATCH. Data read from queue(%0d entries remaining). Interface data: %0d, queue data: %0d", din.size, trans.data_out, temp);
                    end else begin
                        $error("[SCO] : DATA MISMATCH. Data read from queue(%0d entries remaining). Interface data: %0d, queue data: %0d", din.size, trans.data_out, temp);
                        err++;
                    end       
                end else begin
                    $display("[SCO] : FIFO IS EMPTY");
                end
                
                $display("----------------------------------------------------------------------------");  
        
        end else if (trans.we == 1 && trans.re == 0) begin 
        //if just just write, do this        
                if (trans.full == 1'b0) begin
                    din.push_front(trans.data_in);
                    $display("[SCO] : DATA STORED IN QUEUE :%0d. (%0d total entries)", trans.data_in, din.size);
                end else begin
                    $display("[SCO] : FIFO is full");
                end
                    $display("----------------------------------------------------------------------------");   
              
        end else if (trans.we == 1 && trans.re == 1) begin 
        //if both read and write, which has a faster clock?
            if(wclk_faster_than_rclk)begin //if the write clock is faster or equal to the read, do this
                    
                    if (trans.full == 1'b0) begin //write to the queue first----------------------------------------
                        din.push_front(trans.data_in);
                        $display("[SCO] : DATA STORED IN QUEUE :%0d. (%0d total entries)", trans.data_in, din.size);
                    end else begin
                        $display("[SCO] : FIFO is full. (%0d total entries)", din.size);
                    end
                    
                            /*read the queue second and ignore outdated empty flag from transaction class. We know
                              there is readable data in the FIFO*/
                    temp = din.pop_back();
                    if (trans.data_out == temp)begin
                        $display("[SCO] : DATA MATCH. Data read from queue(%0d entries remaining). Interface data: %0d, queue data: %0d", din.size, trans.data_out, temp);
                    end else begin
                        $error("[SCO] : DATA MISMATCH. Data read from queue(%0d entries remaining). Interface data: %0d, queue data: %0d", din.size, trans.data_out, temp);
                        err++;
                    end               
                    $display("----------------------------------------------------------------------------");   
                      
            end else begin  //if the read clock is MUCH faster than the write, do this
            
                        /*write to the queue and ignore any outdated full flag from transaction class. We know
                           there is space in the FIFO*/
                        din.push_front(trans.data_in);
                        $display("[SCO] : DATA STORED IN QUEUE :%0d. (%0d total entries)", trans.data_in, din.size);
                    
                    if (trans.empty == 1'b0) begin //read the queue,----------------------------------------------
                     
                                            
                            temp = din.pop_back();
                        
                        if (trans.data_out == temp)begin
                            $display("[SCO] : DATA MATCH. Data read from queue(%0d entries remaining). Interface data: %0d, queue data: %0d", din.size, trans.data_out, temp);
                        end else begin
                            $error("[SCO] : DATA MISMATCH. Data read from queue(%0d entries remaining). Interface data: %0d, queue data: %0d", din.size, trans.data_out, temp);
                            err++;
                        end       
                    end else begin
                        $display("[SCO] : FIFO IS EMPTY (%0d entries in queue)", din.size);
                    end
                    


                    $display("----------------------------------------------------------------------------"); 
                                              
                  end
                  
            end
            -> next;       
      end  
  endtask
  
endclass

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ENVIRONMENT CLASS-----------------------------------------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class environment;
    
    generator gen;
    driver drv;
    monitor mon;
    scoreboard sco;
    mailbox #(transaction) gen2drv;  // Generator + Driver mailbox
    mailbox #(transaction) mon2sco;  // Monitor + Scoreboard mailbox
    virtual async_fifo_if afifo_if;
    
    function new(virtual async_fifo_if afifo_if,  input bit wclk_faster_than_rclk);
        gen2drv = new();
        gen = new(gen2drv);
        drv = new(gen2drv);
        mon2sco = new();
        mon = new(mon2sco);
        sco = new(mon2sco, wclk_faster_than_rclk);
        this.afifo_if = afifo_if;
        drv.afifo_if = this.afifo_if;
        mon.afifo_if = this.afifo_if;
        gen.next = sco.next;
    endfunction
  
    task pre_test();
        drv.reset();
    endtask
  
    task test();
        fork
            gen.main();
            drv.main();
            mon.main();
            sco.main();
        join_any
    endtask
  
    task post_test();
        wait(gen.done.triggered);  
        $display("---------------------------------------------");
        $display("Potential Errors to Investigate : %0d", sco.err);
        $display("---------------------------------------------");
        $finish();
    endtask
  
    task run();
        pre_test();
        test();
        post_test();
    endtask
      
endclass

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//TOP LEVEL TESTBENCH--------------------------------------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module async_fifo_tb();
    
    parameter WCLK_PERIOD = 20;
    parameter RCLK_PERIOD = 7;
    
    bit rclk, wclk;
    
    bit wclk_faster_than_rclk = (RCLK_PERIOD >= WCLK_PERIOD);
    
    initial begin
        rclk = 0;
        wclk = 0;
    end 
    
    always #RCLK_PERIOD rclk = ~rclk;
    always #WCLK_PERIOD wclk = ~wclk;

    async_fifo_if afifo_if(.rclk(rclk), .wclk(wclk));
    async_fifo #(.DATA_WIDTH(DATA_WIDTH)) DUT (.wclk(afifo_if.wclk), .w_rstn(afifo_if.w_rstn),
                    .rclk(afifo_if.rclk), .r_rstn(afifo_if.r_rstn), .we(afifo_if.we), .re(afifo_if.re), .data_in(afifo_if.data_in),
                    .data_out(afifo_if.data_out), .h_full(afifo_if.h_full), .full(afifo_if.full), .empty(afifo_if.empty));
    
    environment env;
    
    initial begin
        env = new(afifo_if, wclk_faster_than_rclk);
        env.gen.count = 20;
        env.run();
    end
    
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end
  
endmodule
