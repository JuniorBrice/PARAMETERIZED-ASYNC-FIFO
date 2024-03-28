module fifo_memory #(parameter DEPTH = 16, DATA_WIDTH = 8, PTR_WIDTH = 4)(
    input wclk, we,
    input [PTR_WIDTH:0] b_wptr, b_rptr,
    input [DATA_WIDTH-1:0] data_in,
    input full,
    output [DATA_WIDTH-1:0] data_out
    );

    reg [DATA_WIDTH-1:0] memory [DEPTH-1:0];
    
    always@(posedge wclk) begin
        if(we & !full) begin
            memory[b_wptr[PTR_WIDTH-1:0]] <= data_in;
         end
     end
     
    //no need to syncronize since the data is already synchronized by the read pointer in the read pointer contorl block.
    assign data_out = memory[b_rptr[PTR_WIDTH-1:0]];
    
endmodule