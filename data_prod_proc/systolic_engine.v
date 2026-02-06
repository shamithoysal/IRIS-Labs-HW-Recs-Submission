module systolic_engine #(
    parameter DATA_WIDTH = 8,
    parameter IMG_WIDTH = 32
)(
    input wire clk,
    input wire rst_n,
    input wire in_valid,
    input wire [7:0] in_data,
    input wire [71:0] flat_weights,
    output wire [31:0] out_pixel,
    output wire out_valid
);
    wire signed [7:0] k00 = flat_weights[7:0];
    wire signed [7:0] k01 = flat_weights[15:8];
    wire signed [7:0] k02 = flat_weights[23:16];
    wire signed [7:0] k10 = flat_weights[31:24];
    wire signed [7:0] k11 = flat_weights[39:32];
    wire signed [7:0] k12 = flat_weights[47:40];
    wire signed [7:0] k20 = flat_weights[55:48];
    wire signed [7:0] k21 = flat_weights[63:56];
    wire signed [7:0] k22 = flat_weights[71:64];
    wire [7:0] tap0, tap1, tap2;
    reg [7:0] tap1_d1;
    reg [7:0] tap0_d1, tap0_d2;
    wire [7:0] r0_c0_e, r0_c1_e;
    wire [7:0] r1_c0_e, r1_c1_e;
    wire [7:0] r2_c0_e, r2_c1_e;
    wire signed [31:0] r0_c0_s, r0_c1_s, r0_c2_s;
    wire signed [31:0] r1_c0_s, r1_c1_s, r1_c2_s;
    wire signed [31:0] r2_c0_s, r2_c1_s, r2_c2_s;
    reg signed [31:0] col0_d1, col0_d2;
    reg signed [31:0] col1_d1;
    wire signed [31:0] col2_d0;
    reg [31:0] final_sum;
    reg [8:0] valid_pipe;

    line_buffer #(.DATA_WIDTH(8), .IMG_WIDTH(IMG_WIDTH)) line_buffer (
        .clk(clk), .reset_n(rst_n),
        .valid_in(in_valid), .din(in_data),
        .dout_0(tap0), .dout_1(tap1), .dout_2(tap2)
    );

    always @(posedge clk) begin
        if (in_valid) begin
            tap1_d1 <= tap1;
            tap0_d1 <= tap0;
            tap0_d2 <= tap0_d1;
        end
    end

    mac m00 (.clk(clk), .reset_n(rst_n), .in_weight(k00), .in_west(tap2), .out_east(r0_c0_e), .in_north(32'sd0), .out_south(r0_c0_s));
    mac m01 (.clk(clk), .reset_n(rst_n), .in_weight(k01), .in_west(r0_c0_e), .out_east(r0_c1_e), .in_north(32'sd0), .out_south(r0_c1_s));
    mac m02 (.clk(clk), .reset_n(rst_n), .in_weight(k02), .in_west(r0_c1_e), .out_east(), .in_north(32'sd0), .out_south(r0_c2_s));
    mac m10 (.clk(clk), .reset_n(rst_n), .in_weight(k10), .in_west(tap1_d1), .out_east(r1_c0_e), .in_north(r0_c0_s), .out_south(r1_c0_s));
    mac m11 (.clk(clk), .reset_n(rst_n), .in_weight(k11), .in_west(r1_c0_e), .out_east(r1_c1_e), .in_north(r0_c1_s), .out_south(r1_c1_s));
    mac m12 (.clk(clk), .reset_n(rst_n), .in_weight(k12), .in_west(r1_c1_e), .out_east(), .in_north(r0_c2_s), .out_south(r1_c2_s));
    mac m20 (.clk(clk), .reset_n(rst_n), .in_weight(k20), .in_west(tap0_d2), .out_east(r2_c0_e), .in_north(r1_c0_s), .out_south(r2_c0_s));
    mac m21 (.clk(clk), .reset_n(rst_n), .in_weight(k21), .in_west(r2_c0_e), .out_east(r2_c1_e), .in_north(r1_c1_s), .out_south(r2_c1_s));
    mac m22 (.clk(clk), .reset_n(rst_n), .in_weight(k22), .in_west(r2_c1_e), .out_east(), .in_north(r1_c2_s), .out_south(r2_c2_s));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col0_d1 <= 0; col0_d2 <= 0; col1_d1 <= 0;
        end else begin
            col0_d1 <= r2_c0_s;
            col0_d2 <= col0_d1;
            col1_d1 <= r2_c1_s;
        end
    end
    assign col2_d0 = r2_c2_s;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            final_sum <= 0;
            valid_pipe <= 0;
        end else begin
            final_sum <= col0_d2 + col1_d1 + col2_d0;
            valid_pipe <= {valid_pipe[7:0], in_valid}; //TODO
        end
    end

    assign out_pixel = final_sum;
    assign out_valid = valid_pipe[7];
endmodule

