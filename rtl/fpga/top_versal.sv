// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// This is the top level SystemVerilog file that connects the IO on the board to the Ibex Demo System.

module top_versal
(
  // These inputs are defined in data/pins_artya7.xdc
    input         sys_clk_p,
    input         sys_clk_n,
    
    output [0:0]  DDR4_act_n,
    output [16:0] DDR4_adr,
    output [1:0]  DDR4_ba,
    output [0:0]  DDR4_bg,
    output [0:0]  DDR4_ck_c,
    output [0:0]  DDR4_ck_t,
    output [0:0]  DDR4_cke,
    output [0:0]  DDR4_cs_n,
    inout [7:0]   DDR4_dm_n,
    inout [63:0]  DDR4_dq,
    inout [7:0]   DDR4_dqs_c,
    inout [7:0]   DDR4_dqs_t,
    output [0:0]  DDR4_odt,
    output [0:0]  DDR4_reset_n,
  
    output reg    led
);

   logic sys_clk;
   logic axi_rstn, sys_rstn, sys_rstn_d, sys_rstn_d_d;

   logic [255:0] rvfi_tdata;
   logic	 rvfi_tvalid;
   logic	 rvfi_tready;
   logic [31:0]	 rvfi_tkeep;
  
   logic [127:0] rvfi_csr_tdata;
   logic	 rvfi_csr_tvalid;
   logic	 rvfi_csr_tready;
   logic [15:0]	 rvfi_csr_tkeep;

   logic [71:0]	 rvfi_cmd_tdata;
   logic	 rvfi_cmd_tvalid;
   logic	 rvfi_cmd_tready;
  
   logic [71:0]	 rvfi_csr_cmd_tdata;
   logic	 rvfi_csr_cmd_tvalid;
   logic	 rvfi_csr_cmd_tready;

   logic	 m_a_arvalid;
   logic	 m_a_arready;
   logic [31:0]	 m_a_araddr;
   logic [2:0]	 m_a_arsize;
   logic [1:0]	 m_a_arburst;
   logic [3:0]	 m_a_arid;
   logic [7:0]	 m_a_arlen;

   logic	 m_a_rvalid;
   logic	 m_a_rready;
   logic	 m_a_rlast;
   logic [31:0]	 m_a_rdata;
   logic [1:0]	 m_a_rresp;
   logic [3:0]	 m_a_rid;

   logic	 m_a_awvalid;
   logic	 m_a_awready;
   logic [31:0]	 m_a_awaddr;
   logic [2:0]	 m_a_awsize;
   logic [1:0]	 m_a_awburst;
   logic [3:0]	 m_a_awid;
   logic [7:0]	 m_a_awlen;

   logic	 m_a_wvalid;
   logic	 m_a_wready;
   logic	 m_a_wlast;
   logic [31:0]	 m_a_wdata;
   logic [3:0]	 m_a_wstrb;
   logic [3:0]	 m_a_wid;

   logic	 m_a_bvalid;
   logic	 m_a_bready;
   logic [1:0]	 m_a_bresp;
   logic [3:0]	 m_a_bid;

   logic	 m_b_arvalid;
   logic	 m_b_arready;
   logic [31:0]	 m_b_araddr;
   logic [2:0]	 m_b_arsize;
   logic [1:0]	 m_b_arburst;
   logic [3:0]	 m_b_arid;
   logic [7:0]	 m_b_arlen;

   logic	 m_b_rvalid;
   logic	 m_b_rready;
   logic	 m_b_rlast;
   logic [31:0]	 m_b_rdata;
   logic [1:0]	 m_b_rresp;
   logic [3:0]	 m_b_rid;


   logic	ps_rstn, ps_stop;

   localparam int DEBUG_WIDTH = 256;
   localparam int DEBUG_DEPTH = 512;
   
   localparam logic [15:0] MAX_DEBUG_ADDR = ((DEBUG_WIDTH*DEBUG_DEPTH)/8);
   
   logic [15:0]		     DEBUG_addr;
   logic		     DEBUG_clk;
   logic [DEBUG_WIDTH-1:0]   DEBUG_din;
   logic [DEBUG_WIDTH-1:0]   DEBUG_dout;
   logic		     DEBUG_en;
   logic		     DEBUG_rst;
   logic [DEBUG_WIDTH/8-1:0] DEBUG_we;
   logic [7:0]		     DEBUG_counter;
   
   logic [31:0]      base_addr;

   always_comb sys_rstn = axi_rstn && ps_rstn;

   ibex_axi_wrapper
     (
      .sys_clk (sys_clk),
      .sys_rstn (sys_rstn_d_d),

      .led (led),

      .rvfi_tdata (rvfi_tdata),
      .rvfi_tvalid (rvfi_tvalid),
      .rvfi_tready (rvfi_tready),
      .rvfi_tkeep (rvfi_tkeep),
      
      .rvfi_csr_tdata (rvfi_csr_tdata),
      .rvfi_csr_tvalid (rvfi_csr_tvalid),
      .rvfi_csr_tready (rvfi_csr_tready),
      .rvfi_csr_tkeep (rvfi_csr_tkeep),

      .rvfi_cmd_tdata (rvfi_cmd_tdata),
      .rvfi_cmd_tvalid (rvfi_cmd_tvalid),
      .rvfi_cmd_tready (rvfi_cmd_tready),
      
      .rvfi_csr_cmd_tdata (rvfi_csr_cmd_tdata),
      .rvfi_csr_cmd_tvalid (rvfi_csr_cmd_tvalid),
      .rvfi_csr_cmd_tready (rvfi_csr_cmd_tready),
      
      .flush (ps_stop),
      .base_addr (base_addr),
      .debug (DEBUG_din),

      .m_a_arvalid (m_a_arvalid),
      .m_a_arready (m_a_arready),
      .m_a_araddr (m_a_araddr),
      .m_a_arsize (m_a_arsize),
      .m_a_arburst (m_a_arburst),
      .m_a_arid (m_a_arid),
      .m_a_arlen (m_a_arlen),
      .m_a_rvalid (m_a_rvalid),
      .m_a_rready (m_a_rready),
      .m_a_rlast (m_a_rlast),
      .m_a_rdata (m_a_rdata),
      .m_a_rresp (m_a_rresp),
      .m_a_rid (m_a_rid),
      .m_a_awvalid (m_a_awvalid),
      .m_a_awready (m_a_awready),
      .m_a_awaddr (m_a_awaddr),
      .m_a_awsize (m_a_awsize),
      .m_a_awburst (m_a_awburst),
      .m_a_awid (m_a_awid),
      .m_a_awlen (m_a_awlen),
      .m_a_wvalid (m_a_wvalid),
      .m_a_wready (m_a_wready),
      .m_a_wlast (m_a_wlast),
      .m_a_wdata (m_a_wdata),
      .m_a_wstrb (m_a_wstrb),
      .m_a_wid (m_a_wid),
      .m_a_bvalid (m_a_bvalid),
      .m_a_bready (m_a_bready),
      .m_a_bresp (m_a_bresp),
      .m_a_bid (m_a_bid),

      .m_b_arvalid (m_b_arvalid),
      .m_b_arready (m_b_arready),
      .m_b_araddr (m_b_araddr),
      .m_b_arsize (m_b_arsize),
      .m_b_arburst (m_b_arburst),
      .m_b_arid (m_b_arid),
      .m_b_arlen (m_b_arlen),
      .m_b_rvalid (m_b_rvalid),
      .m_b_rready (m_b_rready),
      .m_b_rlast (m_b_rlast),
      .m_b_rdata (m_b_rdata),
      .m_b_rresp (m_b_rresp),
      .m_b_rid (m_b_rid)

      );


   always_ff @(posedge sys_clk or negedge sys_rstn) begin
      if (!sys_rstn) begin
	 DEBUG_addr = 0;
	 sys_rstn_d <= 0;
	 sys_rstn_d_d <= 0;
      end else begin
	 sys_rstn_d <= sys_rstn;
	 sys_rstn_d_d <= sys_rstn_d && sys_rstn;
	 DEBUG_counter <= DEBUG_counter + 1;
	 if (DEBUG_addr < MAX_DEBUG_ADDR) begin
	    DEBUG_addr += (DEBUG_WIDTH/8);
	 end
      end
   end

   always_comb begin
      DEBUG_clk = sys_clk;
      DEBUG_rst = ~sys_rstn;
      DEBUG_we = 32'hffffffff;
      DEBUG_en = 1;
   end

   // ps_subsystem_debug_wrapper u_pssub 
   ps_subsystem_wrapper u_pssub
   (
   
    // .clk (sys_clk),
    // .rstn (sys_rstn),
      
    .DDR4_act_n         (DDR4_act_n    ),
    .DDR4_adr           (DDR4_adr      ),
    .DDR4_ba            (DDR4_ba       ),
    .DDR4_bg            (DDR4_bg       ),
    .DDR4_ck_c          (DDR4_ck_c     ),
    .DDR4_ck_t          (DDR4_ck_t     ),
    .DDR4_cke           (DDR4_cke      ),
    .DDR4_cs_n          (DDR4_cs_n     ),
    .DDR4_dm_n          (DDR4_dm_n     ),
    .DDR4_dq            (DDR4_dq       ),
    .DDR4_dqs_c         (DDR4_dqs_c    ),
    .DDR4_dqs_t         (DDR4_dqs_t    ),
    .DDR4_odt           (DDR4_odt      ),
    .DDR4_reset_n       (DDR4_reset_n  ),

    .PS_IO_tri_o ({ps_rstn, ps_stop}),
    .BASE_ADDR_tri_o (base_addr),

    .rvfi_tdata,
    .rvfi_tvalid,
    .rvfi_tready,
    .rvfi_tkeep,

    .rvfi_cmd_tdata,
    .rvfi_cmd_tvalid,
    .rvfi_cmd_tready,
   
    .rvfi_csr_tdata,
    .rvfi_csr_tvalid,
    .rvfi_csr_tready,
    .rvfi_csr_tkeep,
    
    .rvfi_csr_cmd_tdata,
    .rvfi_csr_cmd_tvalid,
    .rvfi_csr_cmd_tready,

    .IBEX_DATA_arvalid (m_a_arvalid),
    .IBEX_DATA_arready (m_a_arready),
    .IBEX_DATA_araddr ({32'd0, m_a_araddr}),
    .IBEX_DATA_arsize (m_a_arsize),
    .IBEX_DATA_arburst (m_a_arburst),
    .IBEX_DATA_arid (m_a_arid),
    .IBEX_DATA_arlen (m_a_arlen),
    .IBEX_DATA_arcache (3),

    .IBEX_DATA_rvalid (m_a_rvalid),
    .IBEX_DATA_rready (m_a_rready),
    .IBEX_DATA_rlast (m_a_rlast),
    .IBEX_DATA_rdata (m_a_rdata),
    .IBEX_DATA_rresp (m_a_rresp),
    .IBEX_DATA_rid (m_a_rid),
    .IBEX_DATA_awvalid (m_a_awvalid),
    .IBEX_DATA_awready (m_a_awready),
    .IBEX_DATA_awaddr ({32'd0, m_a_awaddr}),
    .IBEX_DATA_awsize (m_a_awsize),
    .IBEX_DATA_awburst (m_a_awburst),
    .IBEX_DATA_awid (m_a_awid),
    .IBEX_DATA_awlen (m_a_awlen),
    .IBEX_DATA_awcache (3),
    
    .IBEX_DATA_wvalid (m_a_wvalid),
    .IBEX_DATA_wready (m_a_wready),
    .IBEX_DATA_wlast (m_a_wlast),
    .IBEX_DATA_wdata (m_a_wdata),
    .IBEX_DATA_wstrb (m_a_wstrb),
    //.IBEX_DATA_wid (m_a_wid),
    .IBEX_DATA_bvalid (m_a_bvalid),
    .IBEX_DATA_bready (m_a_bready),
    .IBEX_DATA_bresp (m_a_bresp),
    .IBEX_DATA_bid (m_a_bid),

    .IBEX_INSTR_arvalid (m_b_arvalid),
    .IBEX_INSTR_arready (m_b_arready),
    .IBEX_INSTR_araddr ({32'd0, m_b_araddr}),
    .IBEX_INSTR_arsize (m_b_arsize),
    .IBEX_INSTR_arburst (m_b_arburst),
    .IBEX_INSTR_arid (m_b_arid),
    .IBEX_INSTR_arlen (m_b_arlen),
    .IBEX_INSTR_arcache (3),
    
    .IBEX_INSTR_rvalid (m_b_rvalid),
    .IBEX_INSTR_rready (m_b_rready),
    .IBEX_INSTR_rlast (m_b_rlast),
    .IBEX_INSTR_rdata (m_b_rdata),
    .IBEX_INSTR_rresp (m_b_rresp),
    .IBEX_INSTR_rid (m_b_rid),

    .DEBUG_addr,
    .DEBUG_clk,
    .DEBUG_din,
    .DEBUG_dout,
    .DEBUG_en,
    .DEBUG_rst,
    .DEBUG_we,

    .axi_clk (sys_clk),
    .axi_rstn (axi_rstn),
    .sys_clk_n (sys_clk_n),
    .sys_clk_p (sys_clk_p)
   );

endmodule
