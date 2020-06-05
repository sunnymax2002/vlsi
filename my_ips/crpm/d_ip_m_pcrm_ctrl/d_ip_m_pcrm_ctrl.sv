/*
 * SystemVerilog Module: d_ip_m_pcrm_ctrl
 * Implements the Power, Clock, Reset and Mode Transition Controller for IPs
 * This is added alongwith functional logic of the IP to realize a sub-system that can be integrated in SoC
 */

module d_ip_m_pcrm_ctrl(
   inout vdd_aon,                   /* Always ON power supply for controller and state retention,
                                       assumed to be always powered-up before vdd, and powered-down after vdd */
   inout vdd,                       // Gated power supply for the module
   inout vss,                       // Ground
   /* All of the inputs and outputs of this module are associated to vdd_aon power domain */
   input logic vdd_po_rst_b,        // Synchronous to clk; Power on reset for vdd. Used to generate isolation control in MS_PWR_GTD mode
   input logic sync_rst_b,          /* Sync reset input, released after vdd and clk are stable,
                                       asserted before either of vdd or clk becomes unstable or off */
   input logic clk_ack,             /* Synchronous to clk; When asserted, it indicates that clk is active and stable; must never assert while sync_rst_b = 0
                                       if released, FSM moves to MS_CLK_GTING state and this is indication that clk will 'soon' be gated */
   input logic clk,                 // Module's functional clock
   output logic vdd_iso_en_b,       // Directs functional module to enable isolation. If released, module must remove isolation
   output logic clk_gate_en_b,      // Directs functional module to enable clock gating. If released, module must ungate clocks
   output logic func_rst_b,         // Module reset
   input logic pwr_gting_ack,       // Module provides an ACK that power gating has been applied (isolations enabled). Tie to vdd_iso_en_b if module can't provide this ACK
   input logic clk_gting_ack        // Module provides an ACK that clock gating has been applied. Tie to clk_gate_en_b if module can't provide this ACK
);

   /* Input Assertions (TODO: code the assertions)
    *    On posedge & negdge of vdd_po_rst_b, vdd_aon, vdd and clk must be stable
    *    On posedge & negdge of sync_rst_b, vdd_aon, vdd and clk must be stable
    *    On posedge & negdge of clk_ack, vdd_aon, vdd and clk must be stable, and vdd_po_rst_b = sync_rst_b = 1
    *    On negedge of sync_rst_b, clk_ack must be 0
    *    On negedge of vdd_po_rst_b, clk_ack = sync_rst_b = 0
    */
   assert property (@(negedge sync_rst_b) (clk_ack == 0));
   assert property (@(negedge vdd_po_rst_b) (clk_ack == 0 && sync_rst_b == 0));
   assert property (@(negedge clk_ack) (vdd_po_rst_b == 1 && sync_rst_b == 1));

   /* FSM states & variables */
   localparam FSM_REG_WIDTH = 3;
   /* State Transition Behaviour and Assumptions
    *    Initial state: MS_RST
    *    When vdd is stable, vdd_po_rst_b is released. This signal is asserted before vdd becomes unstable (and this assertion triggers entry into MS_PWR_GTD mode)
    *    When vdd_aon, vdd and clk are stable, sync_rst_b is released
    *    When clk is stable, clk_ack asserts synchronously, and this triggers transition into MS_RUN mode
    */
   typedef enum logic [FSM_REG_WIDTH - 1 : 0] { MS_RST,           // Power & Clock not stable, module under reset
                                                MS_RUN,           // Module is in active RUN mode
                                                MS_CLK_GTING,     // Transition from MS_RUN to MS_CLK_GTD state
                                                MS_CLK_GTD,       // Module is clock gated
                                                MS_CLK_UNGTING,   // Transition from MS_CLK_GTD to MS_RUN state
                                                MS_PWR_GTING,     // Transition to MS_PWR_GTD state
                                                MS_PWR_GTD,       // Module is power gated (vdd is powered off, but vdd_aon is powered)
                                                MS_PWR_UNGTING    // Transition from MS_PWR_GTD to MS_CLK_GTD state
   } FsmState;

   FsmState curr_state;
   FsmState next_state;

   /* Below internal registers indicate completion of clock and power gating / ungating transitions */
   /*
   wire clk_gting_cmpl;
   assign clk_gting_cmpl = clk_gting_ack;
   wire pwr_gting_cmpl;
   assign pwr_gting_cmpl = pwr_gting_ack;

   logic clk_ungting_cmpl;
   logic pwr_ungting_cmpl; */

   /* Combinational Operation */
   always_comb begin
      case(curr_state)
         MS_RST:
            if(clk_ack)          next_state = MS_RUN;
            else                 next_state = MS_RST;
         MS_RUN:
            if(~clk_ack)         next_state = MS_CLK_GTING;
            else                 next_state = MS_RUN;
         MS_CLK_GTING:
            if(clk_gting_ack)    next_state = MS_CLK_GTD;
            else                 next_state = MS_CLK_GTING;
         MS_CLK_UNGTING:
            if(~clk_gting_ack) next_state = MS_RUN;
            else                 next_state = MS_CLK_UNGTING;
         MS_CLK_GTD:
            if(~vdd_po_rst_b)    next_state = MS_PWR_GTING;
            else begin
               if(clk_ack)       next_state = MS_CLK_UNGTING;
               else              next_state = MS_CLK_GTD;
            end
         MS_PWR_GTING:
            if(pwr_gting_ack)   next_state = MS_PWR_GTD;
            else                 next_state = MS_PWR_GTING;
         MS_PWR_GTD:
            if(vdd_po_rst_b)     next_state = MS_PWR_UNGTING;
            else                 next_state = MS_PWR_GTD;
         MS_PWR_UNGTING:
            if(~pwr_gting_ack) next_state = MS_CLK_GTD;
            else                 next_state = MS_PWR_UNGTING;
         default:                next_state = MS_RST;
      endcase
   end

   /* Synchronous Operation */
   always_ff @(posedge clk) begin
      if(~sync_rst_b) begin
         curr_state <= MS_RST;
      end else begin
         curr_state <= next_state;
      end
   end

   /* Output assignment */
   assign vdd_iso_en_b = ~((curr_state == MS_PWR_GTING) || (curr_state == MS_PWR_GTD) || (curr_state == MS_RST));
   assign clk_gate_en_b = ~((curr_state == MS_CLK_GTING) || (curr_state == MS_CLK_GTD) || (curr_state == MS_RST));
   assign func_rst_b = ~(curr_state == MS_RST);

endmodule