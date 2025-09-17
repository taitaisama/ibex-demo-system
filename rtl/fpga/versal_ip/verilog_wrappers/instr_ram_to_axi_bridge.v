module instr_ram_to_axi_bridge
# (
   parameter NUM_ID_BITS = 4,
   parameter READ_BURST_BITS = 2
   )
(
  input			   clk,
  input			   rstn,
   
  input			   S_RAM_req,
  input			   S_RAM_we,
  input [3:0]		   S_RAM_be,
  input [31:0]		   S_RAM_addr,
  input [31:0]		   S_RAM_wrdata,
  output		   S_RAM_rdvalid,
  output [31:0]		   S_RAM_rddata,
  output		   S_RAM_gnt,

  output		   M_AXI_arvalid,
  input			   M_AXI_arready,
  output [31:0]		   M_AXI_araddr,
  output [2:0]		   M_AXI_arsize,
  output [1:0]		   M_AXI_arburst,
  output [NUM_ID_BITS-1:0] M_AXI_arid,
  output [7:0]		   M_AXI_arlen,

  input			   M_AXI_rvalid,
  output		   M_AXI_rready,
  input			   M_AXI_rlast,
  input [31:0]		   M_AXI_rdata,
  input [1:0]		   M_AXI_rresp,
  input [NUM_ID_BITS-1:0]  M_AXI_rid
);

instr_ram_to_axi
# (
   .NUM_ID_BITS (NUM_ID_BITS),
   .READ_BURST_BITS (READ_BURST_BITS)
   ) u_ir2a
  (
   .clk (clk),
   .rstn (rstn),
   
   .s_req (S_RAM_req),
   .s_addr (S_RAM_addr),
   .s_rvalid (S_RAM_rvalid),
   .s_rdata (S_RAM_rdata),
   .s_gnt (S_RAM_gnt),

   .m_arvalid (M_AXI_arvalid),
   .m_arready (M_AXI_arready),
   .m_araddr (M_AXI_araddr),
   .m_arsize (M_AXI_arsize),
   .m_arburst (M_AXI_arburst),
   .m_arid (M_AXI_arid),
   .m_arlen (M_AXI_arlen),

   .m_rvalid (M_AXI_rvalid),
   .m_rready (M_AXI_rready),
   .m_rlast (M_AXI_rlast),
   .m_rdata (M_AXI_rdata),
   .m_rresp (M_AXI_rresp),
   .m_rid (M_AXI_rid)
   );

endmodule
