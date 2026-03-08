module mux(
    output logic c,
    input logic a,
    input logic b,
    input logic s
);
    assign c = s ? b : a;
endmodule