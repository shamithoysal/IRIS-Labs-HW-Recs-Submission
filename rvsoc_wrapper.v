module rvsoc_wrapper (
    input clk,
    input resetn,

    output ser_tx,
    input  ser_rx,

    output flash_csb,
    output flash_clk,
    inout  flash_io0,
    inout  flash_io1,
    inout  flash_io2,
    inout  flash_io3
);
    parameter integer MEM_WORDS = 32768;   // 128 KB RAM

    wire flash_io0_oe, flash_io0_do, flash_io0_di;
    wire flash_io1_oe, flash_io1_do, flash_io1_di;
    wire flash_io2_oe, flash_io2_do, flash_io2_di;
    wire flash_io3_oe, flash_io3_do, flash_io3_di;

    assign flash_io0 = flash_io0_oe ? flash_io0_do : 1'bz;
    assign flash_io1 = flash_io1_oe ? flash_io1_do : 1'bz;
    assign flash_io2 = flash_io2_oe ? flash_io2_do : 1'bz;
    assign flash_io3 = flash_io3_oe ? flash_io3_do : 1'bz;

    assign flash_io0_di = flash_io0_oe ? 1'b0 : flash_io0;
    assign flash_io1_di = flash_io1_oe ? 1'b0 : flash_io1;
    assign flash_io2_di = flash_io2_oe ? 1'b0 : flash_io2;
    assign flash_io3_di = flash_io3_oe ? 1'b0 : flash_io3;

    // iomem interface from the core
    wire        iomem_valid;
    wire [3:0]  iomem_wstrb;
    wire [31:0] iomem_addr;
    wire [31:0] iomem_wdata;
    wire        iomem_ready;
    wire [31:0] iomem_rdata;

    // GPIO register
    reg [31:0] gpio;
    always @(posedge clk) begin
        if (!resetn) begin
            gpio <= 32'd0;
        end else begin
            if (iomem_valid && |iomem_wstrb && (iomem_addr[31:24] == 8'h03)) begin
                if (iomem_wstrb[0]) gpio[ 7:0] <= iomem_wdata[ 7:0];
                if (iomem_wstrb[1]) gpio[15:8] <= iomem_wdata[15:8];
                if (iomem_wstrb[2]) gpio[23:16] <= iomem_wdata[23:16];
                if (iomem_wstrb[3]) gpio[31:24] <= iomem_wdata[31:24];
            end
        end
    end

    // ACCELERATOR at 0x0400_0000
    wire [7:0] prod_pixel;
    wire prod_valid;
    wire input_fifo_full;

    wire [7:0] proc_in_data;
    wire proc_in_valid;
    wire input_fifo_empty;
    wire proc_in_ready;

    wire [31:0] proc_out_pixel;
    wire proc_out_valid;
    wire [7:0] cfg_rdata;

    wire output_fifo_full;
    wire out_ready;

    wire [31:0] result_data;
    wire        result_empty;

    wire accel_sel      = iomem_valid && (iomem_addr[31:24] == 8'h04);
    wire accel_write_en = accel_sel && |iomem_wstrb && (iomem_addr[7:0] < 8'h40);
    wire [4:0] accel_addr = iomem_addr[6:2];
    wire [7:0] accel_wdata = iomem_wdata[7:0];

    wire result_pop = accel_sel && !(|iomem_wstrb) && (iomem_addr[7:0] == 8'h40);

    wire [31:0] accel_rdata =
        (iomem_addr[7:0] < 8'h40) ? {24'd0, cfg_rdata} :
        (iomem_addr[7:0] == 8'h40) ? result_data :
        (iomem_addr[7:0] == 8'h44) ? {31'd0, !result_empty} :
        32'd0;

    wire gpio_sel = iomem_valid && (iomem_addr[31:24] == 8'h03);


    // Instantiate modules
    data_producer prod_inst (
        .sensor_clk(clk),
        .rst_n(resetn),
        .ready(!input_fifo_full),
        .pixel(prod_pixel),
        .valid(prod_valid)
    );

    // Input FIFO: 8-bit, depth 16, using async FIFO with margins
    async_fifo #(
        .DWIDTH(8),
        .DEPTH(16),
        .FULL_OFFSET(5),   // margin to prevent overflow due to synchronizer delay
        .EMPTY_OFFSET(5)   // margin to prevent underflow
    ) input_fifo (
        .wclk   (clk),
        .wrst_n (resetn),
        .w_en   (prod_valid),
        .wdata  (prod_pixel),
        .wfull  (input_fifo_full),

        .rclk   (clk),
        .rrst_n (resetn),
        .r_en   (proc_in_valid && proc_in_ready),
        .rdata  (proc_in_data),
        .rempty (input_fifo_empty)
    );

    assign proc_in_valid = !input_fifo_empty;

    data_processor #(.DATA_WIDTH(8), .IMG_WIDTH(32)) proc_inst (
        .clk          (clk),
        .rstn         (resetn),
        .in_valid     (proc_in_valid),
        .in_data      (proc_in_data),
        .out_pixel    (proc_out_pixel),
        .out_valid    (proc_out_valid),
        .reg_write_en (accel_write_en),
        .out_ready    (out_ready),
        .reg_addr     (accel_addr),
        .reg_wdata    (accel_wdata),
        .reg_rdata    (cfg_rdata),
        .in_ready     (proc_in_ready)
    );

    // Output FIFO: 32-bit, depth 64, using async FIFO with margins
    async_fifo #(
        .DWIDTH(32),
        .DEPTH(64),
        .FULL_OFFSET(5),
        .EMPTY_OFFSET(5)
    ) output_fifo (
        .wclk   (clk),
        .wrst_n (resetn),
        .w_en   (proc_out_valid),
        .wdata  (proc_out_pixel),
        .wfull  (output_fifo_full),

        .rclk   (clk),
        .rrst_n (resetn),
        .r_en   (result_pop),
        .rdata  (result_data),
        .rempty (result_empty)
    );

    assign out_ready = !output_fifo_full;


    // iomem response mux
    assign iomem_ready = gpio_sel || accel_sel;
    assign iomem_rdata = gpio_sel ? gpio : (accel_sel ? accel_rdata : 32'd0);


    // RISC‑V core instantiation
    rvsoc #(
        .BARREL_SHIFTER(0),
        .ENABLE_MUL(0),
        .ENABLE_DIV(0),
        .ENABLE_FAST_MUL(1),
        .MEM_WORDS(MEM_WORDS)
    ) soc (
        .clk          (clk),
        .resetn       (resetn),

        .ser_tx       (ser_tx),
        .ser_rx       (ser_rx),

        .flash_csb    (flash_csb),
        .flash_clk    (flash_clk),

        .flash_io0_oe (flash_io0_oe),
        .flash_io1_oe (flash_io1_oe),
        .flash_io2_oe (flash_io2_oe),
        .flash_io3_oe (flash_io3_oe),

        .flash_io0_do (flash_io0_do),
        .flash_io1_do (flash_io1_do),
        .flash_io2_do (flash_io2_do),
        .flash_io3_do (flash_io3_do),

        .flash_io0_di (flash_io0_di),
        .flash_io1_di (flash_io1_di),
        .flash_io2_di (flash_io2_di),
        .flash_io3_di (flash_io3_di),

        .irq_5        (1'b0),
        .irq_6        (1'b0),
        .irq_7        (1'b0),

        .iomem_valid  (iomem_valid),
        .iomem_ready  (iomem_ready),
        .iomem_wstrb  (iomem_wstrb),
        .iomem_addr   (iomem_addr),
        .iomem_wdata  (iomem_wdata),
        .iomem_rdata  (iomem_rdata)
    );
endmodule