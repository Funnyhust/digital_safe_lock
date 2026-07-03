module eeprom_i2c #(
    parameter CLK_FREQ = 50_000_000,
    parameter I2C_FREQ = 100_000,
    parameter WRITE_WAIT_CYCLES = 250_000,
    parameter DEV_ADDR = 7'h50
)(
    input  wire i_clk,
    input  wire i_rst_n,

    // Memory-like interface, compatible with internal_ram.
    input  wire i_rd_en,
    input  wire i_wr_en,
    input  wire [18:0] i_addr,
    input  wire [15:0] i_data,
    output reg  [15:0] o_data,
    output reg  o_ready,
    output reg  o_busy,
    output reg  o_error,

    // DE2i-150 EEPROM I2C pins.
    output reg  o_i2c_sclk,
    inout  wire io_i2c_sdat
);

    localparam integer HALF_PERIOD = (CLK_FREQ / (I2C_FREQ * 2));
    localparam integer DIV_WIDTH = 16;

    localparam [5:0]
        ST_IDLE          = 6'd0,
        ST_START_A       = 6'd1,
        ST_START_B       = 6'd2,
        ST_SEND_SETUP    = 6'd3,
        ST_SEND_LOW      = 6'd4,
        ST_SEND_HIGH     = 6'd5,
        ST_ACK_LOW       = 6'd6,
        ST_ACK_HIGH      = 6'd7,
        ST_RECV_LOW      = 6'd8,
        ST_RECV_HIGH     = 6'd9,
        ST_MACK_LOW      = 6'd10,
        ST_MACK_HIGH     = 6'd11,
        ST_STOP_A        = 6'd12,
        ST_STOP_B        = 6'd13,
        ST_WRITE_WAIT    = 6'd14,
        ST_DONE          = 6'd15;

    localparam [4:0]
        OP_IDLE          = 5'd0,
        OP_WR_DEV        = 5'd1,
        OP_WR_ADDR       = 5'd2,
        OP_WR_MSB        = 5'd3,
        OP_WR_LSB        = 5'd4,
        OP_RD_DEV_W      = 5'd5,
        OP_RD_ADDR       = 5'd6,
        OP_RD_DEV_R      = 5'd7,
        OP_RD_MSB        = 5'd8,
        OP_RD_LSB        = 5'd9;

    reg [5:0] state;
    reg [4:0] op;
    reg [7:0] tx_byte;
    reg [7:0] rx_byte;
    reg [7:0] addr_byte;
    reg [15:0] write_data;
    reg [2:0] bit_idx;
    reg [DIV_WIDTH-1:0] div_cnt;
    reg [31:0] write_wait_cnt;
    reg sda_drive_low;
    reg ack_from_slave;
    reg master_ack;

    wire tick = (div_cnt == HALF_PERIOD - 1);
    wire sda_in = io_i2c_sdat;

    assign io_i2c_sdat = sda_drive_low ? 1'b0 : 1'bz;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            div_cnt <= {DIV_WIDTH{1'b0}};
        end else if (state == ST_IDLE || state == ST_DONE || state == ST_WRITE_WAIT) begin
            div_cnt <= {DIV_WIDTH{1'b0}};
        end else if (tick) begin
            div_cnt <= {DIV_WIDTH{1'b0}};
        end else begin
            div_cnt <= div_cnt + 1'b1;
        end
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state <= ST_IDLE;
            op <= OP_IDLE;
            tx_byte <= 8'd0;
            rx_byte <= 8'd0;
            addr_byte <= 8'd0;
            write_data <= 16'd0;
            bit_idx <= 3'd7;
            write_wait_cnt <= 32'd0;
            sda_drive_low <= 1'b0;
            o_i2c_sclk <= 1'b1;
            o_data <= 16'd0;
            o_ready <= 1'b0;
            o_busy <= 1'b0;
            o_error <= 1'b0;
            ack_from_slave <= 1'b1;
            master_ack <= 1'b1;
        end else begin
            case (state)
                ST_IDLE: begin
                    o_i2c_sclk <= 1'b1;
                    sda_drive_low <= 1'b0;
                    o_ready <= 1'b0;
                    o_busy <= 1'b0;

                    if (i_wr_en) begin
                        o_busy <= 1'b1;
                        o_error <= 1'b0;
                        addr_byte <= i_addr[7:0];
                        write_data <= i_data;
                        op <= OP_WR_DEV;
                        state <= ST_START_A;
                    end else if (i_rd_en) begin
                        o_busy <= 1'b1;
                        o_error <= 1'b0;
                        addr_byte <= i_addr[7:0];
                        op <= OP_RD_DEV_W;
                        state <= ST_START_A;
                    end
                end

                ST_START_A: begin
                    o_i2c_sclk <= 1'b1;
                    sda_drive_low <= 1'b0;
                    if (tick) state <= ST_START_B;
                end

                ST_START_B: begin
                    o_i2c_sclk <= 1'b1;
                    sda_drive_low <= 1'b1;
                    if (tick) state <= ST_SEND_SETUP;
                end

                ST_SEND_SETUP: begin
                    o_i2c_sclk <= 1'b0;
                    bit_idx <= 3'd7;
                    case (op)
                        OP_WR_DEV,
                        OP_RD_DEV_W: tx_byte <= {DEV_ADDR, 1'b0};
                        OP_WR_ADDR,
                        OP_RD_ADDR:  tx_byte <= addr_byte;
                        OP_WR_MSB:   tx_byte <= write_data[15:8];
                        OP_WR_LSB:   tx_byte <= write_data[7:0];
                        OP_RD_DEV_R: tx_byte <= {DEV_ADDR, 1'b1};
                        default:     tx_byte <= 8'h00;
                    endcase
                    if (tick) state <= ST_SEND_LOW;
                end

                ST_SEND_LOW: begin
                    o_i2c_sclk <= 1'b0;
                    sda_drive_low <= (tx_byte[bit_idx] == 1'b0);
                    if (tick) state <= ST_SEND_HIGH;
                end

                ST_SEND_HIGH: begin
                    o_i2c_sclk <= 1'b1;
                    if (tick) begin
                        if (bit_idx == 3'd0) begin
                            state <= ST_ACK_LOW;
                        end else begin
                            bit_idx <= bit_idx - 1'b1;
                            state <= ST_SEND_LOW;
                        end
                    end
                end

                ST_ACK_LOW: begin
                    o_i2c_sclk <= 1'b0;
                    sda_drive_low <= 1'b0;
                    if (tick) state <= ST_ACK_HIGH;
                end

                ST_ACK_HIGH: begin
                    o_i2c_sclk <= 1'b1;
                    if (tick) begin
                        ack_from_slave <= sda_in;
                        if (sda_in) o_error <= 1'b1;
                        case (op)
                            OP_WR_DEV: begin
                                op <= OP_WR_ADDR;
                                state <= ST_SEND_SETUP;
                            end
                            OP_WR_ADDR: begin
                                op <= OP_WR_MSB;
                                state <= ST_SEND_SETUP;
                            end
                            OP_WR_MSB: begin
                                op <= OP_WR_LSB;
                                state <= ST_SEND_SETUP;
                            end
                            OP_WR_LSB: begin
                                state <= ST_STOP_A;
                            end
                            OP_RD_DEV_W: begin
                                op <= OP_RD_ADDR;
                                state <= ST_SEND_SETUP;
                            end
                            OP_RD_ADDR: begin
                                op <= OP_RD_DEV_R;
                                state <= ST_START_A;
                            end
                            OP_RD_DEV_R: begin
                                op <= OP_RD_MSB;
                                bit_idx <= 3'd7;
                                rx_byte <= 8'd0;
                                state <= ST_RECV_LOW;
                            end
                            default: begin
                                state <= ST_STOP_A;
                            end
                        endcase
                    end
                end

                ST_RECV_LOW: begin
                    o_i2c_sclk <= 1'b0;
                    sda_drive_low <= 1'b0;
                    if (tick) state <= ST_RECV_HIGH;
                end

                ST_RECV_HIGH: begin
                    o_i2c_sclk <= 1'b1;
                    if (tick) begin
                        rx_byte[bit_idx] <= sda_in;
                        if (bit_idx == 3'd0) begin
                            master_ack <= (op == OP_RD_MSB) ? 1'b0 : 1'b1;
                            state <= ST_MACK_LOW;
                        end else begin
                            bit_idx <= bit_idx - 1'b1;
                            state <= ST_RECV_LOW;
                        end
                    end
                end

                ST_MACK_LOW: begin
                    o_i2c_sclk <= 1'b0;
                    sda_drive_low <= (master_ack == 1'b0);
                    if (tick) state <= ST_MACK_HIGH;
                end

                ST_MACK_HIGH: begin
                    o_i2c_sclk <= 1'b1;
                    if (tick) begin
                        if (op == OP_RD_MSB) begin
                            o_data[15:8] <= {rx_byte[7:1], sda_in};
                            op <= OP_RD_LSB;
                            bit_idx <= 3'd7;
                            rx_byte <= 8'd0;
                            state <= ST_RECV_LOW;
                        end else begin
                            o_data[7:0] <= {rx_byte[7:1], sda_in};
                            state <= ST_STOP_A;
                        end
                    end
                end

                ST_STOP_A: begin
                    o_i2c_sclk <= 1'b0;
                    sda_drive_low <= 1'b1;
                    if (tick) state <= ST_STOP_B;
                end

                ST_STOP_B: begin
                    o_i2c_sclk <= 1'b1;
                    sda_drive_low <= 1'b1;
                    if (tick) begin
                        sda_drive_low <= 1'b0;
                        if (i_wr_en) begin
                            write_wait_cnt <= 32'd0;
                            state <= ST_WRITE_WAIT;
                        end else begin
                            state <= ST_DONE;
                        end
                    end
                end

                ST_WRITE_WAIT: begin
                    o_i2c_sclk <= 1'b1;
                    sda_drive_low <= 1'b0;
                    if (write_wait_cnt >= WRITE_WAIT_CYCLES) begin
                        state <= ST_DONE;
                    end else begin
                        write_wait_cnt <= write_wait_cnt + 1'b1;
                    end
                end

                ST_DONE: begin
                    o_ready <= 1'b1;
                    o_busy <= 1'b0;
                    o_i2c_sclk <= 1'b1;
                    sda_drive_low <= 1'b0;
                    if (!i_rd_en && !i_wr_en) begin
                        o_ready <= 1'b0;
                        state <= ST_IDLE;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
