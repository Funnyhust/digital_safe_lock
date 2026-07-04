`timescale 1ns/1ps

module mock_ssram (
    inout  wire [31:0] FS_DQ,
    input  wire [26:1] FS_ADDR,
    input  wire SSRAM0_CE_N,
    input  wire SSRAM1_CE_N,
    input  wire SSRAM_ADSC_N,
    input  wire SSRAM_ADSP_N,
    input  wire SSRAM_ADV_N,
    input  wire [3:0]  SSRAM_BE,
    input  wire SSRAM_CLK,
    input  wire SSRAM_GW_N,
    input  wire SSRAM_OE_N,
    input  wire SSRAM_WE_N
);

    reg [31:0] memory [0:255]; // Only simulate 256 words for testing
    integer i;
    initial begin
        for (i=0; i<256; i=i+1) memory[i] = 32'h0000_FFFF;
    end

    reg [26:1] latched_addr;
    reg latched_we_n;
    
    // Pipeline registers for read data
    reg [31:0] dout_reg;

    always @(posedge SSRAM_CLK) begin
        if (!SSRAM0_CE_N && !SSRAM_ADSC_N) begin
            // Latch address and write status at rising edge
            latched_addr <= FS_ADDR;
            latched_we_n <= SSRAM_WE_N;
        end
        
        // Late write: if latched_we_n was 0 in the previous cycle, latch data NOW
        if (!latched_we_n) begin
            // We ignore Byte Enables (SSRAM_BE) in this simple mock to save time
            memory[latched_addr[8:1]] <= FS_DQ;
            $display("[MOCK SSRAM] Saved %h to address %h", FS_DQ, latched_addr);
            latched_we_n <= 1'b1; // Clear internal write request
        end
        
        // Pipelined read
        if (latched_we_n) begin
            dout_reg <= memory[latched_addr[8:1]];
        end
    end

    // Output enable (Asynchronous to clock)
    assign FS_DQ = (!SSRAM_OE_N) ? dout_reg : 32'bz;

endmodule
