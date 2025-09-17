// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// This is the top level SystemVerilog file that connects the IO on the board to the Ibex Demo System.

module top_versal
(
  // These inputs are defined in data/pins_artya7.xdc
    input	  sys_clk_p,
    input	  sys_clk_n,
    
    output [0:0]  DDR4_act_n,
    output [16:0] DDR4_adr,
    output [1:0]  DDR4_ba,
    output [0:0]  DDR4_bg,
    output [0:0]  DDR4_ck_c,
    output [0:0]  DDR4_ck_t,
    output [0:0]  DDR4_cke,
    output [0:0]  DDR4_cs_n,
    inout [7:0]	  DDR4_dm_n,
    inout [63:0]  DDR4_dq,
    inout [7:0]	  DDR4_dqs_c,
    inout [7:0]	  DDR4_dqs_t,
    output [0:0]  DDR4_odt,
    output [0:0]  DDR4_reset_n,
  
    output	  mdio_mdc,
    inout	  mdio_mdio_io,
    output [0:0]  phy_reset_n,
    input [3:0]	  rgmii_rd,
    input	  rgmii_rx_ctl,
    input	  rgmii_rxc,
    output [3:0]  rgmii_td,
    output	  rgmii_tx_ctl,
    output	  rgmii_txc,

    output reg	  led
);

   logic	  sys_clk;
   logic	  sys_rstn;

   logic [31:0]	  ibex_ram_base_addr;

   logic	  ibex_ram_a_req;
   logic [3:0]	  ibex_ram_a_we;
   logic [3:0]	  ibex_ram_a_be;
   logic [31:0]	  ibex_ram_a_addr;
   logic [31:0]	  ibex_ram_a_wdata;
   logic	  ibex_ram_a_rvalid;
   logic [31:0]	  ibex_ram_a_rdata;
   logic	  ibex_ram_a_gnt;

   logic	  ibex_ram_b_req;
   logic [3:0]	  ibex_ram_b_we;
   logic [3:0]	  ibex_ram_b_be;
   logic [31:0]	  ibex_ram_b_addr;
   logic [31:0]	  ibex_ram_b_wdata;
   logic	  ibex_ram_b_rvalid;
   logic [31:0]	  ibex_ram_b_rdata;
   logic	  ibex_ram_b_gnt;

   logic	  rvfi_valid;
   logic	  rvfi_trap;
   logic [ 4:0]	  rvfi_rd_addr;
   logic [31:0]	  rvfi_rd_wdata;
   logic [31:0]	  rvfi_pc_rdata;
   logic [31:0]	  rvfi_ext_pre_mip;
   logic [31:0]	  rvfi_ext_post_mip;
   logic	  rvfi_ext_nmi;
   logic	  rvfi_ext_nmi_int;
   logic	  rvfi_ext_debug_req;
   logic	  rvfi_ext_rf_wr_suppress;
   logic [63:0]	  rvfi_ext_mcycle;
   logic [319:0]  rvfi_ext_mhpmcounters;
   logic [319:0]  rvfi_ext_mhpmcountersh;
   logic	  rvfi_ext_ic_scr_key_valid;
   
   logic	  force_stop;

   logic [31:0]	  ibex_ram_a_addr_abs, ibex_ram_b_addr_abs;

   always_comb begin
      ibex_ram_a_addr = ibex_ram_a_addr_abs + ibex_ram_base_addr - 32'h00100000;
      ibex_ram_b_addr = ibex_ram_b_addr_abs + ibex_ram_base_addr - 32'h00100000;
   end

  ibex_demo_system #(
    .GpiWidth     ( 0            ),
    .GpoWidth     ( 1            ),
    .PwmWidth     ( 0            )
  ) u_ibex_demo_system (
    //input
    .clk_sys_i (sys_clk),
    .rst_sys_ni(sys_rstn),
    .gp_i      (),
    .uart_rx_i (1'b0),

    //output
    .gp_o     (led),
    .pwm_o    (),
    .uart_tx_o(),

    .spi_rx_i (1'b0),
    .spi_tx_o (),
    .spi_sck_o(),

    .ibex_ram_a_req_o (ibex_ram_a_req),
    .ibex_ram_a_we_o (ibex_ram_a_we),
    .ibex_ram_a_be_o (ibex_ram_a_be),
    .ibex_ram_a_addr_o (ibex_ram_a_addr_abs),
    .ibex_ram_a_wdata_o (ibex_ram_a_wdata),
    .ibex_ram_a_rvalid_i (ibex_ram_a_rvalid),
    .ibex_ram_a_rdata_i (ibex_ram_a_rdata),
    .ibex_ram_a_gnt_i (ibex_ram_a_gnt),
                              
    .ibex_ram_b_req_o (ibex_ram_b_req),
    .ibex_ram_b_we_o (ibex_ram_b_we),
    .ibex_ram_b_be_o (ibex_ram_b_be),
    .ibex_ram_b_addr_o (ibex_ram_b_addr_abs),
    .ibex_ram_b_wdata_o (ibex_ram_b_wdata),
    .ibex_ram_b_rvalid_i (ibex_ram_b_rvalid),
    .ibex_ram_b_rdata_i (ibex_ram_b_rdata),
    .ibex_ram_b_gnt_i (ibex_ram_b_gnt),

    .rvfi_valid (rvfi_valid),
    .rvfi_trap (rvfi_trap),
    .rvfi_rd_addr (rvfi_rd_addr),
    .rvfi_rd_wdata (rvfi_rd_wdata),
    .rvfi_pc_rdata (rvfi_pc_rdata),
    .rvfi_ext_pre_mip (rvfi_ext_pre_mip),
    .rvfi_ext_post_mip (rvfi_ext_post_mip),
    .rvfi_ext_nmi (rvfi_ext_nmi),
    .rvfi_ext_nmi_int (rvfi_ext_nmi_int),
    .rvfi_ext_debug_req (rvfi_ext_debug_req),
    .rvfi_ext_rf_wr_suppress (rvfi_ext_rf_wr_suppress),
    .rvfi_ext_mcycle (rvfi_ext_mcycle),
    .rvfi_ext_mhpmcounters (rvfi_ext_mhpmcounters),
    .rvfi_ext_mhpmcountersh (rvfi_ext_mhpmcountersh),
    .rvfi_ext_ic_scr_key_valid (rvfi_ext_ic_scr_key_valid),

    .force_stop (force_stop),

    .trst_ni(1'b1),
    .tms_i  (1'b0),
    .tck_i  (1'b0),
    .td_i   (1'b0),
    .td_o   ()
  );

   ps_subsystem_wrapper u_pssub
   (
      
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

    .PROG_ADDR_tri_o (ibex_ram_base_addr),
    .force_stop,

    .ibex_ram_a_req,
    .ibex_ram_a_we,
    .ibex_ram_a_be,
    .ibex_ram_a_addr,
    .ibex_ram_a_wrdata (ibex_ram_a_wdata),
    .ibex_ram_a_rdvalid (ibex_ram_a_rvalid),
    .ibex_ram_a_rddata (ibex_ram_a_rdata),
    .ibex_ram_a_gnt,

    .ibex_ram_b_req,
    .ibex_ram_b_we,
    .ibex_ram_b_be,
    .ibex_ram_b_addr,
    .ibex_ram_b_wrdata (ibex_ram_b_wdata),
    .ibex_ram_b_rdvalid (ibex_ram_b_rvalid),
    .ibex_ram_b_rddata (ibex_ram_b_rdata),
    .ibex_ram_b_gnt,

    .rvfi_valid,
    .rvfi_trap,
    .rvfi_rd_addr,
    .rvfi_rd_wdata,
    .rvfi_pc_rdata,
    .rvfi_ext_pre_mip,
    .rvfi_ext_post_mip,
    .rvfi_ext_nmi,
    .rvfi_ext_nmi_int,
    .rvfi_ext_debug_req,
    .rvfi_ext_rf_wr_suppress,
    .rvfi_ext_mcycle,
    .rvfi_ext_mhpmcounters,
    .rvfi_ext_mhpmcountersh,
    .rvfi_ext_ic_scr_key_valid,

    .mdio_mdc,
    .mdio_mdio_io,
    .phy_reset_n,
    .rgmii_rd,
    .rgmii_rx_ctl,
    .rgmii_rxc,
    .rgmii_td,
    .rgmii_tx_ctl,
    .rgmii_txc,

    .sys_clk (sys_clk),
    .sys_rstn (sys_rstn),
    .sys_clk_n (sys_clk_n),
    .sys_clk_p (sys_clk_p)
   );

endmodule
