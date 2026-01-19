
module rvfi_to_stream
 #(
   parameter RVFI_WIDTH = 256,
   parameter CSR_WIDTH = 64,
   parameter DSIDE_WIDTH = 128,
   parameter LOG2_BUFFER_SIZE = 20)
( 
  input                         clk,
  input                         rstn,

  input [31:0]                  rvfi_ctrl_baseaddr,
  input [LOG2_BUFFER_SIZE-1:0]  rvfi_ctrl_swidx,
  output [LOG2_BUFFER_SIZE-1:0] rvfi_ctrl_hwidx,

  input [31:0]                  csr_ctrl_baseaddr,
  input [LOG2_BUFFER_SIZE-1:0]  csr_ctrl_swidx,
  output [LOG2_BUFFER_SIZE-1:0] csr_ctrl_hwidx,

  input [31:0]                  dside_ctrl_baseaddr,
  input [LOG2_BUFFER_SIZE-1:0]  dside_ctrl_swidx,
  output [LOG2_BUFFER_SIZE-1:0] dside_ctrl_hwidx,

  input                         rvfi_in_valid,
  input                         rvfi_in_trap,
  input [ 4:0]                  rvfi_in_rd_addr,
  input [31:0]                  rvfi_in_rd_wdata,
  input [31:0]                  rvfi_in_pc_rdata,
  input [31:0]                  rvfi_in_ext_pre_mip,
  input [31:0]                  rvfi_in_ext_post_mip,
  input                         rvfi_in_ext_nmi,
  input                         rvfi_in_ext_nmi_int,
  input                         rvfi_in_ext_debug_req,
  input                         rvfi_in_ext_rf_wr_suppress,
  input [63:0]                  rvfi_in_ext_mcycle,
  input [319:0]                 rvfi_in_ext_mhpmcounters, 
  input [319:0]                 rvfi_in_ext_mhpmcountersh,
  input                         rvfi_in_ext_ic_scr_key_valid,

  input                         dside_access_valid,
  input                         dside_access_dwe,
  input [31:0]                  dside_access_daddr,
  input [3:0]                   dside_access_dbe,
  input [31:0]                  dside_access_dwdata,
  input                         dside_access_err,
  input                         dside_access_misaligned_first,
  input                         dside_access_misaligned_second,
  input                         dside_access_misaligned_first_saw_error,
  input                         dside_access_m_mode_access,

  output [RVFI_WIDTH-1:0]       rvfi_axis_fifo_tdata,
  output                        rvfi_axis_fifo_tvalid,
  input                         rvfi_axis_fifo_tready,
  output [RVFI_WIDTH/8-1:0]     rvfi_axis_fifo_tkeep,
  
  output [71:0]                 rvfi_cmd_tdata,
  output                        rvfi_cmd_tvalid,
  input                         rvfi_cmd_tready,

  input [7:0]                   rvfi_sts_tdata,
  input                         rvfi_sts_tvalid,
  output                        rvfi_sts_tready,

  output [CSR_WIDTH-1:0]        csr_axis_fifo_tdata,
  output                        csr_axis_fifo_tvalid,
  input                         csr_axis_fifo_tready,
  output [CSR_WIDTH/8-1:0]      csr_axis_fifo_tkeep,

  output [71:0]                 csr_cmd_tdata,
  output                        csr_cmd_tvalid,
  input                         csr_cmd_tready,

  input [7:0]                   csr_sts_tdata,
  input                         csr_sts_tvalid,
  output                        csr_sts_tready,

  output [DSIDE_WIDTH-1:0]      dside_axis_fifo_tdata,
  output                        dside_axis_fifo_tvalid,
  input                         dside_axis_fifo_tready,
  output [DSIDE_WIDTH/8-1:0]    dside_axis_fifo_tkeep,

  output [71:0]                 dside_cmd_tdata,
  output                        dside_cmd_tvalid,
  input                         dside_cmd_tready,

  input [7:0]                   dside_sts_tdata,
  input                         dside_sts_tvalid,
  output                        dside_sts_tready,

  input                         flush,
  output                        force_stop
);

   rvfi_handler
 #(
   .RVFI_WIDTH (RVFI_WIDTH),
   .CSR_WIDTH (CSR_WIDTH),
   .DSIDE_WIDTH (DSIDE_WIDTH))
   u_rh
     (
      .clk (clk),
      .rstn (rstn),

      .rvfi_base_addr (rvfi_ctrl_baseaddr),
      .rvfi_sw_idx (rvfi_ctrl_swidx),
      .rvfi_hw_idx (rvfi_ctrl_hwidx),

      .csr_base_addr (csr_ctrl_baseaddr),
      .csr_sw_idx (csr_ctrl_swidx),
      .csr_hw_idx (csr_ctrl_hwidx),

      .dside_base_addr (dside_ctrl_baseaddr),
      .dside_sw_idx (dside_ctrl_swidx),
      .dside_hw_idx (dside_ctrl_hwidx),
      
      .rvfi_valid_i (rvfi_in_valid),
      .rvfi_trap_i (rvfi_in_trap),
      .rvfi_rd_addr_i (rvfi_in_rd_addr),
      .rvfi_rd_wdata_i (rvfi_in_rd_wdata),
      .rvfi_pc_rdata_i (rvfi_in_pc_rdata),
      .rvfi_ext_pre_mip_i (rvfi_in_ext_pre_mip),
      .rvfi_ext_post_mip_i (rvfi_in_ext_post_mip),
      .rvfi_ext_nmi_i (rvfi_in_ext_nmi),
      .rvfi_ext_nmi_int_i (rvfi_in_ext_nmi_int),
      .rvfi_ext_debug_req_i (rvfi_in_ext_debug_req),
      .rvfi_ext_rf_wr_suppress_i (rvfi_in_ext_rf_wr_suppress),
      .rvfi_ext_mcycle_i (rvfi_in_ext_mcycle),
      .rvfi_ext_mhpmcounters_i (rvfi_in_ext_mhpmcounters), 
      .rvfi_ext_mhpmcountersh_i (rvfi_in_ext_mhpmcountersh),
      .rvfi_ext_ic_scr_key_valid_i (rvfi_in_ext_ic_scr_key_valid),

      .dside_access_valid_i (dside_access_valid),
      .dside_access_store_i (dside_access_dwe),
      .dside_access_addr_i (dside_access_daddr),
      .dside_access_be_i (dside_access_dbe),
      .dside_access_store_data_i (dside_access_dwdata),
      .dside_access_err_i (dside_access_err),
      .dside_access_misaligned_first_i (dside_access_misaligned_first),
      .dside_access_misaligned_second_i (dside_access_misaligned_second),
      .dside_access_misaligned_first_saw_error_i (dside_access_misaligned_first_saw_error),
      .dside_access_m_mode_access_i (dside_access_m_mode_access),
      
      .busy_o (force_stop),

      .rvfi_axis_fifo_data_o (rvfi_axis_fifo_tdata),
      .rvfi_axis_fifo_valid_o (rvfi_axis_fifo_tvalid),
      .rvfi_axis_fifo_ready_i (rvfi_axis_fifo_tready),
      .rvfi_axis_fifo_keep_o (rvfi_axis_fifo_tkeep),
  
      .rvfi_cmd_data_o (rvfi_cmd_tdata),
      .rvfi_cmd_valid_o (rvfi_cmd_tvalid),
      .rvfi_cmd_ready_i (rvfi_cmd_tready),

      .rvfi_sts_data_o (rvfi_sts_tdata),
      .rvfi_sts_valid_o (rvfi_sts_tvalid),
      .rvfi_sts_ready_i (rvfi_sts_tready),

      .csr_axis_fifo_data_o (csr_axis_fifo_tdata),
      .csr_axis_fifo_valid_o (csr_axis_fifo_tvalid),
      .csr_axis_fifo_ready_i (csr_axis_fifo_tready),
      .csr_axis_fifo_keep_o (csr_axis_fifo_tkeep),

      .csr_cmd_data_o (csr_cmd_tdata),
      .csr_cmd_valid_o (csr_cmd_tvalid),
      .csr_cmd_ready_i (csr_cmd_tready),

      .csr_sts_data_o (csr_sts_tdata),
      .csr_sts_valid_o (csr_sts_tvalid),
      .csr_sts_ready_i (csr_sts_tready),

      .dside_axis_fifo_data_o (dside_axis_fifo_tdata),
      .dside_axis_fifo_valid_o (dside_axis_fifo_tvalid),
      .dside_axis_fifo_ready_i (dside_axis_fifo_tready),
      .dside_axis_fifo_keep_o (dside_axis_fifo_tkeep),

      .dside_cmd_data_o (dside_cmd_tdata),
      .dside_cmd_valid_o (dside_cmd_tvalid),
      .dside_cmd_ready_i (dside_cmd_tready),

      .dside_sts_data_o (dside_sts_tdata),
      .dside_sts_valid_o (dside_sts_tvalid),
      .dside_sts_ready_i (dside_sts_tready),

      
      .flush (flush)

  );
   
endmodule
