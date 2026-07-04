`timescale 1ns/1ps

module ssram_controller (
    input  wire clk,
    input  wire rst_n,

    // Handshaking with FSM
    input  wire i_rd_en,
    input  wire i_wr_en,
    input  wire [19:0] i_addr,
    input  wire [15:0] i_data,
    output reg  [15:0] o_data,
    output reg  o_ready,

    // SSRAM Interface to Physical Board (DE2i-150)
    inout  wire [31:0] FS_DQ,
    output wire [26:1] FS_ADDR,
    output wire SSRAM0_CE_N,
    output wire SSRAM1_CE_N,
    output wire SSRAM_ADSC_N,
    output wire SSRAM_ADSP_N,
    output wire SSRAM_ADV_N,
    output wire [3:0]  SSRAM_BE,
    output wire SSRAM_CLK,
    output wire SSRAM_GW_N,
    output wire SSRAM_OE_N,
    output wire SSRAM_WE_N
);

    // Static Enables
    assign SSRAM0_CE_N = 1'b0;  // Always enable chip
    assign SSRAM1_CE_N = 1'b0;
    assign SSRAM_ADSP_N = 1'b1; // Not using processor mode
    assign SSRAM_ADV_N = 1'b1;  // No burst mode
    assign SSRAM_GW_N = 1'b1;   // No global write
    assign SSRAM_BE = 4'b1100;  // Enable lower 2 bytes only (active low)
    assign SSRAM_CLK = clk;     // Clock the SSRAM

    reg [26:1] addr_reg;
    reg adsc_n_reg;
    reg we_n_reg;
    reg oe_n_reg;
    reg [31:0] data_out_reg;
    reg data_oe;

    assign FS_ADDR = addr_reg;
    assign SSRAM_ADSC_N = adsc_n_reg;
    assign SSRAM_WE_N = we_n_reg;
    assign SSRAM_OE_N = oe_n_reg;
    
    // Tri-state buffer for Data bus
    assign FS_DQ = data_oe ? data_out_reg : 32'bz;

    reg [2:0] state;
    localparam IDLE = 0, R1 = 1, R2 = 2, R3 = 3, W1 = 4, W2 = 5, WAIT_IDLE = 6;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            o_ready <= 1'b0;
            adsc_n_reg <= 1'b1;
            we_n_reg <= 1'b1;
            oe_n_reg <= 1'b1;
            data_oe <= 1'b0;
            addr_reg <= 26'd0;
            data_out_reg <= 32'd0;
            o_data <= 16'd0;
        end else begin
            case (state)
                IDLE: begin
                    o_ready <= 1'b0;
                    data_oe <= 1'b0;
                    oe_n_reg <= 1'b1; // Default disable output
                    
                    if (i_wr_en && !o_ready) begin
                        // Initiate Pipelined Write Cycle
                        addr_reg[20:1] <= i_addr; // Map 20-bit address
                        addr_reg[26:21] <= 6'd0;
                        adsc_n_reg <= 1'b0; // Latch address at next edge
                        we_n_reg <= 1'b0;   // Register write command
                        state <= W1;
                    end else if (i_rd_en && !o_ready) begin
                        // Initiate Pipelined Read Cycle
                        addr_reg[20:1] <= i_addr;
                        addr_reg[26:21] <= 6'd0;
                        adsc_n_reg <= 1'b0; // Latch address at next edge
                        we_n_reg <= 1'b1;
                        oe_n_reg <= 1'b0;   // Enable output buffers
                        state <= R1;
                    end else begin
                        adsc_n_reg <= 1'b1;
                        we_n_reg <= 1'b1;
                    end
                end

                // --- WRITE SEQUENCE ---
                W1: begin
                    adsc_n_reg <= 1'b1; // Stop latching address
                    we_n_reg <= 1'b1;   // Stop write command
                    // In pipelined SSRAM, data is latched at the clock edge AFTER address/we_n
                    // Present data now so it's ready for the next clock edge
                    data_out_reg <= {16'd0, i_data};
                    data_oe <= 1'b1;
                    state <= W2;
                end
                
                W2: begin
                    data_oe <= 1'b0; // Stop driving data bus
                    o_ready <= 1'b1; // Write complete
                    state <= WAIT_IDLE;
                end

                // --- READ SEQUENCE ---
                R1: begin
                    adsc_n_reg <= 1'b1; // Stop latching address
                    // Pipeline wait state 1
                    state <= R2;
                end
                
                R2: begin
                    // Pipeline wait state 2
                    state <= R3;
                end
                
                R3: begin
                    // Data is valid on the bus now
                    o_data <= FS_DQ[15:0];
                    oe_n_reg <= 1'b1; // Stop reading
                    o_ready <= 1'b1;  // Read complete
                    state <= WAIT_IDLE;
                end

                WAIT_IDLE: begin
                    // Wait for FSM to acknowledge completion
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
