// ============================================================
// Date: 10/02/2026
// By:  Isaias M Ramirez
// contents: This module is an implementation of a synchronous FIFO
// ============================================================
// 
module sync_fifo #(
  parameter int unsigned DEPTH = 8,    // TODO: power-of-2 recommended
  parameter int unsigned WIDTH = 8,

  // Thresholds in "entries" (0..DEPTH)
  parameter int unsigned ALMOST_FULL_THRESH  = DEPTH-1,
  parameter int unsigned ALMOST_EMPTY_THRESH = 1
) (
  input  logic               clk,
  input  logic               rst_n,

  input  logic               write_en,
  input  logic [WIDTH-1:0]   write_data,

  input  logic               read_en,
  output logic [WIDTH-1:0]   read_data,

  output logic               full,
  output logic               empty,
  output logic               almost_full,
  output logic               almost_empty
);
  // calculate the number of bits necessary to count to the value DEPTH
  localparam int unsigned ADDR_W = $clog2(DEPTH);

  // Storage
  logic [WIDTH-1:0] mem [0:DEPTH-1];

  // Pointers and occupancy
  logic [ADDR_W-1:0] rd_ptr, wr_ptr; 
  logic [ADDR_W:0]   count; // extra bit to represent DEPTH

    //counter, wr_ptr logic
  always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)begin
      count <= '0;
    end else begin 
      if(!full && write_en && !read_en) begin 
        count <= count +1;//increment if not full, writing and not reading
      end else if( !empty && !write_en && read_en) begin 
        count <= count -1;//decrement if not empty, not writing, and reading 
      end // else leave count un-changed, stores the value of count in memory.
    end
  end
  // the count of items in the fifo is the same as the address to be written 
  // because the most recently written data will be the last to be read in 
  // the currently available data. 
  assign wr_ptr = count[ADDR_W-1:0];

  //of the clock
    always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)begin
      rd_ptr <= '0;
    end else begin 
      if( !empty && !write_en && read_en) begin 
        rd_ptr <= rd_ptr +1;// if read increment ptr
      end
      //if the FIFO is empty, we reset the rd_ptr
      if(empty) rd_ptr <= '0;
    end
  end
  //flag logic
  always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)begin
      full <= 0;
      empty <= 1;
      almost_full <=0;
      almost_empty <=1;
    end else begin
      full <= (count == DEPTH[ADDR_W:0]) ? 1 : 0;
      empty <= (count == '0) ? 1 : 0;
      almost_full <= ( count >= ALMOST_FULL_THRESH[ADDR_W:0]) ? 1 : 0;
      almost_empty <= ( count <= ALMOST_EMPTY_THRESH[ADDR_W:0]) ? 1 : 0;
    end
  end

  //write logic
  always_ff @( posedge clk, negedge rst_n) begin
    if(!rst_n)begin
      mem <= '{default: '0};
    end else begin
      if(write_en && !full) mem[wr_ptr] <= write_data; 
    end
  end
  //read data is always available immediately
  assign read_data = mem[rd_ptr];