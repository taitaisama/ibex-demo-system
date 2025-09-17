`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/17/2025 06:56:50 PM
// Design Name: 
// Module Name: data_ram_to_axi_bridge
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module data_ram_to_axi_bridge
# (
   parameter READ_BURST_BITS = 2,
   parameter NUM_ID_BITS = 4
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
  input [NUM_ID_BITS-1:0]  M_AXI_rid,

  output		   M_AXI_awvalid,
  input			   M_AXI_awready,
  output [31:0]		   M_AXI_awaddr,
  output [2:0]		   M_AXI_awsize,
  output [1:0]		   M_AXI_awburst,
  output [NUM_ID_BITS-1:0] M_AXI_awid,
  output [7:0]		   M_AXI_awlen,

  output		   M_AXI_wvalid,
  input			   M_AXI_wready,
  output		   M_AXI_wlast,
  output [31:0]		   M_AXI_wdata,
  output [3:0]		   M_AXI_wstrb,
  output [NUM_ID_BITS-1:0] M_AXI_wid,

  input			   M_AXI_bvalid,
  output		   M_AXI_bready,
  input [1:0]		   M_AXI_bresp,
  input [NUM_ID_BITS-1:0]  M_AXI_bid
);

data_ram_to_axi 
# ( .READ_BURST_BITS (READ_BURST_BITS),
    .NUM_ID_BITS (NUM_ID_BITS)
    ) u_bridge
 (
  .clk (clk),
  .rstn (rstn),
  .s_req (S_RAM_req),
  .s_we (S_RAM_we),
  .s_be (S_RAM_be),
  .s_addr (S_RAM_addr),
  .s_wdata (S_RAM_wrdata),
  .s_rvalid (S_RAM_rdvalid),
  .s_rdata (S_RAM_rddata),
  .s_gnt (S_RAM_gnt),
  .m_arvalid  (M_AXI_arvalid),
  .m_arready  (M_AXI_arready),
  .m_araddr  (M_AXI_araddr),
  .m_arsize  (M_AXI_arsize),
  .m_arburst  (M_AXI_arburst),
  .m_arid  (M_AXI_arid),
  .m_arlen  (M_AXI_arlen),
  .m_rvalid  (M_AXI_rvalid),
  .m_rready  (M_AXI_rready),
  .m_rlast  (M_AXI_rlast),
  .m_rdata  (M_AXI_rdata),
  .m_rresp  (M_AXI_rresp),
  .m_rid  (M_AXI_rid),
  .m_awvalid  (M_AXI_awvalid),
  .m_awready  (M_AXI_awready),
  .m_awaddr  (M_AXI_awaddr),
  .m_awsize  (M_AXI_awsize),
  .m_awburst  (M_AXI_awburst),
  .m_awid  (M_AXI_awid),
  .m_awlen  (M_AXI_awlen),
  .m_wvalid  (M_AXI_wvalid),
  .m_wready  (M_AXI_wready),
  .m_wlast  (M_AXI_wlast),
  .m_wdata  (M_AXI_wdata),
  .m_wstrb  (M_AXI_wstrb),
  .m_wid  (M_AXI_wid),
  .m_bvalid  (M_AXI_bvalid),
  .m_bready  (M_AXI_bready),
  .m_bresp  (M_AXI_bresp),
  .m_bid  (M_AXI_bid)
  );

endmodule
