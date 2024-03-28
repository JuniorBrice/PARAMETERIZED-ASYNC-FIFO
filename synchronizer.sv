//basic 2 flip flop synchronizer
module synchronizer #(parameter PTR_WIDTH = 4) (
    input clk, rstn,
    input [PTR_WIDTH:0] d_in, 
    output[PTR_WIDTH:0] d_out
    );
    
    reg [PTR_WIDTH:0] q;
    reg [PTR_WIDTH:0] d_out_temp;
    
    always@(posedge clk) begin
        if(!rstn) begin
          q <= 0;
          d_out_temp <= 0;
        end else begin
          q <= d_in;
          d_out_temp <= q;
        end
    end
    
    assign d_out = d_out_temp;
    
endmodule
