module data_processor #(
    parameter DATA_WIDTH = 8,
    parameter IMG_WIDTH = 32
)(
    input wire clk,
    input wire rstn,
    input wire in_valid,
    input wire [7:0] in_data,
    output wire in_ready,
    output reg [31:0] out_pixel,
    output reg out_valid,
    input wire reg_write_en,
    input wire [4:0] reg_addr,
    input wire [7:0] reg_wdata,
    output reg [7:0] reg_rdata
);
    reg [1:0] mode_reg;
    reg enable_reg;
    reg [7:0] kernel_reg [0:8];
    wire [71:0] flat_kernel;
    wire [31:0] conv_out;
    wire conv_valid;

    assign in_ready = enable_reg; 

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin 
            mode_reg <= 0;
            enable_reg <= 0;
            // Default Weights (Identity)
            kernel_reg[0]<=0; kernel_reg[1]<=0; kernel_reg[2]<=0;
            kernel_reg[3]<=0; kernel_reg[4]<=1; kernel_reg[5]<=0;
            kernel_reg[6]<=0; kernel_reg[7]<=0; kernel_reg[8]<=0;
        end else if (reg_write_en) begin
            case (reg_addr)
                // Address 0x00 -> Index 0
                5'd0: begin
                    mode_reg <= reg_wdata[1:0];
                    enable_reg <= reg_wdata[7];
                end
                

                // 0x04 -> Index 1
                5'd1: kernel_reg[0] <= reg_wdata; // K00
                // 0x08 -> Index 2
                5'd2: kernel_reg[1] <= reg_wdata; // K01
                // 0x0C -> Index 3
                5'd3: kernel_reg[2] <= reg_wdata; // K02
                
                // 0x10 -> Index 4
                5'd4: kernel_reg[3] <= reg_wdata; // K10
                // 0x14 -> Index 5
                5'd5: kernel_reg[4] <= reg_wdata; // K11 (Center!)
                // 0x18 -> Index 6
                5'd6: kernel_reg[5] <= reg_wdata; // K12
                
                // 0x1C -> Index 7
                5'd7: kernel_reg[6] <= reg_wdata; // K20
                // 0x20 -> Index 8
                5'd8: kernel_reg[7] <= reg_wdata; // K21
                // 0x24 -> Index 9
                5'd9: kernel_reg[8] <= reg_wdata; // K22
            endcase
        end
    end

    // active check
    always @(*) begin
        case (reg_addr)
            5'd0: reg_rdata = {enable_reg, 5'b0, mode_reg};
            5'd1: reg_rdata = kernel_reg[0];
            5'd2: reg_rdata = kernel_reg[1];
            5'd3: reg_rdata = kernel_reg[2];
            5'd4: reg_rdata = kernel_reg[3];
            5'd5: reg_rdata = kernel_reg[4]; 
            5'd6: reg_rdata = kernel_reg[5];
            5'd7: reg_rdata = kernel_reg[6];
            5'd8: reg_rdata = kernel_reg[7];
            5'd9: reg_rdata = kernel_reg[8];
            default: reg_rdata = 8'h00;
        endcase
    end

    assign flat_kernel = {
        kernel_reg[8], kernel_reg[7], kernel_reg[6],
        kernel_reg[5], kernel_reg[4], kernel_reg[3],
        kernel_reg[2], kernel_reg[1], kernel_reg[0]
    };

    systolic_engine #(.DATA_WIDTH(8), .IMG_WIDTH(IMG_WIDTH)) systolic_engine (
        .clk(clk), .rst_n(rstn),
        .in_valid(in_valid && (mode_reg == 2'b10)),
        .in_data(in_data),
        .flat_weights(flat_kernel),
        .out_pixel(conv_out),
        .out_valid(conv_valid)
    );

    always @(*) begin
        case (mode_reg)
            2'b00: begin // Bypass
                out_pixel = {24'b0, in_data};
                out_valid = in_valid;
            end
            2'b01: begin // Invert
                out_pixel = {24'b0, (8'd255 - in_data)};
                out_valid = in_valid;
            end
            2'b10: begin // Convolution
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