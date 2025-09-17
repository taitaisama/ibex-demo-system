// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// This is the top level SystemVerilog file that connects the IO on the board to the Ibex Demo System.

module ibex_rvfi_wrapper #(
   parameter int RVFI_OUT_WIDTH = 256,
   parameter int RVFI_CSR_OUT_WIDTH = 128,
   parameter int RVFI_FIFO_WIDTH = 208,
   parameter int RVFI_CSR_FIFO_WIDTH = 104
)
(
    input logic				    sys_clk,
    input logic				    sys_rstn,

    output logic			    led,
  
    input logic [31:0]			    rvfi_start_addr,
    input logic [31:0]			    rvfi_csr_start_addr,
    output logic [31:0]			    rvfi_end_addr,
    output logic [31:0]			    rvfi_csr_end_addr,

    output logic			    ibex_ram_a_req,
    output logic [3:0]			    ibex_ram_a_we,
    output logic [3:0]			    ibex_ram_a_be,
    output logic [31:0]			    ibex_ram_a_addr,
    output logic [31:0]			    ibex_ram_a_wdata,
    input logic				    ibex_ram_a_rvalid,
    input logic [31:0]			    ibex_ram_a_rdata,
    input logic				    ibex_ram_a_gnt,

    output logic			    ibex_ram_b_req,
    output logic [3:0]			    ibex_ram_b_we,
    output logic [3:0]			    ibex_ram_b_be,
    output logic [31:0]			    ibex_ram_b_addr,
    output logic [31:0]			    ibex_ram_b_wdata,
    input logic				    ibex_ram_b_rvalid,
    input logic [31:0]			    ibex_ram_b_rdata,
    input logic				    ibex_ram_b_gnt,

    output logic [RVFI_OUT_WIDTH-1:0]	    rvfi_tdata,
    output logic			    rvfi_tvalid,
    input logic				    rvfi_tready,
    output logic [RVFI_OUT_WIDTH/8-1:0]	    rvfi_tkeep,
   
    output logic [RVFI_CSR_OUT_WIDTH-1:0]   rvfi_csr_tdata,
    output logic			    rvfi_csr_tvalid,
    input logic				    rvfi_csr_tready,
    output logic [RVFI_CSR_OUT_WIDTH/8-1:0] rvfi_csr_tkeep,

    output logic [71:0]			    rvfi_cmd_tdata,
    output logic			    rvfi_cmd_tvalid,
    input logic				    rvfi_cmd_tready,
   
    output logic [71:0]			    rvfi_csr_cmd_tdata,
    output logic			    rvfi_csr_cmd_tvalid,
    input logic				    rvfi_csr_cmd_tready,

    input logic [7:0]			    rvfi_sts_tdata,
    input logic				    rvfi_sts_tvalid,
    output logic			    rvfi_sts_tready,
   
    input logic [7:0]			    rvfi_csr_sts_tdata,
    input logic				    rvfi_csr_sts_tvalid,
    output logic			    rvfi_csr_sts_tready,

    input logic				    flush
);

   logic        rvfi_valid;
   logic        rvfi_trap;
   logic [ 4:0] rvfi_rd_addr;
   logic [31:0] rvfi_rd_wdata;
   logic [31:0] rvfi_pc_rdata;
   logic [31:0] rvfi_ext_pre_mip;
   logic [31:0] rvfi_ext_post_mip;
   logic        rvfi_ext_nmi;
   logic        rvfi_ext_nmi_int;
   logic        rvfi_ext_debug_req;
   logic        rvfi_ext_rf_wr_suppress;
   logic [63:0] rvfi_ext_mcycle;
   logic [31:0] rvfi_ext_mhpmcounters [10];   
   logic [31:0] rvfi_ext_mhpmcountersh [10];
   logic        rvfi_ext_ic_scr_key_valid;

   logic	rvfi_handler_ready;
   logic	force_stop;

   always_comb begin
      rvfi_tdata[RVFI_OUT_WIDTH-RVFI_FIFO_WIDTH-1:0] = '0;
      rvfi_csr_tdata[RVFI_CSR_OUT_WIDTH-RVFI_CSR_FIFO_WIDTH-1:0] = '0;
      // rvfi_tkeep = {{(RVFI_FIFO_WIDTH/8){1'b1}}, {((RVFI_OUT_WIDTH-RVFI_FIFO_WIDTH)/8){1'b0}}};
      // rvfi_csr_tkeep = {{(RVFI_CSR_FIFO_WIDTH/8){1'b1}}, {((RVFI_CSR_OUT_WIDTH-RVFI_CSR_FIFO_WIDTH)/8){1'b0}}};
      rvfi_tkeep = {(RVFI_OUT_WIDTH/8){1'b1}};
      rvfi_csr_tkeep = {(RVFI_CSR_OUT_WIDTH/8){1'b1}};
   end 

   always_comb force_stop = ~rvfi_handler_ready;

   rvfi_handler u_rh 
     (
      .clk (sys_clk),
      .rstn (sys_rstn),

      .rvfi_start_addr,
      .rvfi_csr_start_addr,
      .rvfi_end_addr,
      .rvfi_csr_end_addr,

      .rvfi_valid_i (rvfi_valid && sys_rstn),
      .rvfi_trap_i (rvfi_trap),
      .rvfi_rd_addr_i (rvfi_rd_addr),
      .rvfi_rd_wdata_i (rvfi_rd_wdata),
      .rvfi_pc_rdata_i (rvfi_pc_rdata),
      .rvfi_ext_pre_mip_i (rvfi_ext_pre_mip),
      .rvfi_ext_post_mip_i (rvfi_ext_post_mip),
      .rvfi_ext_nmi_i (rvfi_ext_nmi),
      .rvfi_ext_nmi_int_i (rvfi_ext_nmi_int),
      .rvfi_ext_debug_req_i (rvfi_ext_debug_req),
      .rvfi_ext_rf_wr_suppress_i (rvfi_ext_rf_wr_suppress),
      .rvfi_ext_mcycle_i (rvfi_ext_mcycle),
      .rvfi_ext_mhpmcounters_i (rvfi_ext_mhpmcounters),
      .rvfi_ext_mhpmcountersh_i (rvfi_ext_mhpmcountersh),
      .rvfi_ext_ic_scr_key_valid_i (rvfi_ext_ic_scr_key_valid),

      .fifo_data_o (),
      .fifo_valid_o (rvfi_tdata[RVFI_OUT_WIDTH-1 -: RVFI_FIFO_WIDTH]),
      .fifo_ready_i (rvfi_tready),

      .cmd_data_o (rvfi_cmd_tdata),
      .cmd_valid_o (rvfi_cmd_tvalid),
      .cmd_ready_i (rvfi_cmd_tready),

      .fifo_data_csr_o (rvfi_csr_tdata[RVFI_CSR_OUT_WIDTH-1 -: RVFI_CSR_FIFO_WIDTH]),
      .fifo_valid_csr_o (rvfi_csr_tvalid),
      .fifo_ready_csr_i (rvfi_csr_tready),
      
      .cmd_csr_data_o (rvfi_csr_cmd_tdata),
      .cmd_csr_valid_o (rvfi_csr_cmd_tvalid),
      .cmd_csr_ready_i (rvfi_csr_cmd_tready),

      .flush (flush),
      .rvfi_ready_o (rvfi_handler_ready)
      );
   

   // Instantiating the Ibex Demo System.
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
    .ibex_ram_a_addr_o (ibex_ram_a_addr),
    .ibex_ram_a_wdata_o (ibex_ram_a_wdata),
    .ibex_ram_a_rvalid_i (ibex_ram_a_rvalid),
    .ibex_ram_a_rdata_i (ibex_ram_a_rdata),
    .ibex_ram_a_gnt_i (ibex_ram_a_gnt),
                              
    .ibex_ram_b_req_o (ibex_ram_b_req),
    .ibex_ram_b_we_o (ibex_ram_b_we),
    .ibex_ram_b_be_o (ibex_ram_b_be),
    .ibex_ram_b_addr_o (ibex_ram_b_addr),
    .ibex_ram_b_wdata_o (ibex_ram_b_wdata),
    .ibex_ram_b_rvalid_i (ibex_ram_b_rvalid),
    .ibex_ram_b_rdata_i (ibex_ram_b_rdata),
    .ibex_ram_b_gnt_i (ibex_ram_b_gnt),

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

    .force_stop,

    .trst_ni(1'b1),
    .tms_i  (1'b0),
    .tck_i  (1'b0),
    .td_i   (1'b0),
    .td_o   ()
  );

endmodule
