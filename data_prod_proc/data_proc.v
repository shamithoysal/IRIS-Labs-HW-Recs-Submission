module data_processor #(
    parameter DATA_WIDTH = 8,
    parameter IMG_WIDTH = 32
)(
    input wire clk,
    input wire rstn,
    input wire in_valid,
    input wire [7:0] in_data,
    input wire out_ready,
    output wire in_ready,
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
        if (!rstn) begin
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

    always @(*) begin
        case (reg_addr)
            5'h00: reg_rdata = {6'b0, mode_reg};
            5'h04: reg_rdata = kernel_reg[0];
            5'h05: reg_rdata = kernel_reg[1];
            5'h06: reg_rdata = kernel_reg[2];
            5'h07: reg_rdata = kernel_reg[3];
            5'h08: reg_rdata = kernel_reg[4]; 
            5'h09: reg_rdata = kernel_reg[5];
            5'h0A: reg_rdata = kernel_reg[6];
            5'h0B: reg_rdata = kernel_reg[7];
            5'h0C: reg_rdata = kernel_reg[8];
            5'h10: reg_rdata = 8'hAA;
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
        .in_valid(in_valid && (mode_reg == 2'b10) && in_ready),
        .in_data(in_data),
        .flat_weights(flat_kernel),
        .out_pixel(conv_out),
        .out_valid(conv_valid)
    );

    assign in_ready = out_ready;

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