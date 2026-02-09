module rvsoc (
    input clk,
    input resetn,

    output        iomem_valid,
    input         iomem_ready,
    output [ 3:0] iomem_wstrb,
    output [31:0] iomem_addr,
    output [31:0] iomem_wdata,
    input  [31:0] iomem_rdata,

    input  irq_5,
    input  irq_6,
    input  irq_7,

    output ser_tx,
    input  ser_rx,

    output flash_csb,
    output flash_clk,

    output flash_io0_oe,
    output flash_io1_oe,
    output flash_io2_oe,
    output flash_io3_oe,

    output flash_io0_do,
    output flash_io1_do,
    output flash_io2_do,
    output flash_io3_do,

    input  flash_io0_di,
    input  flash_io1_di,
    input  flash_io2_di,
    input  flash_io3_di
);
    parameter [0:0] BARREL_SHIFTER = 1;
    parameter [0:0] ENABLE_MUL = 1;
    parameter [0:0] ENABLE_DIV = 1;
    parameter [0:0] ENABLE_FAST_MUL = 0;
    parameter [0:0] ENABLE_COMPRESSED = 1;
    parameter [0:0] ENABLE_COUNTERS = 1;
    parameter [0:0] ENABLE_IRQ_QREGS = 0;

    parameter integer MEM_WORDS = 256;
    parameter [31:0] STACKADDR = (4*MEM_WORDS);
    parameter [31:0] PROGADDR_RESET = 32'h 0010_0000;
    parameter [31:0] PROGADDR_IRQ = 32'h 0000_0000;

    reg [31:0] irq;
    wire irq_stall = 0;
    wire irq_uart = 0;

    always @* begin
        irq = 0;
        irq[3] = irq_stall;
        irq[4] = irq_uart;
        irq[5] = irq_5;
        irq[6] = irq_6;
        irq[7] = irq_7;
    end

    wire mem_valid;
    wire mem_instr;
    wire mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0] mem_wstrb;
    wire [31:0] mem_rdata;

    wire spimem_ready;
    wire [31:0] spimem_rdata;

    reg ram_ready;
    wire [31:0] ram_rdata;

    assign iomem_valid = mem_valid && (mem_addr[31:24] > 8'h 03);
    assign iomem_wstrb = mem_wstrb;
    assign iomem_addr = mem_addr;
    assign iomem_wdata = mem_wdata;

    wire spimemio_cfgreg_sel = mem_valid && (mem_addr == 32'h 0200_0000);
    wire [31:0] spimemio_cfgreg_do;

    wire        simpleuart_reg_div_sel = mem_valid && (mem_addr == 32'h 0200_0004);
    wire [31:0] simpleuart_reg_div_do;

    wire        simpleuart_reg_dat_sel = mem_valid && (mem_addr == 32'h 0200_0008);
    wire [31:0] simpleuart_reg_dat_do;
    wire        simpleuart_reg_dat_wait;

    // Accelerator Signals (Forward Declaration)
    wire        accel_sel;
    reg  [31:0] accel_rdata;
    reg         accel_ready;

    assign mem_ready =
    (iomem_valid && iomem_ready) ||
    spimem_ready ||
    ram_ready ||
    spimemio_cfgreg_sel ||
    simpleuart_reg_div_sel ||
    (simpleuart_reg_dat_sel && !simpleuart_reg_dat_wait) ||
    accel_ready;

    assign mem_rdata =
    (iomem_valid && iomem_ready) ? iomem_rdata :
    spimem_ready                ? spimem_rdata :
    ram_ready                   ? ram_rdata :
    spimemio_cfgreg_sel         ? spimemio_cfgreg_do :
    simpleuart_reg_div_sel      ? simpleuart_reg_div_do :
    simpleuart_reg_dat_sel      ? simpleuart_reg_dat_do :
    accel_ready                 ? accel_rdata :
    32'h0;

    picorv32 #(
        .STACKADDR(STACKADDR),
        .PROGADDR_RESET(PROGADDR_RESET),
        .PROGADDR_IRQ(PROGADDR_IRQ),
        .BARREL_SHIFTER(BARREL_SHIFTER),
        .COMPRESSED_ISA(ENABLE_COMPRESSED),
        .ENABLE_COUNTERS(ENABLE_COUNTERS),
        .ENABLE_MUL(ENABLE_MUL),
        .ENABLE_DIV(ENABLE_DIV),
        .ENABLE_FAST_MUL(ENABLE_FAST_MUL),
        .ENABLE_IRQ(1),
        .ENABLE_IRQ_QREGS(ENABLE_IRQ_QREGS)
    ) cpu (
        .clk         (clk),
        .resetn      (resetn),
        .mem_valid   (mem_valid),
        .mem_instr   (mem_instr),
        .mem_ready   (mem_ready),
        .mem_addr    (mem_addr),
        .mem_wdata   (mem_wdata),
        .mem_wstrb   (mem_wstrb),
        .mem_rdata   (mem_rdata),
        .irq         (irq)
    );

    spimemio spimemio (
        .clk    (clk),
        .resetn (resetn),
        .valid  (mem_valid && mem_addr >= 4*MEM_WORDS && mem_addr < 32'h 0200_0000),
        .ready  (spimem_ready),
        .addr   (mem_addr[23:0]),
        .rdata  (spimem_rdata),

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

        .cfgreg_we(spimemio_cfgreg_sel ? mem_wstrb : 4'b 0000),
        .cfgreg_di(mem_wdata),
        .cfgreg_do(spimemio_cfgreg_do)
    );

    simpleuart simpleuart (
        .clk         (clk),
        .resetn      (resetn),

        .ser_tx      (ser_tx),
        .ser_rx      (ser_rx),

        .reg_div_we  (simpleuart_reg_div_sel ? mem_wstrb : 4'b 0000),
        .reg_div_di  (mem_wdata),
        .reg_div_do  (simpleuart_reg_div_do),

        .reg_dat_we  (simpleuart_reg_dat_sel ? mem_wstrb[0] : 1'b 0),
        .reg_dat_re  (simpleuart_reg_dat_sel && !mem_wstrb),
        .reg_dat_di  (mem_wdata),
        .reg_dat_do  (simpleuart_reg_dat_do),
        .reg_dat_wait(simpleuart_reg_dat_wait)
    );

    // =========================================================================
    //  ACCELERATOR INTEGRATION
    //  Base Address: 0x0300_0000
    // =========================================================================

    // 1. Address Decoding
    assign accel_sel = mem_valid && (mem_addr[31:24] == 8'h03);

    // 2. Data Producer (System Clock)
    wire [7:0] prod_pixel;
    wire prod_valid;
    wire input_fifo_full;
    
    data_producer prod_inst (
        .sensor_clk(clk),      
        .rst_n(resetn),
        .ready(!input_fifo_full),
        .pixel(prod_pixel),
        .valid(prod_valid)
    );

    wire [7:0] proc_in_data;
    wire proc_in_valid;
    wire input_fifo_empty;
    assign proc_in_valid = !input_fifo_empty;

    async_fifo #(.DWIDTH(8), .DEPTH(16)) input_fifo (
        .wclk(clk), .wrst_n(resetn), 
        .w_en(prod_valid), .wdata(prod_pixel), .wfull(input_fifo_full),
        
        .rclk(clk), .rrst_n(resetn), 
        .r_en(proc_in_valid),
        .rdata(proc_in_data), .rempty(input_fifo_empty)
    );


    wire [31:0] proc_out_pixel;
    wire proc_out_valid;
    wire [7:0] cfg_rdata;
    
    wire cfg_write_en = accel_sel && |mem_wstrb && (mem_addr[7:0] <= 8'h24);

    data_processor #(.DATA_WIDTH(8), .IMG_WIDTH(32)) proc_inst (
        .clk(clk),
        .rstn(resetn),
        .in_valid(proc_in_valid),
        .in_data(proc_in_data),
        .out_pixel(proc_out_pixel),
        .out_valid(proc_out_valid),
        .reg_write_en(cfg_write_en),
        .reg_addr(mem_addr[6:2]), 
        .reg_wdata(mem_wdata[7:0]),
        .reg_rdata(cfg_rdata)
    );

    wire [31:0] result_data;
    wire        result_empty;
    wire result_pop = accel_sel && !(|mem_wstrb) && (mem_addr[7:0] == 8'h10);

    async_fifo #(.DWIDTH(32), .DEPTH(64)) output_fifo (
        .wclk(clk), .wrst_n(resetn),
        .w_en(proc_out_valid), .wdata(proc_out_pixel), 
        
        .rclk(clk), .rrst_n(resetn),
        .r_en(result_pop), 
        .rdata(result_data), .rempty(result_empty)
    );

    always @(posedge clk) begin
        accel_ready <= accel_sel && !accel_ready; 
        
        if (mem_addr[7:0] < 8'h10) begin
            accel_rdata <= {24'd0, cfg_rdata};
        end else if (mem_addr[7:0] == 8'h10) begin
            accel_rdata <= result_data;
        end else if (mem_addr[7:0] == 8'h14) begin
            accel_rdata <= {31'd0, !result_empty};
        end else begin
            accel_rdata <= 32'd0;
        end
    end

    //----------------------------------------------------------------

    always @(posedge clk)
        ram_ready <= mem_valid && !mem_ready && mem_addr < 4*MEM_WORDS;

    soc_mem #(
        .WORDS(MEM_WORDS)
    ) memory (
        .clk(clk),
        .wen((mem_valid && !mem_ready && mem_addr < 4*MEM_WORDS) ? mem_wstrb : 4'b0),
        .addr(mem_addr[23:2]),
        .wdata(mem_wdata),
        .rdata(ram_rdata)
    );
endmodule

module soc_mem #(
    parameter integer WORDS = 256
) (
    input clk,
    input [3:0] wen,
    input [21:0] addr,
    input [31:0] wdata,
    output reg [31:0] rdata
);
    reg [31:0] mem [0:WORDS-1];

    always @(posedge clk) begin
        rdata <= mem[addr];
        if (wen[0]) mem[addr][ 7: 0] <= wdata[ 7: 0];
        if (wen[1]) mem[addr][15: 8] <= wdata[15: 8];
        if (wen[2]) mem[addr][23:16] <= wdata[23:16];
        if (wen[3]) mem[addr][31:24] <= wdata[31:24];
    end
endmodule