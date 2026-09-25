// ============================================================
// Date: 09/25/2026
// By:  Isaias M Ramirez
// contents: Clock divider that outputs 50% duty-cycle clocks 
//           for even and odd inputs of n. Uses a negitive 
//           edge reset on logic 0
// ============================================================
// 

module clk_divN #(
  parameter int N = 4
) (
  input  logic clk,
  input  logic rst_n,
  output logic clk_divN
);
localparam WIDTH = $clog2(N);
logic [WIDTH:0] e_cnt; 
logic e_clk, o_clk;

//even clock logic
always@(posedge clk or negedge rst_n)begin
  if(!rst_n)begin
    e_cnt <= '0;
    e_clk <= 0;
  end else begin
    e_cnt <= (e_cnt == N-1) ? '0 : e_cnt+1;
    e_clk <= (e_cnt < N/2)  ? 1  : 0;
  end
end

//odd clock logic (delay even clock by 1/2 clock cycle)
always@(negedge clk or negedge rst_n)begin
  if(!rst_n)begin
    o_clk<=0;
  end else begin
    o_clk <= e_clk;
  end
end

//output logic
always@(posedge clk or negedge rst_n)begin
  if(!rst_n)begin
    clk_divN<=0;
  end else begin
    if(N%2==0)begin
      clk_divN <= e_clk;
    end else begin
      clk_divN <= o_clk | e_clk;
    end
  end
end

endmodule