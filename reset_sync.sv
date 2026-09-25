// ============================================================
// Date: 09/25/2026
// By:  Isaias M Ramirez
// contents: This module is meant to allow an asynchronous reset
//           while synchronizing the release of the reset with
//           the input clk. 
// ============================================================
// 
module reset_sync (
  input  logic clk,
  input  logic async_rst_n,
  output logic rst_n_sync
);
  logic r1, r2;
  always_ff @( posedge clk or async_rst_n)begin
    if(!async_rst_n)begin
      rst_n_sync <= 0;
      r1 <= 0;
      r2 <= 0;
    end else begin
      r1 <= async_rst_n;
      r2 <= r1;
      rst_n_sync<=r2;
    end
  end