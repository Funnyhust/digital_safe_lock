module lock_fsm #(
    parameter TIMER_CYCLES = 28'd100_000_000 // Number of clock cycles to wait for the 2-second display timer
)(
    input  wire i_clk,             // System clock
    input  wire i_rst_n,           // Active-low asynchronous reset
    
    // User interface
    input  wire [7:0] i_sw,        // 8-bit input from switches (represents the entered password)
    input  wire i_enter_tick,      // 1-cycle pulse indicating the "Enter" button was pressed
    input  wire i_change_tick,     // 1-cycle pulse indicating the "Change Password" button was pressed
    
    // SRAM controller interface (Communication with the sram_controller module)
    output reg  o_sram_rd_en,      // Signal to request a read operation from SRAM
    output reg  o_sram_wr_en,      // Signal to request a write operation to SRAM
    output reg  [18:0] o_sram_addr,// Address in SRAM to access (Always 0 in this basic design)
    output reg  [15:0] o_sram_data_out, // Data to send TO the SRAM (for writing)
    input  wire [15:0] i_sram_data,// Data received FROM the SRAM (after reading)
    input  wire i_sram_ready,      // Handshake signal indicating the SRAM controller has finished its operation
    
    // Outputs to the physical board
    output reg  o_ledr,            // Red LED (Indicates Locked or Error state)
    output reg  o_ledg,            // Green LED (Indicates Unlocked state)
    output reg  [2:0] o_display_state // 3-bit code sent to the hex_display module to show status text
                                      // 0: Blank ("---"), 1: OPN ("OPn"), 2: ERR ("Err"), 3: CHG ("Chg")
);

    // State Encoding for the Finite State Machine
    localparam S_INIT_WR    = 4'd0; // State: Send initial default password to SRAM on boot
    localparam S_INIT_WAIT  = 4'd1; // State: Wait for SRAM to finish writing the initial password
    localparam S_IDLE       = 4'd2; // State: Safe is locked, waiting for user input
    localparam S_READ_CHECK = 4'd3; // State: Reading password from SRAM and comparing it with user input
    localparam S_UNLOCKED   = 4'd4; // State: Safe is unlocked, waiting for "Lock" or "Change Password" command
    localparam S_ERR        = 4'd5; // State: Wrong password entered, display error for 2 seconds
    localparam S_WRITE_CHG  = 4'd6; // State: Sending new password to SRAM to overwrite the old one
    localparam S_CHG_DONE   = 4'd7; // State: New password saved, display success message for 2 seconds

    reg [3:0] state; // Current FSM state
    
    // --- Separate Timer Logic Block ---
    // This block manages the 2-second delay without cluttering the main state machine.
    reg [27:0] timer; 
    
    // The timer is enabled only when the system is in an error state or showing a successful change
    wire timer_en = (state == S_ERR) || (state == S_CHG_DONE);
    
    // Flag that becomes true when the timer reaches the target count
    wire timer_done = (timer >= TIMER_CYCLES);

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            timer <= 28'd0;
        end else if (timer_en) begin
            // If timer is enabled and hasn't finished, increment it
            if (!timer_done) timer <= timer + 1'b1;
        end else begin
            // Reset the timer immediately if we are not in a state that requires waiting
            timer <= 28'd0; 
        end
    end

    // --- Main Finite State Machine ---
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            // Initialize system into a locked, safe state upon reset
            state <= S_INIT_WR;
            o_sram_rd_en <= 1'b0;
            o_sram_wr_en <= 1'b0;
            o_sram_addr <= 19'd0;
            o_sram_data_out <= 16'd0;
            o_ledr <= 1'b1; // Default to Red LED ON (Locked)
            o_ledg <= 1'b0;
            o_display_state <= 3'd0; // Default to Blank display
        end else begin
            case (state)
                S_INIT_WR: begin
                    // Trigger a write operation to set the default password (00) at address 0
                    o_sram_wr_en <= 1'b1;
                    o_sram_addr <= 19'd0;
                    o_sram_data_out <= 16'h0000; 
                    state <= S_INIT_WAIT;
                end
                
                S_INIT_WAIT: begin
                    // Wait until the SRAM controller confirms the write is complete
                    if (i_sram_ready) begin
                        o_sram_wr_en <= 1'b0; // De-assert write request
                        state <= S_IDLE;      // Move to IDLE (ready for user)
                    end
                end
                
                S_IDLE: begin
                    // Safe is locked. Display is Idle ("---"), Red LED is ON
                    o_ledr <= 1'b1;
                    o_ledg <= 1'b0;
                    o_display_state <= 3'd0; 
                    
                    // Wait for the user to press the Enter button
                    if (i_enter_tick) begin
                        // Request the SRAM controller to fetch the saved password from memory
                        o_sram_rd_en <= 1'b1;
                        o_sram_addr <= 19'd0;
                        state <= S_READ_CHECK;
                    end
                end
                
                S_READ_CHECK: begin
                    // Wait until SRAM fetches the data
                    if (i_sram_ready) begin
                        // Compare the lowest 8 bits from memory against the physical switches
                        if (i_sram_data[7:0] == i_sw) begin
                            // Passwords match -> Unlock the safe
                            state <= S_UNLOCKED;
                        end else begin
                            // Passwords mismatch -> Deny access, go to Error state
                            state <= S_ERR;
                        end
                        o_sram_rd_en <= 1'b0; // De-assert read request
                    end
                end
                
                S_UNLOCKED: begin
                    // Safe is unlocked. Display "OPN", Green LED is ON
                    o_ledr <= 1'b0;
                    o_ledg <= 1'b1;
                    o_display_state <= 3'd1; 
                    
                    if (i_change_tick) begin
                        // User pressed "Change". We will overwrite the old password with the current switch values
                        o_sram_wr_en <= 1'b1;
                        o_sram_addr <= 19'd0;
                        o_sram_data_out <= {8'h00, i_sw}; // Pad 8-bit switch value to 16-bit word
                        state <= S_WRITE_CHG;
                    end else if (i_enter_tick) begin
                        // User pressed "Enter" while unlocked -> Lock the safe again
                        state <= S_IDLE;
                    end
                end
                
                S_ERR: begin
                    // Access Denied. Display "ERR", Red LED is ON
                    o_ledr <= 1'b1;
                    o_ledg <= 1'b0;
                    o_display_state <= 3'd2; 
                    
                    // Remain in this state until the 2-second timer finishes, OR the user presses Enter again to bypass
                    if (timer_done || i_enter_tick) begin
                        state <= S_IDLE; // Return to locked state
                    end
                end
                
                S_WRITE_CHG: begin
                    // Wait for the SRAM controller to finish saving the new password
                    if (i_sram_ready) begin
                        o_sram_wr_en <= 1'b0; // De-assert write request
                        state <= S_CHG_DONE;
                    end
                end
                
                S_CHG_DONE: begin
                    // Password successfully changed. Display "CHG", Green LED remains ON
                    o_ledr <= 1'b0;
                    o_ledg <= 1'b1; 
                    o_display_state <= 3'd3; 
                    
                    // Remain in this state to display the message until the 2-second timer finishes
                    if (timer_done) begin
                        state <= S_UNLOCKED; // Automatically return to the Unlocked state
                    end
                end
                
                default: state <= S_INIT_WR; // Fallback to initialization for safety
            endcase
        end
    end

endmodule
