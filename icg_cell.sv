// ============================================================
// Date: 09/25/2026
// By:  Isaias M Ramirez
// contents: Integrated Clock Gating Cell that enables/disables
//           a clk input based on an input enable. 
//           The cell disables the clock only on a negative edge
//           edge of the input clock. 
// ============================================================
// 
module icg_cell (
  input  logic clk_in,
  input  logic enable,
  output logic clk_gated
);
//latch the enable on the falling edge of input clk
//to avoid glitching on the output
logic en_latched;
always_latch @(negedge clk_in)begin
  en_latched <= enable;
end
//Output logic - and the enable and clk_in
assign clk_gated = en_latched & clk_in;

endmodule