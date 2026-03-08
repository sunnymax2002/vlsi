module mux_tb();
    // Declare signals in the testbench as logic (or reg/wire where appropriate)
    logic a, b, s;
    logic c;

    // Instantiate the DUT
    mux m1(
        .c(c), 
        .a(a), 
        .b(b), 
        .s(s)
    );

    // Generate stimulus within an initial block
    initial begin
        // Initialize all inputs
        a = 1'b0;
        b = 1'b0;
        s = 1'b0;
        
        // Apply different input combinations with delays
        #5 a = 1'b1; b = 1'b0; s = 1'b0; // Test case 1: s=0, c should be a (1)
        #5 a = 1'b0; b = 1'b1; s = 1'b1; // Test case 2: s=1, c should be b (1)
        #5 a = 1'b1; b = 1'b1; s = 1'b0; // Test case 3: s=0, c should be a (1)
        #5 a = 1'b0; b = 1'b0; s = 1'b1; // Test case 4: s=1, c should be b (0)

        // Add a check for results (simple self-checking)
        #1; // Allow time for the logic to propagate
        if (c !== 1'b0) $display("Test Case 4 FAILED: Expected c=0, got c=%b", c);
        else $display("Test Case 4 PASSED");

        #5 $display("Simulation finished at time %0t", $time);
        $finish; // Terminate the simulation
    end
    
    // Optional: initial block to dump waveforms for viewing
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, mux_tb);
    end

endmodule