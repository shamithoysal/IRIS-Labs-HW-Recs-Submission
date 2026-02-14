module sync_fifo #(
    parameter DWIDTH = 8,
    parameter DEPTH  = 16
)(
    input  clk,
    input  rst_n,
    input  w_en,
    input  [DWIDTH-1:0] wdata,
    output wfull,
    input  r_en,
    output [DWIDTH-1:0] rdata,
    output rempty
);
    localparam AWIDTH = $clog2(DEPTH);
    reg [DWIDTH-1:0] mem [0:DEPTH-1];
    reg [AWIDTH:0] wptr, rptr;
    wire [AWIDTH:0] next_wptr = wptr + 1;
    wire [AWIDTH:0] next_rptr = rptr + 1;

    // Full when next write pointer equals read pointer (with wrap)
    assign wfull = (next_wptr[AWIDTH-1:0] == rptr[AWIDTH-1:0]) && (next_wptr[AWIDTH] != rptr[AWIDTH]);
    // Empty when write and read pointers are equal
    assign rempty = (wptr == rptr);
    // Combinational read data
    assign rdata = mem[rptr[AWIDTH-1:0]];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr <= 0;
            rptr <= 0;
        end else begin
            if (w_en && !wfull) begin
                mem[wptr[AWIDTH-1:0]] <= wdata;
                wptr <= next_wptr;
            end
            if (r_en && !rempty) begin
                rptr <= next_rptr;
            end
        end
    end
endmodule