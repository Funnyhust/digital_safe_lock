module button_debounce #(
    parameter DELAY_CYCLES = 20'd1_000_000 // Number of clock cycles to wait for the button signal to stabilize
)(
    input  wire i_clk,         // 50MHz system clock
    input  wire i_rst_n,       // Active-low asynchronous reset
    input  wire i_btn,         // Raw, noisy input from the physical push button
    output reg  o_btn_state,   // Clean, debounced state of the button
    output wire o_btn_tick     // 1-clock-cycle pulse generated when the button is pressed (falling edge detected)
);

    reg [19:0] counter;        // 20-bit counter to measure the debounce time delay
    reg btn_sync_0;            // First flip-flop of the synchronizer
    reg btn_sync_1;            // Second flip-flop of the synchronizer
    reg btn_state_prev;        // Register to store the previous state for edge detection

    // Double flip-flop synchronizer to prevent metastability from asynchronous inputs
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            // On reset, initialize synchronizer flip-flops to high (assuming active-low buttons)
            btn_sync_0 <= 1'b1; 
            btn_sync_1 <= 1'b1;
        end else begin
            // Shift the raw input through the two flip-flops
            btn_sync_0 <= i_btn;
            btn_sync_1 <= btn_sync_0;
        end
    end

    // Main debounce logic: wait for the signal to be stable for DELAY_CYCLES
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            // Reset counter and states
            counter <= 20'd0;
            o_btn_state <= 1'b1;      // Default state is unpressed (High for active-low)
            btn_state_prev <= 1'b1;   // Default previous state
        end else begin
            // Store the current debounced state to compare it on the next clock cycle (edge detection)
            btn_state_prev <= o_btn_state; 
            
            // Check if the synchronized input matches the current debounced output
            if (btn_sync_1 == o_btn_state) begin
                // The signal hasn't changed, or it returned to its original state (bounced back), so reset the counter
                counter <= 20'd0; 
            end else begin
                // The signal has changed, start counting clock cycles
                counter <= counter + 1'b1;
                // If the signal remains stable for the required number of cycles
                if (counter == (DELAY_CYCLES - 1)) begin
                    // Update the final debounced output with the new stable state
                    o_btn_state <= btn_sync_1; 
                    // Reset the counter for the next potential button press
                    counter <= 20'd0;
                end
            end
        end
    end

    // Tick generation: output becomes High (1) for exactly 1 clock cycle 
    // when the debounced state transitions from 1 (unpressed) to 0 (pressed)
    assign o_btn_tick = (btn_state_prev == 1'b1) && (o_btn_state == 1'b0);

endmodule
