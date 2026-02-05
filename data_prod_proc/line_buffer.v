module line_buffer #(
    parameter DATA_WIDTH = 8,
    parameter IMG_WIDTH  = 32
)(
    input  wire clk,
    input  wire reset_n,
    input  wire valid_in,
    input  wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout_0,
    output wire [DATA_WIDTH-1:0] dout_1,
    output wire [DATA_WIDTH-1:0] dout_2
);

    reg [DATA_WIDTH-1:0] line_mem1 [0:IMG_WIDTH-1];
    reg [DATA_WIDTH-1:0] line_mem2 [0:IMG_WIDTH-1];
    reg [DATA_WIDTH-1:0] rdata1;
    reg [DATA_WIDTH-1:0] rdata2;
    reg [$clog2(IMG_WIDTH)-1:0] ptr;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            ptr <= 0;
        end else if (valid_in) begin
            if (ptr == IMG_WIDTH - 1)
                ptr <= 0;
            else
                ptr <= ptr + 1;
        end
    end

    always @(posedge clk) begin
        if (valid_in) begin
            rdata1 <= line_mem1[ptr];
            line_mem1[ptr] <= din;
            rdata2 <= line_mem2[ptr];
            line_mem2[ptr] <= line_mem1[ptr];
        end
    end

    assign dout_0 = din;
    assign dout_1 = rdata1;
    assign dout_2 = rdata2;

endmodule