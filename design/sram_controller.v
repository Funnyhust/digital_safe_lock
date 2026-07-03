module sram_controller #(
    parameter WAIT_CYCLES = 2
)(
    input  wire        i_clk,
    input  wire        i_rst_n,

    // Simple memory-like interface used by lock_fsm.
    input  wire        i_rd_en,
    input  wire        i_wr_en,
    input  wire [18:0] i_addr,
    input  wire [15:0] i_data,
    output reg  [15:0] o_data,
    output reg         o_ready,

    // External asynchronous SRAM interface, 16-bit data bus.
    output reg  [18:0] SRAM_ADDR,
    inout  wire [15:0] SRAM_DQ,
    output reg         SRAM_CE_N,
    output reg         SRAM_OE_N,
    output reg         SRAM_WE_N,
    output reg         SRAM_LB_N,
    output reg         SRAM_UB_N
);

    localparam [2:0]
        S_IDLE        = 3'd0,
        S_READ_WAIT   = 3'd1,
        S_READ_DONE   = 3'd2,
        S_WRITE_WAIT  = 3'd3,
        S_DONE        = 3'd4;

    reg [2:0] state;
    reg [15:0] dq_out;
    reg dq_drive;
    reg [7:0] wait_cnt;

    assign SRAM_DQ = dq_drive ? dq_out : 16'hzzzz;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state <= S_IDLE;
            SRAM_ADDR <= 19'd0;
            SRAM_CE_N <= 1'b1;
            SRAM_OE_N <= 1'b1;
            SRAM_WE_N <= 1'b1;
            SRAM_LB_N <= 1'b1;
            SRAM_UB_N <= 1'b1;
            dq_out <= 16'd0;
            dq_drive <= 1'b0;
            wait_cnt <= 8'd0;
            o_data <= 16'd0;
            o_ready <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    o_ready <= 1'b0;
                    dq_drive <= 1'b0;
                    SRAM_CE_N <= 1'b1;
                    SRAM_OE_N <= 1'b1;
                    SRAM_WE_N <= 1'b1;
                    SRAM_LB_N <= 1'b1;
                    SRAM_UB_N <= 1'b1;
                    wait_cnt <= 8'd0;

                    if (i_wr_en) begin
                        SRAM_ADDR <= i_addr;
                        dq_out <= i_data;
                        dq_drive <= 1'b1;
                        SRAM_CE_N <= 1'b0;
                        SRAM_OE_N <= 1'b1;
                        SRAM_WE_N <= 1'b0;
                        SRAM_LB_N <= 1'b0;
                        SRAM_UB_N <= 1'b0;
                        state <= S_WRITE_WAIT;
                    end else if (i_rd_en) begin
                        SRAM_ADDR <= i_addr;
                        dq_drive <= 1'b0;
                        SRAM_CE_N <= 1'b0;
                        SRAM_OE_N <= 1'b0;
                        SRAM_WE_N <= 1'b1;
                        SRAM_LB_N <= 1'b0;
                        SRAM_UB_N <= 1'b0;
                        state <= S_READ_WAIT;
                    end
                end

                S_READ_WAIT: begin
                    if (wait_cnt >= WAIT_CYCLES[7:0]) begin
                        o_data <= SRAM_DQ;
                        state <= S_READ_DONE;
                    end else begin
                        wait_cnt <= wait_cnt + 1'b1;
                    end
                end

                S_READ_DONE: begin
                    SRAM_CE_N <= 1'b1;
                    SRAM_OE_N <= 1'b1;
                    SRAM_WE_N <= 1'b1;
                    SRAM_LB_N <= 1'b1;
                    SRAM_UB_N <= 1'b1;
                    o_ready <= 1'b1;
                    state <= S_DONE;
                end

                S_WRITE_WAIT: begin
                    if (wait_cnt >= WAIT_CYCLES[7:0]) begin
                        SRAM_WE_N <= 1'b1;
                        SRAM_CE_N <= 1'b1;
                        SRAM_LB_N <= 1'b1;
                        SRAM_UB_N <= 1'b1;
                        dq_drive <= 1'b0;
                        o_ready <= 1'b1;
                        state <= S_DONE;
                    end else begin
                        wait_cnt <= wait_cnt + 1'b1;
                    end
                end

                S_DONE: begin
                    if (!i_rd_en && !i_wr_en) begin
                        o_ready <= 1'b0;
                        state <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
