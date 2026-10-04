// ============================================================
// Date: 10/03/2026
// By:  Isaias M Ramirez
// contents: This module is an implementation of an asynchronous FIFO
// the fifo does not assume any clock phase correlation and utilizes a global
// reset for all pointers and memory
// ============================================================
// 
module async_fifo #(
  parameter int unsigned DEPTH = 16,   // must be power of 2 
  parameter int unsigned WIDTH = 8
) (
  // Write domain
  input  logic               write_clk,
  input  logic               write_rst_n,
  input  logic               write_en,
  input  logic [WIDTH-1:0]   write_data,
  output logic               full,

  // Read domain
  input  logic               read_clk,
  input  logic               read_rst_n,
  input  logic               read_en,
  output logic [WIDTH-1:0]   read_data,
  output logic               empty
);

  localparam int unsigned ADDR_W = $clog2(DEPTH);
  // Using ADDR_W+1 pointer bits (extra bit disambiguates full vs empty).
  localparam int unsigned PTR_W  = ADDR_W + 1;

  // Memory, dual-port because read and write operations are in different always blocks
  logic [WIDTH-1:0] mem [0:DEPTH-1];

  // Write pointers
  logic [PTR_W-1:0] wbin;
  logic [PTR_W-1:0] wgray;

  // Read pointers
  logic [PTR_W-1:0] rbin;
  logic [PTR_W-1:0] rgray;

  // Synchronized pointers
  logic [PTR_W-1:0] rgray_sync_w, rbin_sync_w; // read pointer synced into write clock domain
  logic [PTR_W-1:0] wgray_sync_r, wbin_sync_r; // write pointer synced into read clock domain 

  // 2-FF sync stages (no comb logic between stages).
  logic [PTR_W-1:0] rgray_w_q1, rgray_w_q2;
  logic [PTR_W-1:0] wgray_r_q1, wgray_r_q2;

  //global reset
  logic rst_n; 
  assign rst_n = (write_rst_n & read_rst_n); //reset on either reset .
  //********FIFO Write Domain**********
  always_ff @(posedge write_clk, negedge rst_n)begin
    if(!rst_n)begin //reset pointers on empty
      wbin <= '0;
    end else begin
      if(write_en & !full)begin
        wbin <= wbin + 1;
      end 
    end
  end
  // wgray is immediately equivalent to wbin 
  assign wgray = bin2gray(wbin);
  //rgray synchronyzer circuit
  always_ff @(posedge write_clk, negedge rst_n)begin
    if(!rst_n) begin
      rgray_w_q1 <= '0;
      rgray_w_q2 <= '0;
    end else begin
      rgray_w_q1 <= rgray;
      rgray_w_q2 <= rgray_w_q1;
    end
  end
  assign rgray_sync_w = rgray_w_q2; // assign to synchronized value. 
  //convert gray to bin
  assign rbin_sync_w = gray2bin(rgray_sync_w); 
  //this is necessary to disambiguate the full from empty because full + 1 would wrap around to all zeros
  assign full = (rbin_sync_w == {~wbin[PTR_W-1],wbin[PTR_W-2:0]}) ? 1 : 0;
  //example ( 0000 == ~(1)000 ) -> 1 with 3 ptr bits 
  //could technically make this comparison in gray code, but wanted to convert from gray to bin

  //write logic
  always_ff @(posedge write_clk, rst_n)begin
    if(!rst_n)begin
      mem <= '{default: '0};
    end else begin
      if(write_en & !full ) mem[wbin[ADDR_W-1:0]] <= write_data;
    end
  end

  //********FIFO Read Domain**********
    always_ff @(posedge read_clk, negedge rst_n)begin
    if(!rst_n)begin
      rbin <= '0;
    end else begin
      if(read_en & !empty)begin
        rbin <= rbin + 1;
      end 
    end
  end
  //wgray is immediately equivalent to wbin 
  assign rgray = bin2gray(rbin);
  //wgray synchronyzer circuit, this could be a module, but keeping this simple. 
  always_ff @(posedge read_clk, negedge rst_n)begin
    if(!rst_n) begin
      wgray_r_q1 <= '0;
      wgray_r_q2 <= '0;
    end else begin
      wgray_r_q1 <= wgray;
      wgray_r_q2 <= wgray_r_q1;
    end
  end
  assign wgray_sync_r = wgray_r_q2; // assign to synchronized value. 
  //convert gray to bin
  assign wbin_sync_r = gray2bin(wgray_sync_r); 
  //because we used the workaround for full, we can keep empty simple.
  assign empty = wbin_sync_r == rbin;

  //need to synchronize reads with the read clock.
  //if the fifo is empty, the pointer doesn't change
  always_ff @(posedge read_clk, rst_n)begin
    if(!rst_n)begin
      read_data <= 0;
    end else begin
      if(read_en & !empty) read_data <= mem[rbin[ADDR_W-1:0]];
    end
  end
  
  // ----------------------------
  // Utility functions
  // ----------------------------
  function automatic logic [PTR_W-1:0] bin2gray(input logic [PTR_W-1:0] bin);
  bin2gray = (bin >> 1) ^ bin;
  endfunction

  function automatic logic [PTR_W-1:0] gray2bin(input logic [PTR_W-1:0] gray);
    logic [PTR_W-1:0] bin;
    bin[PTR_W-1] = gray[PTR_W-1];
    for (int i = PTR_W-2; i >= 0; i--)
        bin[i] = bin[i+1] ^ gray[i];
    return bin;
  endfunction

endmodule