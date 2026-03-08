module mkCounter (Empty);
    // Define a 1-bit register initialized to 0
    Reg#(Bit#(1)) cnt <- mkReg(0);

    // Rule: increments the counter every clock cycle
    rule increment;
        cnt <= cnt + 1;
        $display("Counter value: %d", cnt);
    endrule
endmodule