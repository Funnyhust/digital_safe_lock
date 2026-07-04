module internal_ram (
    input  wire i_clk,            // System clock (50MHz)
    input  wire i_rst_n,          // Active-low asynchronous reset
    
    // FSM Interface
    input  wire i_rd_en,          // Read enable signal from FSM
    input  wire i_wr_en,          // Write enable signal from FSM
    input  wire [18:0] i_addr,    // Memory address to read/write
    input  wire [15:0] i_data,    // Data to be written into RAM
    output reg  [15:0] o_data,    // Data read from RAM
    output reg  o_ready           // High when the read/write operation is complete
);

    // We need to store at least two 16-bit words (password at address 0, magic number at address 1)
    reg [15:0] memory [0:1];
    
    // Simple state machine to mimic SRAM controller timing (1-cycle delay)
    reg [1:0] state;
    localparam IDLE = 2'd0;
    localparam WAIT = 2'd1;
    localparam DONE = 2'd2;

    // Simulate random/uninitialized memory on power-up
    initial begin
        memory[0] = 16'hXXXX;
        memory[1] = 16'hXXXX;
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state <= IDLE;
            o_ready <= 1'b0;
            o_data <= 16'd0;
            // IMPORTANT: Do NOT clear memory here. A soft reset should not erase SRAM.
        end else begin
            case (state)
                IDLE: begin
                    o_ready <= 1'b0;
                    if (i_wr_en) begin
                        memory[i_addr[0]] <= i_data; // Write data immediately
                        state <= WAIT;
                    end else if (i_rd_en) begin
                        o_data <= memory[i_addr[0]]; // Read data immediately
                        state <= WAIT;
                    end
                end
                
                WAIT: begin
                    // Add 1 cycle delay to perfectly mimic the old external SRAM controller handshake
                    o_ready <= 1'b1;
                    state <= DONE;
                end
                
                DONE: begin
                    // Wait until FSM drops the enable signal before returning to IDLE
                    if (!i_rd_en && !i_wr_en) begin
                        o_ready <= 1'b0;
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
