// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// This is the top level SystemVerilog file that connects the IO on the board to the Ibex Demo System.
module top_versal #(
  parameter SRAMInitFile = "/home/ritu/dev/work/ibex-demo-system/sw/c/build/demo/hello_world/demo.hex"
) (
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
   logic sys_rstn;

   logic        ibex_ram_a_req;
   logic [3:0]  ibex_ram_a_we;
   logic [3:0]  ibex_ram_a_be;
   logic [31:0] ibex_ram_a_addr;
   logic [31:0] ibex_ram_a_wdata;
   logic        ibex_ram_a_rvalid;
   logic [31:0] ibex_ram_a_rdata;

   logic        ibex_ram_b_req;
   logic [3:0]  ibex_ram_b_we;
   logic [3:0]  ibex_ram_b_be;
   logic [31:0] ibex_ram_b_bddr;
   logic [31:0] ibex_ram_b_wdata;
   logic        ibex_ram_b_rvalid;
   logic [31:0] ibex_ram_b_rdata;
   
   logic        ps_bram_a_clk;
   logic        ps_bram_a_rst;
   logic [3:0]  ps_bram_a_we;
   logic        ps_bram_a_en;
   logic [31:0] ps_bram_a_addr;
   logic [31:0] ps_bram_a_wdata;
   logic [31:0] ps_bram_a_rdata;

   logic        ram_a_req;
   logic [3:0]  ram_a_we;
   logic [3:0]  ram_a_be;
   logic [31:0] ram_a_addr;
   logic [31:0] ram_a_wdata;
   logic        ram_a_rvalid;
   logic [31:0] ram_a_rdata;

   logic        ps_ctrl;

   always_comb begin
      ram_a_req = ps_ctrl ? ps_bram_a_en : ibex_ram_a_req;
      ram_a_we = ps_ctrl ? ps_bram_a_we : ibex_ram_a_we;
      ram_a_be = ps_ctrl ? 4'b1111 : ibex_ram_a_be;
      ram_a_addr = ps_ctrl ? ps_bram_a_addr : ibex_ram_a_addr;
      ram_a_wdata = ps_ctrl ? ps_bram_a_wdata : ibex_ram_a_wdata;
      ibex_ram_a_rvalid = (~ps_ctrl) && ram_a_rvalid;
      ibex_ram_a_rdata = ram_a_rdata;
      ps_bram_a_rdata = ram_a_rdata;
   end   

   localparam logic [31:0] MEM_SIZE      = 128 * 1024; // 128 KiB   

  ram_2p #(
    .Depth       ( MEM_SIZE / 4 ),
    .MemInitFile ( SRAMInitFile )
  ) u_ram (
   .clk_i (sys_clk),
   .rst_ni(sys_rstn),

   .a_req_i   (ram_a_req),
   .a_we_i    (ram_a_we),
   .a_be_i    (ram_a_be),
   .a_addr_i  (ram_a_addr),
   .a_wdata_i (ram_a_wdata),
   .a_rvalid_o(ram_a_rvalid),
   .a_rdata_o (ram_a_rdata),

   .b_req_i   (ibex_ram_b_req),
   .b_we_i    (ibex_ram_b_we),
   .b_be_i    (ibex_ram_b_be),
   .b_addr_i  (ibex_ram_b_addr),
   .b_wdata_i (ibex_ram_b_wdata),
   .b_rvalid_o(ibex_ram_b_rvalid),
   .b_rdata_o (ibex_ram_b_rdata)
   );


  // Instantiating the Ibex Demo System.
  ibex_demo_system #(
    .GpiWidth     ( 0            ),
    .GpoWidth     ( 1            ),
    .PwmWidth     ( 0            ),
    .SRAMInitFile ( SRAMInitFile )
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
    .ibex_ram_a_addr_o (ibex_ram_a_addr),
    .ibex_ram_a_wdata_o (ibex_ram_a_wdata),
    .ibex_ram_a_rvalid_i (ibex_ram_a_rvalid),
    .ibex_ram_a_rdata_i (ibex_ram_a_rdata),
                              
    .ibex_ram_b_req_o (ibex_ram_b_req),
    .ibex_ram_b_we_o (ibex_ram_b_we),
    .ibex_ram_b_be_o (ibex_ram_b_be),
    .ibex_ram_b_addr_o (ibex_ram_b_addr),
    .ibex_ram_b_wdata_o (ibex_ram_b_wdata),
    .ibex_ram_b_rvalid_i (ibex_ram_b_rvalid),
    .ibex_ram_b_rdata_i (ibex_ram_b_rdata),

    .trst_ni(1'b1),
    .tms_i  (1'b0),
    .tck_i  (1'b0),
    .td_i   (1'b0),
    .td_o   ()
  );
   
   ps_subsystem_wrapper u_pssub (
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
    .PS_BRAM_addr (ps_bram_a_addr),
    .PS_BRAM_clk (ps_bram_a_clk),
    .PS_BRAM_din (ps_bram_a_wdata),
    .PS_BRAM_dout (ps_bram_a_rdata),
    .PS_BRAM_en (ps_bram_a_en),
    .PS_BRAM_rst (ps_bram_a_rst),
    .PS_BRAM_we (ps_bram_a_we),
    .PS_REQ_tri_o (ps_ctrl),
    .axi_clk (sys_clk),
    .axi_rstn (sys_rstn),
    .sys_clk_n (sys_clk_n),
    .sys_clk_p (sys_clk_p)
   );

endmodule
