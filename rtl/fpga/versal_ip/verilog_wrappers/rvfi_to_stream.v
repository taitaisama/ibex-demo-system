module rvfi_to_stream
 #(
   parameter OUT_WIDTH = 256,
   parameter CSR_WIDTH = 128)
( 
  input			   clk,
  input			   rstn,

  input			   rvfi_in_valid,
  input			   rvfi_in_trap,
  input [ 4:0]		   rvfi_in_rd_addr,
  input [31:0]		   rvfi_in_rd_wdata,
  input [31:0]		   rvfi_in_pc_rdata,
  input [31:0]		   rvfi_in_ext_pre_mip,
  input [31:0]		   rvfi_in_ext_post_mip,
  input			   rvfi_in_ext_nmi,
  input			   rvfi_in_ext_nmi_int,
  input			   rvfi_in_ext_debug_req,
  input			   rvfi_in_ext_rf_wr_suppress,
  input [63:0]		   rvfi_in_ext_mcycle,
  input [319:0]		   rvfi_in_ext_mhpmcounters, 
  input [319:0]		   rvfi_in_ext_mhpmcountersh,
  input			   rvfi_in_ext_ic_scr_key_valid,
  output		   rvfi_in_force_stop,

  output [OUT_WIDTH-1:0]   rvfi_stream_tdata,
  output		   rvfi_stream_tvalid,
  input			   rvfi_stream_tready,
  output [OUT_WIDTH/8-1:0] rvfi_stream_tkeep,
  
  output [71:0]		   rvfi_cmd_tdata,
  output		   rvfi_cmd_tvalid,
  input			   rvfi_cmd_tready,

  input [7:0]		   rvfi_sts_tdata,
  input			   rvfi_sts_tvalid,
  output		   rvfi_sts_tready,

  output [CSR_WIDTH-1:0]   rvfi_csr_stream_tdata,
  output		   rvfi_csr_stream_tvalid,
  input			   rvfi_csr_stream_tready,
  output [CSR_WIDTH/8-1:0] rvfi_csr_stream_tkeep,

  output [71:0]		   rvfi_csr_cmd_tdata,
  output		   rvfi_csr_cmd_tvalid,
  input			   rvfi_csr_cmd_tready,

  input [7:0]		   rvfi_csr_sts_tdata,
  input			   rvfi_csr_sts_tvalid,
  output		   rvfi_csr_sts_tready,

  input			   flush,

  input [31:0]		   rvfi_ctrl_start_addr,
  input [31:0]		   rvfi_ctrl_end_addr,
  output [31:0]		   rvfi_ctrl_curr_addr,
  output		   rvfi_ctrl_full,
  input			   rvfi_ctrl_rst_addr,
  
  input [31:0]		   rvfi_csr_ctrl_start_addr,
  input [31:0]		   rvfi_csr_ctrl_end_addr,
  output [31:0]		   rvfi_csr_ctrl_curr_addr,
  output		   rvfi_csr_ctrl_full,
  input			   rvfi_csr_ctrl_rst_addr
);


   rvfi_handler
 #(
   .FULL_OUT_WIDTH (OUT_WIDTH),
   .FULL_CSR_WIDTH (CSR_WIDTH))
   u_rh
     (
      .clk (clk),
      .rstn (rstn),
   
      .rvfi_start_addr (rvfi_ctrl_start_addr),
      .rvfi_csr_start_addr (rvfi_csr_ctrl_start_addr),
      .rvfi_end_addr (rvfi_ctrl_end_addr),
      .rvfi_csr_end_addr (rvfi_csr_ctrl_end_addr),
      .rvfi_curr_addr (rvfi_ctrl_curr_addr),
      .rvfi_csr_curr_addr (rvfi_csr_ctrl_curr_addr),
      
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
      .rvfi_busy_o (rvfi_in_force_stop),

      .fifo_data_o (rvfi_stream_tdata),
      .fifo_valid_o (rvfi_stream_tvalid),
      .fifo_ready_i (rvfi_stream_tready),
      .cmd_data_o (rvfi_cmd_tdata),
      .cmd_valid_o (rvfi_cmd_tvalid),
      .cmd_ready_i (rvfi_cmd_tready),
      .sts_data_o (rvfi_sts_tdata),
      .sts_valid_o (rvfi_sts_tvalid),
      .sts_ready_i (rvfi_sts_tready),
      .fifo_data_csr_o (rvfi_csr_stream_tdata),
      .fifo_valid_csr_o (rvfi_csr_stream_tvalid),
      .fifo_ready_csr_i (rvfi_csr_stream_tready),
      .cmd_csr_data_o (rvfi_csr_cmd_tdata),
      .cmd_csr_valid_o (rvfi_csr_cmd_tvalid),
      .cmd_csr_ready_i (rvfi_csr_cmd_tready),
      .sts_csr_data_o (rvfi_csr_sts_tdata),
      .sts_csr_valid_o (rvfi_csr_sts_tvalid),
      .sts_csr_ready_i (rvfi_csr_sts_tready),
      
      .flush (flush),
      .rvfi_full (rvfi_ctrl_full),
      .rvfi_csr_full (rvfi_csr_ctrl_full),
      .rvfi_rst_addr (rvfi_ctrl_rst_addr),
      .rvfi_csr_rst_addr (rvfi_csr_ctrl_rst_addr)

  );
   
endmodule
