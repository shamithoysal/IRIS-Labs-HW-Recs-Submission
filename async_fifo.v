module async_fifo #(
    parameter DWIDTH = 8,
    parameter DEPTH  = 16,
    parameter FULL_OFFSET = 5,   // Stop when only this many slots left
    parameter EMPTY_OFFSET = 5    // Stop when only this many entries left
)(
    input  wclk,
    input  wrst_n,
    input  w_en,
    input  [DWIDTH-1:0] wdata,
    output wfull,
    input  rclk,
    input  rrst_n,
    input  r_en,
    output [DWIDTH-1:0] rdata,
    output rempty
);
    localparam AWIDTH = $clog2(DEPTH);
    reg [DWIDTH-1:0] mem [0:DEPTH-1];

    // Binary pointers (extra bit for wrap)
    reg [AWIDTH:0] wptr_bin, rptr_bin;
    // Gray code pointers
    reg [AWIDTH:0] wptr_gray, rptr_gray;

    // Synchronized gray pointers
    reg [AWIDTH:0] wptr_gray_sync1, wptr_gray_sync2;
    reg [AWIDTH:0] rptr_gray_sync1, rptr_gray_sync2;

    // Gray to binary conversion (combinational)
    function [AWIDTH:0] gray2bin;
        input [AWIDTH:0] gray;
        integer i;
        begin
            gray2bin[AWIDTH] = gray[AWIDTH];
            for (i = AWIDTH-1; i >= 0; i = i - 1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    // Write logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_bin <= 0;
            wptr_gray <= 0;
        end else if (~wfull && w_en) begin
            mem[wptr_bin[AWIDTH-1:0]] <= wdata;
            wptr_bin <= wptr_bin + 1;
            wptr_gray <= (wptr_bin + 1) >> 1 ^ (wptr_bin + 1);  // binary to gray
        end
    end

    // Read logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_bin <= 0;
            rptr_gray <= 0;
        end else if (~rempty && r_en) begin
            rptr_bin <= rptr_bin + 1;
            rptr_gray <= (rptr_bin + 1) >> 1 ^ (rptr_bin + 1);
        end
    end

    // Synchronize write pointer to read clock
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_sync1 <= 0;
            wptr_gray_sync2 <= 0;
        end else begin
            wptr_gray_sync1 <= wptr_gray;
            wptr_gray_sync2 <= wptr_gray_sync1;
        end
    end

    // Synchronize read pointer to write clock
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_sync1 <= 0;
            rptr_gray_sync2 <= 0;
        end else begin
            rptr_gray_sync1 <= rptr_gray;
            rptr_gray_sync2 <= rptr_gray_sync1;
        end
    end

    // Combinational read data
    assign rdata = mem[rptr_bin[AWIDTH-1:0]];

    // -----------------------------------------------------------------
    // Full detection with margin
    // Convert synchronized read pointer (gray) to binary
    wire [AWIDTH:0] rptr_bin_sync = gray2bin(rptr_gray_sync2);
    // Distance from write pointer to synchronized read pointer (modulo 2*DEPTH)
    wire [AWIDTH:0] dist = wptr_bin - rptr_bin_sync;
    // Full when distance >= DEPTH - FULL_OFFSET
    assign wfull = (dist >= (DEPTH - FULL_OFFSET));

    // -----------------------------------------------------------------
    // Empty detection with margin
    // Convert synchronized write pointer (gray) to binary
    wire [AWIDTH:0] wptr_bin_sync = gray2bin(wptr_gray_sync2);
    // Distance from read pointer to synchronized write pointer
    wire [AWIDTH:0] dist_r = wptr_bin_sync - rptr_bin;
    // Empty when distance <= EMPTY_OFFSET
    assign rempty = (dist_r <= EMPTY_OFFSET);

endmodule