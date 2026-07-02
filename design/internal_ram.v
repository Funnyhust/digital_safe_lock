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

    // We only need to store a single 16-bit word (the password at address 0)
    // To simulate a larger RAM if needed, this could be an array: reg [15:0] mem [0:1023];
    // But since the FSM only writes to address 0, a single register is highly optimized.
    reg [15:0] memory;
    
    // Simple state machine to mimic SRAM controller timing (1-cycle delay)
    reg [1:0] state;
    localparam IDLE = 2'd0;
    localparam WAIT = 2'd1;
    localparam DONE = 2'd2;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state <= IDLE;
            o_ready <= 1'b0;
            o_data <= 16'd0;
            memory <= 16'd0; 
        end else begin
            case (state)
                IDLE: begin
                    o_ready <= 1'b0;
                    if (i_wr_en) begin
                        memory <= i_data; // Write data immediately
                        state <= WAIT;
                    end else if (i_rd_en) begin
                        o_data <= memory; // Read data immediately
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
