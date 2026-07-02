module digital_safe_lock #(
    parameter DB_DELAY = 20'd1_000_000,         // Configurable debounce delay (1 million clock cycles at 50MHz ~ 20ms). Set to 1 for simulations.
    parameter TIMER_CYCLES = 28'd100_000_000    // Configurable 2-second timer (100 million clock cycles at 50MHz).
)(
    input  wire CLOCK_50,       // System clock input (50MHz)
    input  wire [17:0] SW,      // Toggle switches (we use SW[7:0] for password input)
    input  wire [3:0] KEY,      // Push buttons. KEY[0]: Reset, KEY[1]: Enter, KEY[2]: Change Pass. (Active Low)
    
    output wire [17:0] LEDR,    // Red LEDs (we use LEDR[0])
    output wire [8:0] LEDG,     // Green LEDs (we use LEDG[0])
    
    output wire [6:0] HEX2,     // Leftmost 7-segment display
    output wire [6:0] HEX1,     // Middle 7-segment display
    output wire [6:0] HEX0,     // Rightmost 7-segment display
    
    // LCD physical interface pins
    output wire LCD_ON,         // Power ON/Backlight Enable
    output wire LCD_RS,         // Register Select
    output wire LCD_RW,         // Read/Write
    output wire LCD_EN,         // Enable
    output wire [7:0] LCD_DATA  // 8-bit Data bus
);

    // Turn off unused LEDs
    assign LEDR[17:1] = 17'd0;
    assign LEDG[8:1] = 8'd0;
    
    // Turn on LCD power/backlight
    assign LCD_ON = 1'b1;

    // Map the reset button to a dedicated wire for clarity
    wire rst_n = KEY[0];
    
    // --- Debouncer Instantiations ---
    // Physical buttons bounce, creating rapid false signals. We must filter these.
    
    wire enter_btn_state; // The stable state of the Enter button
    wire enter_tick;      // A clean 1-clock-cycle pulse when Enter is pressed
    
    button_debounce #(
        .DELAY_CYCLES(DB_DELAY) // Pass down the configurable delay
    ) db_enter (
        .i_clk(CLOCK_50),
        .i_rst_n(rst_n),
        .i_btn(KEY[1]),               // Connect physical KEY[1] (Enter)
        .o_btn_state(enter_btn_state),
        .o_btn_tick(enter_tick)       // Retrieve the clean pulse
    );
    
    wire change_btn_state; // The stable state of the Change button
    wire change_tick;      // A clean 1-clock-cycle pulse when Change is pressed
    
    button_debounce #(
        .DELAY_CYCLES(DB_DELAY) // Pass down the configurable delay
    ) db_change (
        .i_clk(CLOCK_50),
        .i_rst_n(rst_n),
        .i_btn(KEY[2]),               // Connect physical KEY[2] (Change Password)
        .o_btn_state(change_btn_state),
        .o_btn_tick(change_tick)      // Retrieve the clean pulse
    );
    
    // --- Internal RAM Instantiation ---
    // Replaces the physical SRAM with an internal FPGA block RAM / register to save pins and complexity
    
    wire sram_rd_en;                  // Internal read request signal
    wire sram_wr_en;                  // Internal write request signal
    wire [18:0] sram_addr_internal;   // Internal address bus
    wire [15:0] sram_data_to_ctrl;    // Data flowing from FSM into RAM
    wire [15:0] sram_data_from_ctrl;  // Data flowing from RAM into FSM
    wire sram_ready;                  // Handshake signal indicating memory operation is done
    
    internal_ram int_ram (
        .i_clk(CLOCK_50),
        .i_rst_n(rst_n),
        
        // FSM Interface
        .i_rd_en(sram_rd_en),
        .i_wr_en(sram_wr_en),
        .i_addr(sram_addr_internal),
        .i_data(sram_data_to_ctrl),
        .o_data(sram_data_from_ctrl),
        .o_ready(sram_ready)
    );
    
    // --- Central Lock FSM Instantiation ---
    // The "Brain" of the digital safe, managing states and password verification
    
    wire [2:0] display_state; // Internal bus carrying the current display code to the HEX display module
    
    lock_fsm #(
        .TIMER_CYCLES(TIMER_CYCLES) // Pass down the configurable timer length
    ) fsm_inst (
        .i_clk(CLOCK_50),
        .i_rst_n(rst_n),
        
        // UI Inputs
        .i_sw(SW[7:0]),
        .i_enter_tick(enter_tick),
        .i_change_tick(change_tick),
        
        // Communication with the SRAM controller
        .o_sram_rd_en(sram_rd_en),
        .o_sram_wr_en(sram_wr_en),
        .o_sram_addr(sram_addr_internal),
        .o_sram_data_out(sram_data_to_ctrl),
        .i_sram_data(sram_data_from_ctrl),
        .i_sram_ready(sram_ready),
        
        // UI Outputs
        .o_ledr(LEDR[0]),
        .o_ledg(LEDG[0]),
        .o_display_state(display_state)
    );
    
    // --- HEX Display Instantiation ---
    // Translates the FSM's state codes into physical 7-segment LED patterns
    
    hex_display hex_inst (
        .i_state(display_state), // Receives the display code from the FSM
        .o_hex2(HEX2),
        .o_hex1(HEX1),
        .o_hex0(HEX0)
    );
    
    // --- LCD Controller Instantiation ---
    // Translates the FSM's state codes into full text messages on the 16x2 LCD
    
    lcd_controller #(
        .CLK_FREQ(50_000_000)
    ) lcd_inst (
        .i_clk(CLOCK_50),
        .i_rst_n(rst_n),
        .i_state(display_state),
        
        // Physical LCD Pins
        .o_lcd_rs(LCD_RS),
        .o_lcd_rw(LCD_RW),
        .o_lcd_en(LCD_EN),
        .o_lcd_data(LCD_DATA)
    );

endmodule
