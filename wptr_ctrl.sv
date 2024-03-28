module wptr_ctrl #(parameter PTR_WIDTH = 4, DEPTH  = 16)(
    input wclk, w_rstn, we,
    input [PTR_WIDTH:0] g_rptr_s,
    output[PTR_WIDTH:0] b_wptr, g_wptr,
    output h_full,
    output full
    );
    
    /*wires for the next write pointer, one in regualr binary
    and one in gray code*/
    wire [PTR_WIDTH:0] b_wptr_next;
    wire [PTR_WIDTH:0] g_wptr_next;  
    
    //temporary output registers
    reg [PTR_WIDTH:0] g_wptr_temp;    
    reg [PTR_WIDTH:0] b_wptr_temp;
    reg h_full_temp;
    reg full_temp;
    
    //wires used later in the module to calculate the FIFO full/half full flags.
    wire [PTR_WIDTH:0] b_rptr_s;
    wire wrap_around;
    wire [PTR_WIDTH-1:0] max_ptr = (1 << PTR_WIDTH) - 1; /*calculating the maximum value 
                                                a pointer can hold, excluding wrap bit*/
    
    //counter that keeps track how many items are in thye FIFO for the full/half full flags
    reg [PTR_WIDTH:0] fifo_count;
    
    //caculating the next write pointers
    assign b_wptr_next = b_wptr + (we && !full);
    assign g_wptr_next = (b_wptr_next >> 1) ^ b_wptr_next;
  
    //the write pointer and FIFO count get 0 at reset
    always@(posedge wclk or negedge w_rstn) begin
        if(!w_rstn) begin
          b_wptr_temp <= 0; 
          g_wptr_temp <= 0;
        end
        else begin
          b_wptr_temp <= b_wptr_next; // increment the binary write pointer
          g_wptr_temp <= g_wptr_next; // increment the gray write pointer
        end
    end
 
 //FIFO COUNT BLOCK. block triggers whenever either of the clock synchronized pointers change
    always @(b_wptr or b_rptr_s) begin
//Check how many items are currently in the FIFO
        if (wrap_around) begin
            fifo_count = (max_ptr - b_rptr_s[PTR_WIDTH-1:0]) + b_wptr[PTR_WIDTH-1:0];/*if wrapped around,
                                                 the difference the the max pointer value and the read pointer,
                                                 plus the the write pointer value is the FIFO count.*/  
        end else begin
            fifo_count = b_wptr[PTR_WIDTH-1:0] - b_rptr_s[PTR_WIDTH-1:0]; /*if not wrapped around,
                                                 the difference between the write and read pointers
                                                 is the FIFO count*/
        end    
    end
    
  /*The full/half full flag is always 0 at reset, but may be 1 if the # of items in the
   FIFO == the depth of the FIFO, or if the # of items in the FIFO >= FIFO depth/2 respectively*/
  always@(posedge wclk or negedge w_rstn) begin
        if(!w_rstn)begin
            h_full_temp <= 0;
            full_temp <= 0;
        end else begin
            h_full_temp <= (fifo_count >= (DEPTH-1) >> 1)? 1:0;
            full_temp <= (fifo_count >= DEPTH-1)? 1:0;     
        end
  end
    
  g2b_converter #(.PTR_WIDTH(PTR_WIDTH)) g2b (
    .gray(g_rptr_s),
    .bin(b_rptr_s)
    ); /*binary to gray conversion of the synchronized read pointer to 
        use in the calcultion of the FIFO wrap bit*/
        
  assign wrap_around = b_rptr_s[PTR_WIDTH] ^ b_wptr[PTR_WIDTH]; /*the wrap around bit will be the XOR of
                                                      the MSB of the read and write pointers in binary format*/

  //output assignments
  assign b_wptr = b_wptr_temp;
  assign g_wptr = g_wptr_temp; 
  assign h_full = h_full_temp; //final synchronized half full flag assignment                                                
  assign full = full_temp; //final synchronized full flag assignment 
  
endmodule
