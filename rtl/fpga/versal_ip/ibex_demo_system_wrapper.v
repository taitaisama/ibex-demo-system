

module ibex_demo_system_wrapper
  (
   input          sys_clk,
   input          sys_rstn,

   output         led,

   input [31:0]   ibex_ram_base_addr,

   output         ibex_ram_a_req,
   output [3:0]   ibex_ram_a_we,
   output [3:0]   ibex_ram_a_be,
   output [31:0]  ibex_ram_a_addr,
   output [31:0]  ibex_ram_a_wr_data,
   input          ibex_ram_a_rd_valid,
   input [31:0]   ibex_ram_a_rd_data,
   input          ibex_ram_a_gnt,

   output         ibex_ram_b_req,
   output [3:0]   ibex_ram_b_we,
   output [3:0]   ibex_ram_b_be,
   output [31:0]  ibex_ram_b_addr,
   output [31:0]  ibex_ram_b_wr_data,
   input          ibex_ram_b_rd_valid,
   input [31:0]   ibex_ram_b_rd_data,
   input          ibex_ram_b_gnt,

   output         rvfi_valid,
   output         rvfi_trap,
   output [ 4:0]  rvfi_rd_addr,
   output [31:0]  rvfi_rd_wdata,
   output [31:0]  rvfi_pc_rdata,
   output [31:0]  rvfi_ext_pre_mip,
   output [31:0]  rvfi_ext_post_mip,
   output         rvfi_ext_nmi,
   output         rvfi_ext_nmi_int,
   output         rvfi_ext_debug_req,
   output         rvfi_ext_rf_wr_suppress,
   output [63:0]  rvfi_ext_mcycle,
   output [319:0] rvfi_ext_mhpmcounters,
   output [319:0] rvfi_ext_mhpmcountersh,
   output         rvfi_ext_ic_scr_key_valid,

   output         dside_access_valid,
   output         dside_access_dwe,
   output [31:0]  dside_access_daddr,
   output [3:0]   dside_access_dbe,
   output [31:0]  dside_access_dwdata,
   output         dside_access_err,
   output         dside_access_misaligned_first,
   output         dside_access_misaligned_second,
   output         dside_access_misaligned_first_saw_error,
   output         dside_access_m_mode_access,

   input          force_stop
);

   wire [31:0] ibex_ram_a_addr_abs, ibex_ram_b_addr_abs;
   
   assign ibex_ram_a_addr = ibex_ram_a_addr_abs + ibex_ram_base_addr - 32'h00100000;
   assign ibex_ram_b_addr = ibex_ram_b_addr_abs + ibex_ram_base_addr - 32'h00100000;

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
    .ibex_ram_a_wdata_o (ibex_ram_a_wr_data),
    .ibex_ram_a_rvalid_i (ibex_ram_a_rd_valid),
    .ibex_ram_a_rdata_i (ibex_ram_a_rd_data),
    .ibex_ram_a_gnt_i (ibex_ram_a_gnt),
                              
    .ibex_ram_b_req_o (ibex_ram_b_req),
    .ibex_ram_b_we_o (ibex_ram_b_we),
    .ibex_ram_b_be_o (ibex_ram_b_be),
    .ibex_ram_b_addr_o (ibex_ram_b_addr_abs),
    .ibex_ram_b_wdata_o (ibex_ram_b_wr_data),
    .ibex_ram_b_rvalid_i (ibex_ram_b_rd_valid),
    .ibex_ram_b_rdata_i (ibex_ram_b_rd_data),
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

    .dside_access_valid (dside_access_valid),
    .dside_access_store (dside_access_dwe),
    .dside_access_addr (dside_access_daddr),
    .dside_access_be (dside_access_dbe),
    .dside_access_store_data (dside_access_dwdata),
    .dside_access_err (dside_access_err),
    .dside_access_misaligned_first (dside_access_misaligned_first),
    .dside_access_misaligned_second (dside_access_misaligned_second),
    .dside_access_misaligned_first_saw_error (dside_access_misaligned_first_saw_error),
    .dside_access_m_mode_access (dside_access_m_mode_access),

    .force_stop (rvfi_force_stop),

    .trst_ni(1'b1),
    .tms_i  (1'b0),
    .tck_i  (1'b0),
    .td_i   (1'b0),
    .td_o   ()
  );

endmodule
