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

    // --- Device Under Test (DUT) Instantiation ---
    // Instantiate the Top Module with simulation-friendly parameters to drastically speed up the test
    // DB_DELAY = 1 ensures instant debouncing (no waiting millions of cycles for a button press)
    // TIMER_CYCLES = 20 ensures the 2-second display timer finishes in just 400ns
    digital_safe_lock #(
        .DB_DELAY(20'd1),
        .TIMER_CYCLES(28'd20)
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
        .LCD_DATA(LCD_DATA)
    );

    // The memory is now internal to the FPGA (internal_ram), so we don't need
    // an external SRAM behavioral model anymore.

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
            #200;                // Wait 200ns to allow the FSM to finish writing the default password to SRAM
        end
    endtask

    // Task 2: Simulate a user entering a password and pressing a specific button
    // btn_type: 1 for Enter (KEY[1]), 2 for Change (KEY[2])
    task enter_password(input [7:0] pass, input [1:0] btn_type);
        begin
            SW[7:0] = pass; // Flip the physical switches to set the password
            
            if (btn_type == 1) begin
                KEY[1] = 1'b0; // Press the 'Enter' button
                #40;           // Hold it down for 40ns (longer than 1 clock cycle to guarantee the debouncer catches it)
                KEY[1] = 1'b1; // Release the button
            end else if (btn_type == 2) begin
                KEY[2] = 1'b0; // Press the 'Change Password' button
                #40;           
                KEY[2] = 1'b1; 
            end
            
            #200; // Wait 200ns for the SRAM operations and FSM processing to complete
        end
    endtask

    // Task 3: Wait for the display timer (e.g., the 2-second "ERR" or "CHG" display) to finish naturally
    task wait_for_display_timer;
        begin
            // Since we parameterized TIMER_CYCLES to 20, the FSM will only wait 20 cycles (400ns).
            // We wait 600ns here to ensure the timer has fully expired and the FSM has transitioned back to IDLE.
            #600; 
        end
    endtask

    // Task 4: Self-checking result verifier. Automatically checks if the LEDs match our expectations.
    task check_result(input exp_ledg, input exp_ledr, input [7:0] test_id);
        begin
            if (LEDG[0] == exp_ledg && LEDR[0] == exp_ledr) begin
                // If the outputs match expectations, print a Success message
                $display("Pass: Test %0d (LEDG=%b, LEDR=%b)", test_id, LEDG[0], LEDR[0]);
            end else begin
                // If they don't match, print a Failure message with details and stop the simulation
                $display("Fail: Test %0d - Expected LEDG=%b LEDR=%b, Got LEDG=%b LEDR=%b", 
                         test_id, exp_ledg, exp_ledr, LEDG[0], LEDR[0]);
                $stop; 
            end
        end
    endtask

    // --- Main Test Sequence (Execution Block) ---
    initial begin
        // Generate a waveform file (VCD) for viewing in tools like GTKWave
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_digital_safe_lock);

        // Set initial, safe values for all inputs before resetting
        SW = 18'h00000;
        KEY = 4'b1111; // All buttons unpressed (Active Low)
        
        $display("========================================");
        $display("   DIGITAL SAFE LOCK - TESTBENCH START  ");
        $display("========================================");
        
        // --- Boot Sequence ---
        reset_system();
        
        // --- Test 1: Unlock with the default password ---
        $display("\n[Test 1] Unlock with default password (00)");
        enter_password(8'h00, 1);
        check_result(1'b1, 1'b0, 1); // We expect Green LED ON, Red LED OFF
        
        // --- Test 2: Change the password ---
        $display("\n[Test 2] Change password to A5");
        enter_password(8'hA5, 2);    // Enter 'A5' and press the 'Change' button
        wait_for_display_timer();    // Wait for the "CHG" message to finish displaying
        $display("Password changed to A5.");
        
        // Relock the safe before proceeding
        $display("\nLocking the safe...");
        enter_password(8'hA5, 1);    // Pressing 'Enter' while unlocked will lock it
        
        // --- Test 3: Attempt to unlock with an incorrect password ---
        $display("\n[Test 3] Try unlocking with WRONG password (11)");
        enter_password(8'h11, 1);
        check_result(1'b0, 1'b1, 3); // We expect Green LED OFF, Red LED ON (Error)
        wait_for_display_timer();    // Wait for the 2-second "ERR" display to finish
        
        // --- Test 4: Attempt to unlock with the NEW correct password ---
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

        // Simulation is finished
        #500;
        $display("========================================");
        $display("          SIMULATION COMPLETE           ");
        $display("========================================");
        $finish;
    end

endmodule
