/*
 * SystemVerilog Module: tb_d_ip_m_pcrm_ctrl
 * Implements the testbench for d_ip_m_pcrm_ctrl
 */

module tb_d_ip_m_pcrm_ctrl();
    logic vdd_aon;
    logic vdd;
    logic vss;
    logic vdd_po_rst_b;
    logic sync_rst_b;
    logic clk_ack;
    logic clk;
    wire vdd_iso_en_b;
    wire clk_gate_en_b;
    wire func_rst_b;
    logic pwr_gting_ack;
    logic clk_gting_ack;
    logic en_clk;
    
    initial begin
        vss = 1'b0;

        #10
        vdd_aon = 1'b1;
        vdd_po_rst_b = 1'b0;
        sync_rst_b = 1'b0;
        clk_ack = 1'b0;

        #50
        vdd = 1'b1;
        en_clk = 1;
        #10
        vdd_po_rst_b = 1'b1;
        clk = 1'b0;

        pwr_gting_ack = 0;
        //clk_gting_ack = 0;

        #20
        sync_rst_b = 1'b1;

        #40
        clk_ack = 1'b1;

        #100
        clk_ack = 1'b0;

        //#40
        //clk_gting_ack = 1;

        #100
        vdd_po_rst_b = 1'b0;
        #5
        pwr_gting_ack = 1;
        #30
        vdd = 0;

        #1000
        $finish;
    end

    /* Clk */
    always @(clk) begin
        if(en_clk) begin
            #20 clk <= ~clk;
        end
    end

    /* Clock gating ack generation */
    always@(clk_gate_en_b) begin
        if(~clk_gate_en_b) begin
            #10 clk_gting_ack <= 1;
        end else begin
            clk_gting_ack <= 0;
        end
    end

    /* DUT Instance */
    d_ip_m_pcrm_ctrl DUT(
        /*
        .vdd_aon(vdd_aon),
        .vdd(vdd),
        .vss(vss),
        */
        .vdd_po_rst_b(vdd_po_rst_b),
        .sync_rst_b(sync_rst_b),
        .clk_ack(clk_ack),
        .clk(clk),
        .vdd_iso_en_b(vdd_iso_en_b),
        .clk_gate_en_b(clk_gate_en_b),
        .func_rst_b(func_rst_b),
        .pwr_gting_ack(pwr_gting_ack),
        .clk_gting_ack(clk_gting_ack)
    );
endmodule