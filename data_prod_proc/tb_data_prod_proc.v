`timescale 1ns/1ps

module tb_data_prod_proc;

    reg clk = 0;
    reg sensor_clk = 0;

    // 100MHz System Clock
    always #5 clk = ~clk;

    // 200MHz Sensor Clock
    always #2.5 sensor_clk = ~sensor_clk;

    // Reset Logic (System)
    reg [5:0] reset_cnt = 0;
    wire resetn = &reset_cnt;
    always @(posedge clk) begin
        if (!resetn) reset_cnt <= reset_cnt + 1'b1;
    end

    // Reset Logic (Sensor)
    reg [5:0] sensor_reset_cnt = 0;
    wire sensor_resetn = &sensor_reset_cnt;
    always @(posedge sensor_clk) begin
        if (!sensor_resetn) sensor_reset_cnt <= sensor_reset_cnt + 1'b1;
    end

    // Wires
    wire [7:0] pixel;
    wire valid;
    wire ready;
    
    // FIFO Wires
    wire [7:0] fifo_rdata;
    wire fifo_rempty;
    wire fifo_wfull;
    wire fifo_ren;
    
    // Processor Outputs
    wire [31:0] proc_out_pixel;
    wire proc_out_valid;

    // Configuration Signals
    reg cfg_write_en = 0;
    reg [4:0] cfg_addr = 0;
    reg [7:0] cfg_wdata = 0;
    wire [7:0] cfg_rdata;

    async_fifo #(.DWIDTH(8), .DEPTH(16)) async_fifo (
        .wclk(sensor_clk), .wrst_n(sensor_resetn),
        .w_en(valid),          
        .wdata(pixel),
        .wfull(fifo_wfull),     

        .rclk(clk), .rrst_n(resetn),
        .r_en(fifo_ren),        
        .rdata(fifo_rdata),
        .rempty(fifo_rempty)
    );

    // Flow Control
    assign ready = !fifo_wfull;       
    assign fifo_ren = !fifo_rempty;   


    data_processor #(.DATA_WIDTH(8), .IMG_WIDTH(32)) data_processor (
        .clk(clk),
        .rstn(resetn),
        .in_valid(fifo_ren),    
        .in_data(fifo_rdata),
        .out_pixel(proc_out_pixel),
        .out_valid(proc_out_valid),
        .reg_write_en(cfg_write_en),
        .reg_addr(cfg_addr),
        .reg_wdata(cfg_wdata),
        .reg_rdata(cfg_rdata)
    );

    data_producer data_producer (
        .sensor_clk(sensor_clk),
        .rst_n(sensor_resetn), 
        .ready(ready),
        .pixel(pixel),
        .valid(valid)
    );



    task write_reg(input [4:0] addr, input [7:0] data);
        begin
            @(posedge clk);
            cfg_write_en = 1;
            cfg_addr = addr;
            cfg_wdata = data;
            @(posedge clk);
            cfg_write_en = 0;
        end
    endtask

    initial begin
        wait(resetn);
        repeat(10) @(posedge clk);
        $display("--- Reset Released ---");

        // Set Mode to Convolution
        write_reg(5'h00, 8'b0000_0010); 

        // Load Edge Detection Kernel
        write_reg(5'h04, 8'd0);
        write_reg(5'h05, -8'd1);
        write_reg(5'h06, 8'd0);
        write_reg(5'h07, -8'd1);
        write_reg(5'h08, 8'd4);
        write_reg(5'h09, -8'd1);
        write_reg(5'h0A, 8'd0);
        write_reg(5'h0B, -8'd1);
        write_reg(5'h0C, 8'd0);
        $display("--- Weights Loaded ---");

        #10000;
        $display("--- Simulation Done ---");
        $finish;
    end

endmodule