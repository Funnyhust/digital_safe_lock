`timescale 1ns/1ps // Set simulation timescale: 1 nanosecond time unit, 1 picosecond precision

module tb_digital_safe_lock();

    // --- Signal Declarations ---
    // Registers are used for signals that we generate/drive inside the testbench (Inputs to the DUT)
    reg CLOCK_50;   // 50MHz Clock
    reg [17:0] SW;  // 18 toggle switches for password input
    reg [3:0] KEY;  // 4 push buttons (Active Low)
    
    // Wires are used to observe signals coming out of the DUT (Outputs from the DUT)
    wire [17:0] LEDR; // Red LEDs
    wire [8:0] LEDG;  // Green LEDs
    wire [6:0] HEX2;  // 7-Segment Displays
    wire [6:0] HEX1;
    wire [6:0] HEX0;
    
    // LCD physical interface wires
    wire LCD_ON;
    wire LCD_RS;
    wire LCD_RW;
    wire LCD_EN;
    wire [7:0] LCD_DATA;
    
    // SSRAM wires
    wire [31:0] FS_DQ;
    wire [26:1] FS_ADDR;
    wire SSRAM0_CE_N;
    wire SSRAM1_CE_N;
    wire SSRAM_ADSC_N;
    wire SSRAM_ADSP_N;
    wire SSRAM_ADV_N;
    wire [3:0]  SSRAM_BE;
    wire SSRAM_CLK;
    wire SSRAM_GW_N;
    wire SSRAM_OE_N;
    wire SSRAM_WE_N;
    
    // --- Device Under Test (DUT) Instantiation ---
    // Instantiate the Top Module with simulation-friendly parameters to drastically speed up the test
    // DB_DELAY = 1 ensures instant debouncing (no waiting millions of cycles for a button press)
    // TIMER_CYCLES = 20 ensures the 2-second display timer finishes in just 400ns
    digital_safe_lock #(
        .DB_DELAY(20'd1),
        .TIMER_CYCLES(28'd200_000) // 200,000 cycles = 4ms timer
    ) dut (
        .CLOCK_50(CLOCK_50),
        .SW(SW),
        .KEY(KEY),
        .LEDR(LEDR),
        .LEDG(LEDG),
        .HEX2(HEX2),
        .HEX1(HEX1),
        .HEX0(HEX0),
        .LCD_ON(LCD_ON),
        .LCD_RS(LCD_RS),
        .LCD_RW(LCD_RW),
        .LCD_EN(LCD_EN),
        .LCD_DATA(LCD_DATA),
        .FS_DQ(FS_DQ),
        .FS_ADDR(FS_ADDR),
        .SSRAM0_CE_N(SSRAM0_CE_N),
        .SSRAM1_CE_N(SSRAM1_CE_N),
        .SSRAM_ADSC_N(SSRAM_ADSC_N),
        .SSRAM_ADSP_N(SSRAM_ADSP_N),
        .SSRAM_ADV_N(SSRAM_ADV_N),
        .SSRAM_BE(SSRAM_BE),
        .SSRAM_CLK(SSRAM_CLK),
        .SSRAM_GW_N(SSRAM_GW_N),
        .SSRAM_OE_N(SSRAM_OE_N),
        .SSRAM_WE_N(SSRAM_WE_N)
    );

    // Instantiate mock async SSRAM
    mock_ssram ssram_chip (
        .FS_DQ(FS_DQ),
        .FS_ADDR(FS_ADDR),
        .SSRAM0_CE_N(SSRAM0_CE_N),
        .SSRAM1_CE_N(SSRAM1_CE_N),
        .SSRAM_ADSC_N(SSRAM_ADSC_N),
        .SSRAM_ADSP_N(SSRAM_ADSP_N),
        .SSRAM_ADV_N(SSRAM_ADV_N),
        .SSRAM_BE(SSRAM_BE),
        .SSRAM_CLK(SSRAM_CLK),
        .SSRAM_GW_N(SSRAM_GW_N),
        .SSRAM_OE_N(SSRAM_OE_N),
        .SSRAM_WE_N(SSRAM_WE_N)
    );

    // --- Clock Generation ---
    initial begin
        CLOCK_50 = 0;
        // Toggle the clock every 10ns, creating a 20ns period (50MHz frequency)
        forever #10 CLOCK_50 = ~CLOCK_50;
    end

    // --- Tasks for Modular, Self-Checking Tests ---
    
    // Task 1: Perform a hardware reset
    task reset_system;
        begin
            KEY[0] = 1'b0;       // Assert Reset (Active Low)
            #100 KEY[0] = 1'b1;  // De-assert Reset after 100ns
            // SRAM init is extremely fast (just 2 clock cycles)
            #1000;               // Wait 1us
        end
    endtask

    // Task 2: Simulate a user entering a password and pressing a specific button
    // btn_type: 1 for Enter (KEY[1]), 2 for Change (KEY[2])
    task enter_password(input [7:0] pass, input [1:0] btn_type);
        begin
            SW[7:0] = pass; // Flip the physical switches to set the password
            
            if (btn_type == 1) begin
                KEY[1] = 1'b0; // Press the 'Enter' button
                #40;           // Hold it down for 40ns
                KEY[1] = 1'b1; // Release the button
            end else if (btn_type == 2) begin
                KEY[2] = 1'b0; // Press the 'Change Password' button
                #40;           
                KEY[2] = 1'b1; 
            end
            
            // SRAM read/write takes 2 clock cycles (40ns).
            #1000; // Wait 1us
        end
    endtask

    // Task 3: Wait for the display timer (e.g., the 2-second "ERR" or "CHG" display) to finish naturally
    task wait_for_display_timer;
        begin
            // Since we parameterized TIMER_CYCLES to 200,000, the timer is 4ms.
            // We wait 4.1 million ns (4.1ms) to ensure it expires safely.
            #4100000; 
        end
    endtask

    // Task 4: Verify the outcome automatically
    task check_result(input expected_ledg, input expected_ledr, input [7:0] test_num);
        begin
            if (LEDG[0] == expected_ledg && LEDR[0] == expected_ledr) begin
                $display("Pass: Test %0d (LEDG=%b, LEDR=%b)", test_num, LEDG[0], LEDR[0]);
            end else begin
                $display("Fail: Test %0d - Expected LEDG=%b LEDR=%b, Got LEDG=%b LEDR=%b", 
                         test_num, expected_ledg, expected_ledr, LEDG[0], LEDR[0]);
                $stop; // Pause simulation on failure
            end
        end
    endtask

    // --- Main Simulation Block ---
    initial begin
        // Initialize inputs
        SW = 18'd0;
        KEY = 4'b1111; // Buttons are active low, so 1 means unpressed
        
        $dumpfile("waveform.vcd"); 
        $dumpvars(0, tb_digital_safe_lock); 
        
        $display("========================================");
        $display("   DIGITAL SAFE LOCK - TESTBENCH START  ");
        $display("========================================");

        // Reset the system to its initial state
        reset_system();

        // --- Test 1: Try unlocking with the default password ---
        $display("\n[Test 1] Unlock with default password (00)");
        enter_password(8'h00, 1);
        check_result(1'b1, 1'b0, 1); // We expect Green LED ON (Unlock Success)

        // --- Test 2: Change the password to a new value (e.g., A5) ---
        $display("\n[Test 2] Change password to A5");
        enter_password(8'hA5, 2); // Press 'Change' button
        $display("Password changed to A5.");
        wait_for_display_timer(); // Wait for "CHANGED!" to disappear
        
        // Relock the safe before testing the new password
        $display("\nLocking the safe...");
        enter_password(8'h00, 1); // Password doesn't matter when locking
        
        // --- Test 3: Try unlocking with the WRONG password (11) ---
        $display("\n[Test 3] Try unlocking with WRONG password (11)");
        enter_password(8'h11, 1);
        check_result(1'b0, 1'b1, 3); // We expect Red LED ON (Error)
        wait_for_display_timer();    // Wait for the "ERROR!" display to finish
        
        // --- Test 4: Try unlocking with the NEW CORRECT password (A5) ---
        $display("\n[Test 4] Unlock with NEW password (A5)");
        enter_password(8'hA5, 1);
        check_result(1'b1, 1'b0, 4); // We expect Green LED ON, Red LED OFF
        
        // Relock the safe before proceeding
        $display("\nLocking the safe...");
        enter_password(8'h00, 1);    // Password switch values don't matter when locking, just pressing 'Enter' is enough
        
        // --- Test 5: Rapid succession of incorrect passwords (Spamming) ---
        $display("\n[Test 5] Spam wrong password multiple times");
        enter_password(8'h99, 1);
        check_result(1'b0, 1'b1, 51);
        wait_for_display_timer();
        
        enter_password(8'h88, 1);
        check_result(1'b0, 1'b1, 52);
        wait_for_display_timer();

        // --- Test 6: Verify the system still works after being spammed with errors ---
        $display("\n[Test 6] Unlock again with correct password (A5)");
        enter_password(8'hA5, 1);
        check_result(1'b1, 1'b0, 6);

        // Relock
        $display("\nLocking the safe...");
        enter_password(8'hA5, 1);

        // --- Test 8: Attempt to change password while locked ---
        $display("\n[Test 8] Try changing password without unlocking");
        // Safe is currently locked. Try to change password to BB.
        enter_password(8'hBB, 2); // Press 'Change' button
        wait_for_display_timer();
        
        $display("  > Verify password didn't change to BB");
        enter_password(8'hBB, 1);
        check_result(1'b0, 1'b1, 81); // BB should fail
        wait_for_display_timer();
        
        $display("  > Verify A5 still works");
        enter_password(8'hA5, 1);
        check_result(1'b1, 1'b0, 82); // A5 should still work
        
        // Relock
        $display("\nLocking the safe...");
        enter_password(8'hA5, 1);

        // --- Test 9: Bypass ERR state with Enter button (Early Exit) ---
        $display("\n[Test 9] Early exit from ERR state");
        // Enter wrong password to trigger ERR state
        SW[7:0] = 8'h99; 
        KEY[1] = 1'b0; // Press Enter
        #40;
        KEY[1] = 1'b1;
        
        #1000; // Wait for SRAM read and transition to ERR
        check_result(1'b0, 1'b1, 91); // Confirm we are in ERR state
        
        // normally wait_for_display_timer is called (which is 4ms).
        $display("  > Pressing Enter to bypass the error timer");
        KEY[1] = 1'b0;
        #40;
        KEY[1] = 1'b1;
        #1000; // Wait for FSM to transition back to IDLE
        
        // Prove we are back in IDLE by immediately unlocking with correct password
        $display("  > Unlocking immediately with A5");
        enter_password(8'hA5, 1);
        check_result(1'b1, 1'b0, 92);

        // Simulation is finished
        #500;
        $display("========================================");
        $display("          SIMULATION COMPLETE           ");
        $display("========================================");
        $finish;
    end

endmodule
