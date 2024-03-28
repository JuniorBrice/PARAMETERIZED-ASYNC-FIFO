module async_fifo #(parameter DATA_WIDTH = 8, DEPTH = 16)(
    input wclk,
    input w_rstn,
    input rclk,
    input r_rstn,
    input we,
    input re,
    input [DATA_WIDTH-1:0] data_in,
    output [DATA_WIDTH-1:0] data_out,
    output h_full,
    output full,
    output empty
    );
    
    localparam PTR_WIDTH = $clog2(DEPTH); /*assigning localparam PTR_WIDTH the value
               of ceiling(log2(DEPTH)), which is synthesizeable and returns the the 
               number of bits necessary to store the value of DEPTH. For instance
               $clog2(15) would return 4, since 4 bits are necessary to store a value of 15.*/
               
    //proper wires we need to connect the FIFO
    wire [PTR_WIDTH:0] g_wptr_s, g_rptr_s;
    wire [PTR_WIDTH:0] b_wptr, b_rptr;
    wire [PTR_WIDTH:0] g_wptr, g_rptr;
    
    //wire addresses for the FIFO
    wire [PTR_WIDTH-1:0] raddr, waddr;
    
    //the read and write pointer synchronizers for the FIFO
    synchronizer #(PTR_WIDTH) wptr_sync (.clk(rclk), .rstn(r_rstn), .d_in(g_wptr), .d_out(g_wptr_s));
    synchronizer #(PTR_WIDTH) rptr_sync (.clk(wclk), .rstn(w_rstn), .d_in(g_rptr), .d_out(g_rptr_s)); 
    
    //read and write pointer control blocks
    wptr_ctrl #(.PTR_WIDTH(PTR_WIDTH), .DEPTH(DEPTH)) wptr_control (.wclk(wclk), .w_rstn(w_rstn), .we(we),
                    .g_rptr_s(g_rptr_s), .b_wptr(b_wptr), .g_wptr(g_wptr), .h_full(h_full), .full(full));
    
    rptr_ctrl #(.PTR_WIDTH(PTR_WIDTH)) rptr_control (.rclk(rclk), .r_rstn(r_rstn), .re(re), .g_wptr_s(g_wptr_s),
                    .b_rptr(b_rptr), .g_rptr(g_rptr), .empty(empty));
    
    //the FIFO memory
    fifo_memory #(.DEPTH(DEPTH), .DATA_WIDTH(DATA_WIDTH), .PTR_WIDTH(PTR_WIDTH)) fmemory (.wclk(wclk), .we(we),
                    .b_wptr(b_wptr), .b_rptr(b_rptr), .data_in(data_in), .full(full), .data_out(data_out));

endmodule