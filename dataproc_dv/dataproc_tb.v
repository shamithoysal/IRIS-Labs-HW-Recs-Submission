`timescale 1 ns / 1 ps

module dataproc_tb;
    // 1. Clock Generation (100 MHz)
    reg clk = 0;
    always #5 clk = ~clk; 

    // 2. Reset Generation
    reg [5:0] reset_cnt = 0;
    wire resetn = &reset_cnt; // Active Low Reset

    always @(posedge clk) begin
        if (reset_cnt < 63)
            reset_cnt <= reset_cnt + 1;
    end

    // 3. UART Parameters (Matches your Firmware!)
    // Firmware Divisor 104 @ 100MHz = ~961,538 Baud
    // TB Period 53 * 2 * 10ns = 1.06us => ~943,000 Baud
    // Close enough for simulation!
    localparam ser_half_period = 53;
    event ser_sample;

    // 4. Signals
    wire ser_rx;
    wire ser_tx; // This is the output we watch!
    
    wire flash_csb;
    wire flash_clk;
    wire flash_io0;
    wire flash_io1;
    wire flash_io2;
    wire flash_io3;

    // =========================================================
    //  YOUR CUSTOM TB LOGIC STARTS HERE
    // =========================================================

	initial begin
        $dumpfile("dataproc_tb.vcd");
        $dumpvars(0, dataproc_tb);

        $display("LOADING FIRMWARE FROM DISK...");
        
        // 🚨 ABSOLUTE PATH FORCE-LOAD 🚨
        // This forces Vivado to read the ACTUAL file you just built.
        $readmemh("D:/Data/IRIS HW Labs Recs/IRIS-Labs-HW-Recs-Submission/dataproc_dv/firmware.hex", uut.soc.memory.mem); 
        
        // Run for 50ms to allow UART to print
        #50000000; 
        $display("TIMEOUT: Simulation ran too long!");
        $finish;
    end

    // =========================================================
    //  END CUSTOM LOGIC
    // =========================================================

    // 5. Instantiate the Processor
    // INCREASED MEMORY TO 4096 WORDS (16KB) TO MATCH LINKER SCRIPT!
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

    // 6. Flash Model (Not used in RAM mode, but kept for connectivity)
    spiflash spiflash (
        .csb(flash_csb),
        .clk(flash_clk),
        .io0(flash_io0),
        .io1(flash_io1),
        .io2(flash_io2),
        .io3(flash_io3)
    );

    // 7. UART Receiver (The Magic Print Block)
    reg [7:0] buffer;
    always begin
        // Wait for Start Bit (Line goes Low)
        @(negedge ser_tx);

        // Wait Half a bit to get to the middle
        repeat (ser_half_period) @(posedge clk);
        -> ser_sample;

        // Read 8 Data Bits
        repeat (8) begin
            repeat (ser_half_period) @(posedge clk);
            repeat (ser_half_period) @(posedge clk);
            buffer = {ser_tx, buffer[7:1]}; // Shift in bit
            -> ser_sample;
        end

        // Wait for Stop Bit
        repeat (ser_half_period) @(posedge clk);
        repeat (ser_half_period) @(posedge clk);
        -> ser_sample;

        // Print the Character!
        if (buffer < 32 || buffer >= 127)
            $display("Serial data: %d (Hex: %h)", buffer, buffer);
        else
            $display("Serial data: '%c'", buffer);
    end

endmodule