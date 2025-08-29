module rvfi_handler #(
  parameter int	OUT_WIDTH = 256,
  parameter int	CSR_WIDTH = 256) 
( 
  input logic			 clk,
  input logic			 rstn,
  input logic			 rvfi_valid_i,
  input logic			 rvfi_trap_i,
  input logic [ 4:0]		 rvfi_rd_addr_i,
  input logic [31:0]		 rvfi_rd_wdata_i,
  input logic [31:0]		 rvfi_pc_rdata_i,
  input logic [31:0]		 rvfi_ext_pre_mip_i,
  input logic [31:0]		 rvfi_ext_post_mip_i,
  input logic			 rvfi_ext_nmi_i,
  input logic			 rvfi_ext_nmi_int_i,
  input logic			 rvfi_ext_debug_req_i,
  input logic			 rvfi_ext_rf_wr_suppress_i,
  input logic [63:0]		 rvfi_ext_mcycle_i,
  input logic [31:0]		 rvfi_ext_mhpmcounters_i [10], 
  input logic [31:0]		 rvfi_ext_mhpmcountersh_i [10],
  input logic			 rvfi_ext_ic_scr_key_valid_i,

  output logic [OUT_WIDTH-1:0]	 rdata_o,
  output logic			 rvalid_o,
  input logic			 rready_i,
  output logic [OUT_WIDTH/8-1:0] rkeep_o,

  output logic [CSR_WIDTH-1:0]	 rdata_csr_o,
  output logic			 rvalid_csr_o,
  input logic			 rready_csr_i,
  output logic [CSR_WIDTH/8-1:0] rkeep_csr_o,

  output logic			 rvfi_ready_o
);

   typedef struct packed {
      logic [63:0] rvfi_ext_mcycle;
      logic	   rvfi_trap;
      logic [ 4:0] rvfi_rd_addr;
      logic [31:0] rvfi_rd_wdata;
      logic [31:0] rvfi_pc_rdata;
      logic [31:0] rvfi_ext_pre_mip;
      logic [31:0] rvfi_ext_post_mip;
      logic	   rvfi_ext_nmi;
      logic	   rvfi_ext_nmi_int;
      logic	   rvfi_ext_debug_req;
      logic	   rvfi_ext_rf_wr_suppress;
      logic	   rvfi_ext_ic_scr_key_valid;
      logic [319:0] rvfi_ext_mhpmcounters;   
      logic [319:0] rvfi_ext_mhpmcountersh;
   } rvfi_data_t;

   rvfi_data_t fifo_input_rvfi;
   rvfi_data_t fifo_output_rvfi;

   always_comb begin
      fifo_input_rvfi.rvfi_trap = rvfi_trap_i;
      fifo_input_rvfi.rvfi_rd_addr = rvfi_rd_addr_i;
      fifo_input_rvfi.rvfi_rd_wdata = rvfi_rd_wdata_i;
      fifo_input_rvfi.rvfi_pc_rdata = rvfi_pc_rdata_i;
      fifo_input_rvfi.rvfi_ext_pre_mip = rvfi_ext_pre_mip_i;
      fifo_input_rvfi.rvfi_ext_post_mip = rvfi_ext_post_mip_i;
      fifo_input_rvfi.rvfi_ext_nmi = rvfi_ext_nmi_i;
      fifo_input_rvfi.rvfi_ext_nmi_int = rvfi_ext_nmi_int_i;
      fifo_input_rvfi.rvfi_ext_debug_req = rvfi_ext_debug_req_i;
      fifo_input_rvfi.rvfi_ext_rf_wr_suppress = rvfi_ext_rf_wr_suppress_i;
      fifo_input_rvfi.rvfi_ext_mcycle = rvfi_ext_mcycle_i;
      for (int i = 0; i < 10; i ++) begin
	 fifo_input_rvfi.rvfi_ext_mhpmcounters[i*32 +: 32] = rvfi_ext_mhpmcounters_i[i];
	 fifo_input_rvfi.rvfi_ext_mhpmcountersh[i*32 +: 32] = rvfi_ext_mhpmcountersh_i[i];
      end
      fifo_input_rvfi.rvfi_ext_ic_scr_key_valid = rvfi_ext_ic_scr_key_valid_i;
   end

   logic	rvfi_fifo_empty;
   logic	rvfi_fifo_almost_full;

   logic	rvfi_to_mem_ready;
   logic	rvfi_to_mem_valid;

   always_comb rvfi_to_mem_valid = !rvfi_fifo_empty && rvfi_to_mem_ready;

   rvfi_fifo_wrapper u_rvfi_fifo
     (
      .clk (clk),
      .rst (~rstn),
      .fifo_read_almost_empty (),
      .fifo_read_empty (rvfi_fifo_empty),
      .fifo_read_rd_data (fifo_output_rvfi),
      .fifo_read_rd_en (rvfi_to_mem_valid),
      .fifo_write_almost_full (rvfi_fifo_almost_full),
      .fifo_write_full (),
      .fifo_write_wr_data (fifo_input_rvfi),
      .fifo_write_wr_en (rvfi_valid_i)
      );

   always_comb rvfi_ready_o = ~rvfi_fifo_almost_full;

   logic [63:0]  rvfi_out_mcycle;
   logic [143:0] rvfi_out_data;
   logic [31:0]	 rvfi_out_csr [20];

   always_comb begin
      rvfi_out_mcycle = fifo_output_rvfi.rvfi_ext_mcycle;
      rvfi_out_data = {fifo_output_rvfi.rvfi_trap, fifo_output_rvfi.rvfi_rd_addr, fifo_output_rvfi.rvfi_rd_wdata, fifo_output_rvfi.rvfi_pc_rdata, fifo_output_rvfi.rvfi_ext_pre_mip, fifo_output_rvfi.rvfi_ext_post_mip, fifo_output_rvfi.rvfi_ext_nmi, fifo_output_rvfi.rvfi_ext_nmi_int, fifo_output_rvfi.rvfi_ext_debug_req, fifo_output_rvfi.rvfi_ext_rf_wr_suppress, fifo_output_rvfi.rvfi_ext_ic_scr_key_valid};
      for (int i = 0; i < 10; i ++) begin
	 rvfi_out_csr[i] = fifo_output_rvfi.rvfi_ext_mhpmcounters[i*32 +: 32];
	 rvfi_out_csr[10+i] = fifo_output_rvfi.rvfi_ext_mhpmcountersh[i*32 +: 32];
      end
   end
   

   rvfi_to_mem u_rtm
     (
      .clk (clk),
      .rstn (rstn),
      .valid_i (rvfi_to_mem_valid),
      .rvfi_mcycle (rvfi_out_mcycle),
      .rvfi (rvfi_out_data),
      .rvfi_csr (rvfi_out_csr),
      .wready_o (rvfi_to_mem_ready),

      .rdata_o,
      .rvalid_o,
      .rready_i,

      .rdata_csr_o,
      .rvalid_csr_o,
      .rready_csr_i
      
      );
   
endmodule
