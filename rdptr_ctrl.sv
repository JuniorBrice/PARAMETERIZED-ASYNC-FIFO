module rptr_ctrl #(parameter PTR_WIDTH = 4)(
    input rclk, r_rstn, re,
    input [PTR_WIDTH:0] g_wptr_s,
    output[PTR_WIDTH:0] b_rptr, g_rptr,
    output empty
    );
    
    /*wire for the next read pointer, one in regualr binary
    and one in gray code*/
    wire [PTR_WIDTH:0] b_rptr_next;
    wire [PTR_WIDTH:0] g_rptr_next;
    
    //wires/regs used later in the module to help control b_rptr_next
    wire [PTR_WIDTH:0] b_wptr_s;
    wire wrap_around;
    reg recently_empty;
    reg recently_empty_count;
    wire [PTR_WIDTH-1:0] max_ptr = (1 << PTR_WIDTH) - 1; /*calculating the maximum value 
                                                a pointer can hold, excluding wrap bit*/
    
    //temporary output registers
    reg [PTR_WIDTH:0] g_rptr_temp;    
    reg [PTR_WIDTH:0] b_rptr_temp; 
    reg empty_temp;  
    
    //counter that keeps track how many items are in thye FIFO, used to control b_rptr_next
    reg [PTR_WIDTH:0] fifo_count;
    
    
 //FIFO COUNT BLOCK. block triggers whenever either of the clock synchronized pointers change
    always @(b_wptr_s or b_rptr) begin
//Check how many items are currently in the FIFO
        if (wrap_around) begin
            fifo_count = (max_ptr - b_rptr[PTR_WIDTH-1:0]) + b_wptr_s[PTR_WIDTH-1:0];/*if wrapped around,
                                                 the difference the the max pointer value and the read pointer,
                                                 plus the the write pointer value is the FIFO count.*/  
        end else begin
            fifo_count = b_wptr_s[PTR_WIDTH-1:0] - b_rptr[PTR_WIDTH-1:0]; /*if not wrapped around,
                                                 the difference between the write and read pointers
                                                 is the FIFO count*/
        end    
    end
    
    //caculating the next read pointer  
    /*below, we seing if the FIFO has recently been empty (i.e. the read and write pointers currently share the same address 
     and assign the recently empty flag to be 1 if the FIFO was indeed empty, and a read operation has yet to take place.
     We later use this register to keep the read pointer in place (instead of moving to the next address) whenever the next 
     read enable is called. This is because we need to give the read clock domain an opporunity to read the value stored in 
     data out whenever it needs to*/  
    always @(*)begin
        if(fifo_count == 0 )begin
            recently_empty = 1;
            recently_empty_count = 0;
        end else if (re && !empty && recently_empty_count == 0 && recently_empty == 1) begin
            recently_empty_count = 1;     
        end else if (re && !empty && recently_empty_count == 1 && recently_empty == 1) begin
            recently_empty = 0;
            recently_empty_count = 0;
        end
    end   
    
    //assigning read pointer next variables
    assign b_rptr_next = (recently_empty == 1)?  (b_rptr) : (b_rptr + (re && !empty));
    assign g_rptr_next = (b_rptr_next >> 1) ^ b_rptr_next;
    
    /*synchronous logic to assign the output read pointers,
    which are zero on reset*/  
    always@(posedge rclk or negedge r_rstn) begin
        if(!r_rstn) begin
            b_rptr_temp <= 0;
            g_rptr_temp <= 0;
        end else begin
            b_rptr_temp <= b_rptr_next;
            g_rptr_temp <= g_rptr_next;
        end
    end
    
    /*if reset-- empty is 1, otherwise it is only one
     if the fifo has caught up in read addresses.*/
    always@(posedge rclk or negedge r_rstn) begin
        if(!r_rstn) begin
            empty_temp <= 1;
        end else begin
            empty_temp <= (g_wptr_s == g_rptr_next);
        end
    end
    
    g2b_converter #(.PTR_WIDTH(PTR_WIDTH)) g2b (
    .gray(g_wptr_s),
    .bin( b_wptr_s)
    ); /*binary to gray conversion of the synchronized write pointer to 
        use in the calcultion of the next read pointer address*/
    
    assign wrap_around = b_rptr[PTR_WIDTH] ^ b_wptr_s[PTR_WIDTH]; /*the wrap around bit will be the XOR of
                                                      the MSB of the read and write pointers in binary format*/
    
    //output assignments
    assign b_rptr = b_rptr_temp;
    assign g_rptr = g_rptr_temp;
    assign empty = empty_temp;
    
endmodule
