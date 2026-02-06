module data_proc #(
    parameter DATA_WIDTH = 8,
    parameter IMG_WIDTH = 32
)(
    input wire clk,
    input wire rstn,
    input wire in_valid,
    input wire [7:0] in_data,
    output reg [31:0] out_pixel,
    output reg out_valid,
    input wire reg_write_en,
    input wire [4:0] reg_addr,
    input wire [7:0] reg_wdata,
    output reg [7:0] reg_rdata
);
    reg [1:0] mode_reg;
    reg [7:0] kernel_reg [0:8];
    wire [71:0] flat_kernel;
    wire [31:0] conv_out;
    wire conv_valid;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin // default is identity matrix
            mode_reg <= 0;
            kernel_reg[0]<=0; kernel_reg[1]<=0; kernel_reg[2]<=0;
            kernel_reg[3]<=0; kernel_reg[4]<=1; kernel_reg[5]<=0;
            kernel_reg[6]<=0; kernel_reg[7]<=0; kernel_reg[8]<=0;
        end else if (reg_write_en) begin
            case (reg_addr)
                5'h00: mode_reg <= reg_wdata[1:0];
                5'h04: kernel_reg[0] <= reg_wdata;
                5'h05: kernel_reg[1] <= reg_wdata;
                5'h06: kernel_reg[2] <= reg_wdata;
                5'h07: kernel_reg[3] <= reg_wdata;
                5'h08: kernel_reg[4] <= reg_wdata;
                5'h09: kernel_reg[5] <= reg_wdata;
                5'h0A: kernel_reg[6] <= reg_wdata;
                5'h0B: kernel_reg[7] <= reg_wdata;
                5'h0C: kernel_reg[8] <= reg_wdata;
            endcase
        end
    end

    // active check
    always @(*) begin
        case (reg_addr)
            5'h00: reg_rdata = {6'b0, mode_reg};
            5'h10: reg_rdata = 8'hAA;
            default: reg_rdata = 8'h00;
        endcase
    end

    assign flat_kernel = {
        kernel_reg[8], kernel_reg[7], kernel_reg[6],
        kernel_reg[5], kernel_reg[4], kernel_reg[3],
        kernel_reg[2], kernel_reg[1], kernel_reg[0]
    };

    systolic_engine #(.DATA_WIDTH(8), .IMG_WIDTH(IMG_WIDTH)) u_engine (
        .clk(clk), .rst_n(rstn),
        .in_valid(in_valid && (mode_reg == 2'b10)),
        .in_data(in_data),
        .flat_weights(flat_kernel),
        .out_pixel(conv_out),
        .out_valid(conv_valid)
    );

    always @(*) begin
        case (mode_reg)
            2'b00: begin
                out_pixel = {24'b0, in_data};
                out_valid = in_valid;
            end
            2'b01: begin
                out_pixel = {24'b0, (8'd255 - in_data)};
                out_valid = in_valid;
            end
            2'b10: begin
                out_pixel = conv_out;
                out_valid = conv_valid;
            end
            default: begin
                out_pixel = 0;
                out_valid = 0;
            end
        endcase
    end
endmodule

/* --------------------------------------------------------------------------
Purpose of this module : This module should perform certain operations
based on the mode register and pixel values streamed out by data_prod module.

mode[1:0]:
00 - Bypass
01 - Invert the pixel
10 - Convolution with a kernel of your choice (kernel is 3x3 2d array)
11 - Not implemented

Memory map of registers:

0x00 - Mode (2 bits)    [R/W]
0x04 - Kernel (9 * 8 = 72 bits)     [R/W]
0x10 - Status reg   [R]
----------------------------------------------------------------------------*/