`timescale 1 ns / 1 ps

module dataproc_tb;
    // 1. Clock Generation (100 MHz)
    reg clk = 0;
    always #5 clk = ~clk; 

    // 2. Reset Generation
    reg [5:0] reset_cnt = 0;
    wire resetn = &reset_cnt; 

    always @(posedge clk) begin
        if (reset_cnt < 63)
            reset_cnt <= reset_cnt + 1;
    end

    // 3. UART Parameters (SYNC MODE - DIV 19)
    localparam ser_half_period = 10;
    event ser_sample;

    // 4. Signals
    wire ser_rx;
    wire ser_tx; 
    
    wire flash_csb;
    wire flash_clk;
    wire flash_io0;
    wire flash_io1;
    wire flash_io2;
    wire flash_io3;

    // =========================================================
    //  OPTIMIZED LOGIC: NO WAVEFORM DUMPING
    // =========================================================

    initial begin
        
        $display("[%t] LOADING FIRMWARE FROM DISK...", $time);
        
        $readmemh("D:/Data/IRIS HW Labs Recs/IRIS-Labs-HW-Recs-Submission/dataproc_dv/firmware.hex", uut.soc.memory.mem); 
        
        // Extended runtime for full image processing
        #200000000; 
        $display("[%t] TIMEOUT: Simulation finished.", $time);
        $finish;
    end

    // =========================================================
    //  INSTANTIATION
    // =========================================================

    rvsoc_wrapper #(
        .MEM_WORDS(4096) 
    ) uut (
        .clk      (clk),
        .resetn   (resetn),
        .ser_rx   (ser_rx),
        .ser_tx   (ser_tx),
        .flash_csb(flash_csb),
        .flash_clk(flash_clk),
        .flash_io0(flash_io0),
        .flash_io1(flash_io1),
        .flash_io2(flash_io2),
        .flash_io3(flash_io3)
    );

    spiflash spiflash (
        .csb(flash_csb), .clk(flash_clk), .io0(flash_io0), .io1(flash_io1), .io2(flash_io2), .io3(flash_io3)
    );

    // =========================================================
    //  OPTIMIZED UART RECEIVER (Line Buffered)
    // =========================================================
    // 7. Optimized UART Receiver (Instant Print)
    reg [7:0] buffer;
    always begin
        @(negedge ser_tx);
        repeat (ser_half_period) @(posedge clk);
        -> ser_sample;
        repeat (8) begin
            repeat (ser_half_period) @(posedge clk);
            repeat (ser_half_period) @(posedge clk);
            buffer = {ser_tx, buffer[7:1]};
            -> ser_sample;
        end
        repeat (ser_half_period) @(posedge clk);
        repeat (ser_half_period) @(posedge clk);
        
        // ⚡ INSTANT PRINT: No buffering, no waiting.
        if (buffer == 13) begin
            // Ignore Carriage Return
        end else if (buffer == 10) begin
            $write("\n"); // Newline
        end else begin
            $write("%c", buffer); // Character (digit or minus sign)
        end
    end

endmodule