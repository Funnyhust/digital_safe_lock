module hex_display (
    input  wire [2:0] i_state,    // Current display state provided by the FSM (0: Idle, 1: OPN, 2: ERR, 3: CHG)
    output reg  [6:0] o_hex2,     // 7-segment control signals for the leftmost display (HEX2)
    output reg  [6:0] o_hex1,     // 7-segment control signals for the middle display (HEX1)
    output reg  [6:0] o_hex0      // 7-segment control signals for the rightmost display (HEX0)
);

    // Constant declarations for the 7-segment character encodings.
    // Note: The segments are active-low (0 = ON, 1 = OFF).
    // The bit mapping is typically: {g, f, e, d, c, b, a}
    
    // Characters for "OPn" (OPEN)
    localparam CHAR_O = 7'h40;    // Displays 'O'
    localparam CHAR_P = 7'h0C;    // Displays 'P'
    localparam CHAR_n = 7'h2B;    // Displays 'n'
    
    // Characters for "Err" (ERROR)
    localparam CHAR_E = 7'h06;    // Displays 'E'
    localparam CHAR_r = 7'h2F;    // Displays 'r'
    
    // Characters for "Chg" (CHANGE)
    localparam CHAR_C = 7'h46;    // Displays 'C'
    localparam CHAR_h = 7'h0B;    // Displays 'h'
    localparam CHAR_g = 7'h10;    // Displays 'g'
    
    // Character for "---" (IDLE / Blank)
    localparam CHAR_DASH = 7'h3F; // Displays a middle dash '-'

    // Combinational logic block to decode the state into 7-segment patterns
    always @(*) begin
        case (i_state)
            3'd0: begin 
                // State 0: System is IDLE. Display "---"
                o_hex2 = CHAR_DASH;
                o_hex1 = CHAR_DASH;
                o_hex0 = CHAR_DASH;
            end
            3'd1: begin 
                // State 1: System is UNLOCKED. Display "OPn"
                o_hex2 = CHAR_O;
                o_hex1 = CHAR_P;
                o_hex0 = CHAR_n;
            end
            3'd2: begin 
                // State 2: Wrong password entered. Display "Err"
                o_hex2 = CHAR_E;
                o_hex1 = CHAR_r;
                o_hex0 = CHAR_r;
            end
            3'd3: begin 
                // State 3: Password successfully changed. Display "Chg"
                o_hex2 = CHAR_C;
                o_hex1 = CHAR_h;
                o_hex0 = CHAR_g;
            end
            default: begin
                // Default fallback: Display "---" to prevent undefined latches
                o_hex2 = CHAR_DASH;
                o_hex1 = CHAR_DASH;
                o_hex0 = CHAR_DASH;
            end
        endcase
    end

endmodule
