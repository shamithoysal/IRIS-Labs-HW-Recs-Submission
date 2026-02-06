module async_fifo #(
    parameter DWIDTH=8, 
    parameter DEPTH=16
)( 
    input wclk,
    input wrst_n,
    input w_en,
    input [DWIDTH-1:0] wdata,
    output wfull,
    input rclk,
    input rrst_n,
    input r_en,
    output reg [DWIDTH-1:0] rdata,
    output rempty
);

    reg [DWIDTH-1:0] mem [DEPTH-1:0];


    localparam AWIDTH = $clog2(DEPTH);

    reg [AWIDTH:0] wptr_bin, wptr_gray; 
    reg [AWIDTH:0] rptr_bin, rptr_gray; 

    reg [AWIDTH:0] wptr_gray_sync1, wptr_gray_sync2; 
    reg [AWIDTH:0] rptr_gray_sync1, rptr_gray_sync2;

    always @(posedge wclk, negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_bin <= 0;
            wptr_gray <= 0;
        end else if (~wfull && w_en) begin
            mem[wptr_bin[AWIDTH-1:0]] <= wdata;
            wptr_bin <= wptr_bin + 1;
            wptr_gray <= (wptr_bin + 1) >> 1 ^ (wptr_bin + 1);
        end

    end

    always @(posedge rclk, negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_bin <= 0;
            rptr_gray <= 0;
        end else if (~rempty && r_en) begin
            rdata <= mem[rptr_bin[AWIDTH-1:0]];
            rptr_bin <= rptr_bin + 1;
            rptr_gray <= (rptr_bin + 1) >> 1 ^ (rptr_bin + 1);
        end
    end

always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_sync1 <= 0;
            wptr_gray_sync2 <= 0;
        end else begin
            wptr_gray_sync1 <= wptr_gray;      
            wptr_gray_sync2 <= wptr_gray_sync1;
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_sync1 <= 0;
            rptr_gray_sync2 <= 0;
        end else begin
            rptr_gray_sync1 <= rptr_gray; 
            rptr_gray_sync2 <= rptr_gray_sync1;
        end
    end

    assign rempty = (rptr_gray == wptr_gray_sync2);

    assign wfull = (wptr_gray == {~rptr_gray_sync2[AWIDTH:AWIDTH-1], rptr_gray_sync2[AWIDTH-2:0]});

endmodule