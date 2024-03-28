//general gray to binary converter used in the write pointer control block
module g2b_converter #(parameter PTR_WIDTH = 4)(
    input [PTR_WIDTH:0] gray,
    output[PTR_WIDTH:0] bin
    );
    
    assign bin[PTR_WIDTH] = gray[PTR_WIDTH];
    
    for(genvar i = PTR_WIDTH - 1; i >= 0; i = i-1) begin
        assign bin[i] = gray[i] ^ bin[i+1];
    end
    
endmodule
