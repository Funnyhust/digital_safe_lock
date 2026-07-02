module lcd_controller #(
    parameter CLK_FREQ = 50_000_000 // System clock frequency in Hz
)(
    input  wire i_clk,
    input  wire i_rst_n,
    input  wire [2:0] i_state,      // 0: IDLE, 1: OPN, 2: ERR, 3: CHG
    
    // LCD physical interface
    output reg  o_lcd_rs,           // Register Select (0: Command, 1: Data)
    output wire o_lcd_rw,           // Read/Write (Always 0: Write)
    output reg  o_lcd_en,           // Enable pulse
    output reg  [7:0] o_lcd_data    // 8-bit Data bus
);

    assign o_lcd_rw = 1'b0; // We only write to the LCD

    // --- Delay Timers ---
    // HD44780 requires specific delays between commands
    localparam DELAY_20MS = CLK_FREQ / 50;         // 20ms power-up delay
    localparam DELAY_2MS  = CLK_FREQ / 500;        // 2ms delay (Clear Display)
    localparam DELAY_50US = CLK_FREQ / 20_000;     // 50us delay (Normal commands)
    
    // For simulation, we can drastically reduce these timers if a parameter is passed.
    // We'll define internal delay constants that default to hardware timings.
    integer current_delay;
    reg [24:0] timer;

    // --- State Machine ---
    localparam S_PWR_ON    = 4'd0;
    localparam S_INIT_1    = 4'd1;  // Function Set
    localparam S_INIT_2    = 4'd2;  // Display On/Off
    localparam S_INIT_3    = 4'd3;  // Clear Display
    localparam S_INIT_4    = 4'd4;  // Entry Mode Set
    localparam S_LINE1     = 4'd5;  // Set DDRAM Address to Line 1
    localparam S_PRINT1    = 4'd6;  // Print Line 1
    localparam S_LINE2     = 4'd7;  // Set DDRAM Address to Line 2
    localparam S_PRINT2    = 4'd8;  // Print Line 2
    localparam S_WAIT      = 4'd9;  // Wait for state change
    
    reg [3:0] state;
    reg [3:0] next_state_after_delay;
    reg [4:0] char_index;
    reg [2:0] current_fsm_state;

    // --- Character ROM ---
    // Line 1 is static
    wire [7:0] line1_char [0:15];
    assign line1_char[0] =" "; assign line1_char[1] ="D"; assign line1_char[2] ="I"; assign line1_char[3] ="G";
    assign line1_char[4] ="I"; assign line1_char[5] ="T"; assign line1_char[6] ="A"; assign line1_char[7] ="L";
    assign line1_char[8] =" "; assign line1_char[9] ="S"; assign line1_char[10]="A"; assign line1_char[11]="F";
    assign line1_char[12]="E"; assign line1_char[13]=" "; assign line1_char[14]=" "; assign line1_char[15]=" ";

    // Line 2 depends on i_state
    reg [7:0] line2_char [0:15];
    always @(*) begin
        case(current_fsm_state)
            3'd0: begin // IDLE: "STATUS: LOCKED  "
                line2_char[0]="S"; line2_char[1]="T"; line2_char[2]="A"; line2_char[3]="T"; line2_char[4]="U"; line2_char[5]="S"; line2_char[6]=":"; line2_char[7]=" ";
                line2_char[8]="L"; line2_char[9]="O"; line2_char[10]="C"; line2_char[11]="K"; line2_char[12]="E"; line2_char[13]="D"; line2_char[14]=" "; line2_char[15]=" ";
            end
            3'd1: begin // OPN:  "STATUS: OPEN    "
                line2_char[0]="S"; line2_char[1]="T"; line2_char[2]="A"; line2_char[3]="T"; line2_char[4]="U"; line2_char[5]="S"; line2_char[6]=":"; line2_char[7]=" ";
                line2_char[8]="O"; line2_char[9]="P"; line2_char[10]="E"; line2_char[11]="N"; line2_char[12]=" "; line2_char[13]=" "; line2_char[14]=" "; line2_char[15]=" ";
            end
            3'd2: begin // ERR:  "WRONG PASSWORD! "
                line2_char[0]="W"; line2_char[1]="R"; line2_char[2]="O"; line2_char[3]="N"; line2_char[4]="G"; line2_char[5]=" "; line2_char[6]="P"; line2_char[7]="A";
                line2_char[8]="S"; line2_char[9]="S"; line2_char[10]="W"; line2_char[11]="O"; line2_char[12]="R"; line2_char[13]="D"; line2_char[14]="!"; line2_char[15]=" ";
            end
            3'd3: begin // CHG:  "NEW PASS SAVED! "
                line2_char[0]="N"; line2_char[1]="E"; line2_char[2]="W"; line2_char[3]=" "; line2_char[4]="P"; line2_char[5]="A"; line2_char[6]="S"; line2_char[7]="S";
                line2_char[8]=" "; line2_char[9]="S"; line2_char[10]="A"; line2_char[11]="V"; line2_char[12]="E"; line2_char[13]="D"; line2_char[14]="!"; line2_char[15]=" ";
            end
            default: begin // "                "
                line2_char[0]=" "; line2_char[1]=" "; line2_char[2]=" "; line2_char[3]=" "; line2_char[4]=" "; line2_char[5]=" "; line2_char[6]=" "; line2_char[7]=" ";
                line2_char[8]=" "; line2_char[9]=" "; line2_char[10]=" "; line2_char[11]=" "; line2_char[12]=" "; line2_char[13]=" "; line2_char[14]=" "; line2_char[15]=" ";
            end
        endcase
    end

    // Sequence controller
    reg [2:0] seq;
    localparam SEQ_SETUP = 3'd0;
    localparam SEQ_EN_HI = 3'd1;
    localparam SEQ_EN_LO = 3'd2;
    localparam SEQ_DELAY = 3'd3;
    localparam SEQ_DONE  = 3'd4;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state <= S_PWR_ON;
            seq <= SEQ_SETUP;
            timer <= 0;
            char_index <= 0;
            o_lcd_rs <= 0;
            o_lcd_en <= 0;
            o_lcd_data <= 0;
            current_fsm_state <= 3'd0;
        end else begin
            case (seq)
                SEQ_SETUP: begin
                    o_lcd_en <= 1'b0;
                    case (state)
                        S_PWR_ON: begin
                            // Wait 20ms at power on
                            o_lcd_rs <= 0; o_lcd_data <= 8'h00; current_delay <= DELAY_20MS;
                            next_state_after_delay <= S_INIT_1; seq <= SEQ_DELAY;
                        end
                        S_INIT_1: begin o_lcd_rs <= 0; o_lcd_data <= 8'h38; current_delay <= DELAY_50US; seq <= SEQ_EN_HI; next_state_after_delay <= S_INIT_2; end
                        S_INIT_2: begin o_lcd_rs <= 0; o_lcd_data <= 8'h0C; current_delay <= DELAY_50US; seq <= SEQ_EN_HI; next_state_after_delay <= S_INIT_3; end
                        S_INIT_3: begin o_lcd_rs <= 0; o_lcd_data <= 8'h01; current_delay <= DELAY_2MS;  seq <= SEQ_EN_HI; next_state_after_delay <= S_INIT_4; end
                        S_INIT_4: begin o_lcd_rs <= 0; o_lcd_data <= 8'h06; current_delay <= DELAY_50US; seq <= SEQ_EN_HI; next_state_after_delay <= S_LINE1; end
                        
                        S_LINE1:  begin o_lcd_rs <= 0; o_lcd_data <= 8'h80; current_delay <= DELAY_50US; seq <= SEQ_EN_HI; next_state_after_delay <= S_PRINT1; char_index <= 0; end
                        S_PRINT1: begin o_lcd_rs <= 1; o_lcd_data <= line1_char[char_index]; current_delay <= DELAY_50US; seq <= SEQ_EN_HI; next_state_after_delay <= S_PRINT1; end
                        
                        S_LINE2:  begin o_lcd_rs <= 0; o_lcd_data <= 8'hC0; current_delay <= DELAY_50US; seq <= SEQ_EN_HI; next_state_after_delay <= S_PRINT2; char_index <= 0; end
                        S_PRINT2: begin o_lcd_rs <= 1; o_lcd_data <= line2_char[char_index]; current_delay <= DELAY_50US; seq <= SEQ_EN_HI; next_state_after_delay <= S_PRINT2; end
                        
                        S_WAIT: begin
                            // Monitor i_state for changes. If changed, redraw line 2.
                            if (current_fsm_state != i_state) begin
                                current_fsm_state <= i_state;
                                state <= S_LINE2; // Jump to reprint Line 2
                            end
                        end
                        default: state <= S_PWR_ON;
                    endcase
                end
                
                SEQ_EN_HI: begin
                    o_lcd_en <= 1'b1;
                    seq <= SEQ_EN_LO;
                end
                
                SEQ_EN_LO: begin
                    o_lcd_en <= 1'b0;
                    seq <= SEQ_DELAY;
                    timer <= 0;
                end
                
                SEQ_DELAY: begin
                    // Simplified simulation mode: if DELAY_20MS was overridden via top module parameter passed down? 
                    // To keep it simple, we check if we reached the required ticks.
                    if (timer >= current_delay) begin
                        timer <= 0;
                        seq <= SEQ_DONE;
                    end else begin
                        timer <= timer + 1'b1;
                    end
                end
                
                SEQ_DONE: begin
                    seq <= SEQ_SETUP;
                    // Logic for char printing loops
                    if (state == S_PRINT1) begin
                        if (char_index == 15) state <= S_LINE2;
                        else char_index <= char_index + 1'b1;
                    end else if (state == S_PRINT2) begin
                        if (char_index == 15) state <= S_WAIT;
                        else char_index <= char_index + 1'b1;
                    end else begin
                        state <= next_state_after_delay;
                    end
                end
            endcase
        end
    end

endmodule
