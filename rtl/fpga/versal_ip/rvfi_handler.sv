`default_nettype none

module rvfi_handler #(
   parameter		  FULL_OUT_WIDTH = 256,
   parameter		  FULL_CSR_WIDTH = 64,
   parameter int	  OUT_WIDTH = 232,
   parameter int	  CSR_WIDTH = 64,
   parameter logic [31:0] BUFFER_SIZE = 32'h100000,
   parameter int	  NUM_BUFFERS = 4)
( 
  input logic				 clk,
  input logic				 rstn,

  input logic [31:0]			 rvfi_base_addr,
  input logic [$clog2(NUM_BUFFERS)-1:0]	 rvfi_sw_idx,
  output logic [$clog2(NUM_BUFFERS)-1:0] rvfi_hw_idx,

  input logic [31:0]			 rvfi_csr_base_addr,
  input logic [$clog2(NUM_BUFFERS)-1:0]	 rvfi_csr_sw_idx,
  output logic [$clog2(NUM_BUFFERS)-1:0] rvfi_csr_hw_idx,

  input logic				 rvfi_valid_i,
  input logic				 rvfi_trap_i,
  input logic [ 4:0]			 rvfi_rd_addr_i,
  input logic [31:0]			 rvfi_rd_wdata_i,
  input logic [31:0]			 rvfi_pc_rdata_i,
  input logic [31:0]			 rvfi_ext_pre_mip_i,
  input logic [31:0]			 rvfi_ext_post_mip_i,
  input logic				 rvfi_ext_nmi_i,
  input logic				 rvfi_ext_nmi_int_i,
  input logic				 rvfi_ext_debug_req_i,
  input logic				 rvfi_ext_rf_wr_suppress_i,
  input logic [63:0]			 rvfi_ext_mcycle_i,
  input logic [319:0]			 rvfi_ext_mhpmcounters_i, 
  input logic [319:0]			 rvfi_ext_mhpmcountersh_i,
  input logic				 rvfi_ext_ic_scr_key_valid_i,

  output logic [FULL_OUT_WIDTH-1:0]	 fifo_data_o,
  output logic				 fifo_valid_o,
  input logic				 fifo_ready_i,
  output logic [FULL_OUT_WIDTH/8-1:0]	 fifo_keep_o,
  
  output logic [71:0]			 cmd_data_o,
  output logic				 cmd_valid_o,
  input logic				 cmd_ready_i,

  input logic [7:0]			 sts_data_o,
  input logic				 sts_valid_o,
  output logic				 sts_ready_i,

  output logic [FULL_CSR_WIDTH-1:0]	 fifo_data_csr_o,
  output logic				 fifo_valid_csr_o,
  input logic				 fifo_ready_csr_i,
  output logic [FULL_CSR_WIDTH/8-1:0]	 fifo_keep_csr_o,

  output logic [71:0]			 cmd_csr_data_o,
  output logic				 cmd_csr_valid_o,
  input logic				 cmd_csr_ready_i,

  input logic [7:0]			 sts_csr_data_o,
  input logic				 sts_csr_valid_o,
  output logic				 sts_csr_ready_i,

  input logic				 flush,

  output logic				 rvfi_busy_o
);

   typedef struct packed {
      logic [23:0] counter;
      logic [63:0] rvfi_ext_mcycle;
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
      logic        rvfi_ext_ic_scr_key_valid;
      logic [319:0] rvfi_ext_mhpmcounters;   
      logic [319:0] rvfi_ext_mhpmcountersh;
   } rvfi_data_t;

   rvfi_data_t fifo_input_rvfi;
   rvfi_data_t fifo_output_rvfi;

   logic [23:0] rvfi_counter;

   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         rvfi_counter     <= '0;
      end else begin
         if (rvfi_valid_i) begin
            rvfi_counter  <= rvfi_counter + 1;
         end
      end
   end

   always_comb begin
      fifo_input_rvfi.counter = rvfi_counter;
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
      fifo_input_rvfi.rvfi_ext_mhpmcounters = rvfi_ext_mhpmcounters_i;
      fifo_input_rvfi.rvfi_ext_mhpmcountersh = rvfi_ext_mhpmcountersh_i;
      fifo_input_rvfi.rvfi_ext_ic_scr_key_valid = rvfi_ext_ic_scr_key_valid_i;
   end

   logic        rvfi_fifo_data_valid;
   logic        rvfi_fifo_almost_full;
   logic	rvfi_fifo_busy;

   logic        rvfi_to_mem_ready;
   logic        rvfi_to_mem_valid;

   always_comb begin
      rvfi_to_mem_valid = rvfi_fifo_data_valid && rvfi_to_mem_ready;
   end

   fifo_wrapper #(.WIDTH(856), .DEPTH(16))
   u_rvfi_fifo (
      .clk (clk),
      .rst (~rstn),
      .data_valid (rvfi_fifo_data_valid),
      .fifo_wr_busy (rvfi_fifo_busy),
      .fifo_read_rd_data (fifo_output_rvfi),
      .fifo_read_rd_en (rvfi_to_mem_valid),
      .fifo_almost_full (rvfi_fifo_almost_full),
      .fifo_write_wr_data (fifo_input_rvfi),
      .fifo_write_wr_en (rvfi_valid_i)
      );

   always_comb rvfi_busy_o = rvfi_fifo_almost_full || rvfi_fifo_busy;

   logic [23:0]  rvfi_out_counter;
   logic [207:0] rvfi_out_data;
   logic [31:0]  rvfi_out_csr [20];

   always_comb begin

      rvfi_out_counter = fifo_output_rvfi.counter;

      rvfi_out_data = {fifo_output_rvfi.rvfi_ext_mcycle,
                       fifo_output_rvfi.rvfi_rd_wdata,
                       fifo_output_rvfi.rvfi_pc_rdata,
                       fifo_output_rvfi.rvfi_ext_pre_mip,
                       fifo_output_rvfi.rvfi_ext_post_mip,
                       fifo_output_rvfi.rvfi_rd_addr,
                       fifo_output_rvfi.rvfi_ext_nmi,
                       fifo_output_rvfi.rvfi_ext_nmi_int,
                       fifo_output_rvfi.rvfi_ext_debug_req,
                       fifo_output_rvfi.rvfi_ext_rf_wr_suppress,
                       fifo_output_rvfi.rvfi_ext_ic_scr_key_valid,
                       fifo_output_rvfi.rvfi_trap,
                       5'b0};
      for (int i = 0; i < 10; i ++) begin
         rvfi_out_csr[i] = fifo_output_rvfi.rvfi_ext_mhpmcounters[i*32 +: 32];
         rvfi_out_csr[10+i] = fifo_output_rvfi.rvfi_ext_mhpmcountersh[i*32 +: 32];
      end
   end
   
   always_comb begin
      fifo_data_o[FULL_OUT_WIDTH-OUT_WIDTH-1:0] = '0;
      fifo_data_csr_o[FULL_CSR_WIDTH-CSR_WIDTH-1:0] = '0;
      fifo_keep_o = {(FULL_OUT_WIDTH/8){1'b1}};
      fifo_keep_csr_o = {(FULL_CSR_WIDTH/8){1'b1}};
      // fifo_keep_o = {{(OUT_WIDTH/8){1'b1}}, {(FULL_OUT_WIDTH-OUT_WIDTH/8){1'b0}}};
      // fifo_keep_csr_o = {{(CSR_WIDTH/8){1'b1}}, {(FULL_CSR_WIDTH-CSR_WIDTH/8){1'b0}}};
   end

   
   rvfi_to_mem
     #(
       .NUM_CSR_WORDS (20),
       .IN_WIDTH (144),
       .OUT_WIDTH (OUT_WIDTH),
       .CSR_WIDTH (CSR_WIDTH)
       ) u_rtm
     (
      .clk (clk),
      .rstn (rstn),

      .rvfi_base_addr,
      .rvfi_sw_idx,
      .rvfi_hw_idx,

      .rvfi_csr_base_addr,
      .rvfi_csr_sw_idx,
      .rvfi_csr_hw_idx,

      .valid_i (rvfi_to_mem_valid),
      .rvfi_counter (rvfi_out_counter),
      .rvfi (rvfi_out_data),
      .rvfi_csr (rvfi_out_csr),
      .wready_o (rvfi_to_mem_ready),
      .flush (flush),

      .fifo_data_o (fifo_data_o[FULL_OUT_WIDTH-1 -: OUT_WIDTH]),
      .fifo_valid_o,
      .fifo_ready_i,

      .cmd_data_o,
      .cmd_valid_o,
      .cmd_ready_i,
      
      .sts_data_o,
      .sts_valid_o,
      .sts_ready_i,
      
      .fifo_data_csr_o (fifo_data_csr_o[FULL_CSR_WIDTH-1 -: CSR_WIDTH]),
      .fifo_valid_csr_o,
      .fifo_ready_csr_i,

      .cmd_csr_data_o,
      .cmd_csr_valid_o,
      .cmd_csr_ready_i,

      .sts_csr_data_o,
      .sts_csr_valid_o,
      .sts_csr_ready_i
      
      );
   
   
endmodule
