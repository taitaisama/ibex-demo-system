
module rvfi_to_mem #(
     parameter int	    NUM_CSR_WORDS = 20,
     parameter int	    IN_WIDTH = 144,
     parameter int	    OUT_WIDTH = 208,
     parameter int	    CSR_WIDTH = 104,
     parameter logic [31:0] BUFFER_SIZE = 32'h100000,
     parameter int	    NUM_BUFFERS = 4)
(

 input logic [31:0]			rvfi_base_addr,
 input logic [$clog2(NUM_BUFFERS)-1:0]	rvfi_sw_idx,
 output logic [$clog2(NUM_BUFFERS)-1:0]	rvfi_hw_idx,

 input logic [31:0]			rvfi_csr_base_addr,
 input logic [$clog2(NUM_BUFFERS)-1:0]	rvfi_csr_sw_idx,
 output logic [$clog2(NUM_BUFFERS)-1:0]	rvfi_csr_hw_idx,

 input logic				clk,
 input logic				rstn,
 input logic				valid_i,
 input [63:0]				rvfi_mcycle,
 input [IN_WIDTH-1:0]			rvfi,
 input [31:0]				rvfi_csr [NUM_CSR_WORDS],
 output logic				wready_o,
 input logic				flush,

 output logic [OUT_WIDTH-1:0]		fifo_data_o,
 output logic				fifo_valid_o,
 input logic				fifo_ready_i,
     
 output logic [71:0]			cmd_data_o,
 output logic				cmd_valid_o,
 input logic				cmd_ready_i,

 input logic [7:0]			sts_data_o,
 input logic				sts_valid_o,
 output logic				sts_ready_i,

 output logic [CSR_WIDTH-1:0]		fifo_data_csr_o,
 output logic				fifo_valid_csr_o,
 input logic				fifo_ready_csr_i,
     
 output logic [71:0]			cmd_csr_data_o,
 output logic				cmd_csr_valid_o,
 input logic				cmd_csr_ready_i,

 input logic [7:0]			sts_csr_data_o,
 input logic				sts_csr_valid_o,
 output logic				sts_csr_ready_i

 );

   logic [63:0]   mcycle;

   logic [31:0]   csr_data;
   logic [7:0]    csr_addr;
   logic          csr_ready, csr_valid;
   
   assign csr_addr[7:$clog2(NUM_CSR_WORDS+1)] = '0;

   rvfi_csr #(.NUM_WORDS (NUM_CSR_WORDS), .WIDTH (32)) 
   u_csr (
          .clk (clk),
          .rstn (rstn),
          .data_i (rvfi_csr),
          .valid_i (valid_i),
          .data_o (csr_data),
          .addr_o (csr_addr[$clog2(NUM_CSR_WORDS+1):0]),
          .ready_o (csr_ready),
          .valid_o (csr_valid)
          );

   always_comb begin
      wready_o = csr_ready && fifo_ready_i && fifo_ready_csr_i;
      fifo_valid_o = valid_i;
      fifo_data_o  = {rvfi_mcycle, rvfi};
      fifo_valid_csr_o = csr_valid;
      fifo_data_csr_o <= {mcycle, csr_addr, csr_data};   
   end

   datamover_cmd
     #(.DATA_WIDTH (OUT_WIDTH),
       .BUFFER_SIZE (BUFFER_SIZE),
       .NUM_BUFFERS (NUM_BUFFERS)
       ) u_dmc
     (
      .clk (clk),
      .rstn (rstn),
      .base_addr (rvfi_base_addr),
      .hw_idx (rvfi_hw_idx),
      .sw_idx (rvfi_sw_idx),
      .fifo_write (fifo_valid_o && fifo_ready_i),
      .flush (flush),
      .m_axis_cmd_tdata (cmd_data_o),
      .m_axis_cmd_tvalid (cmd_valid_o),
      .m_axis_cmd_tready (cmd_ready_i),
      .m_axis_sts_tdata (sts_data_o),
      .m_axis_sts_tvalid (sts_valid_o),
      .m_axis_sts_tready (sts_ready_i)
      );
   
   datamover_cmd
     #(.DATA_WIDTH (CSR_WIDTH),
       .BUFFER_SIZE (BUFFER_SIZE),
       .NUM_BUFFERS (NUM_BUFFERS)
       ) u_dmc_csr
     (
      .clk (clk),
      .rstn (rstn),
      .base_addr (rvfi_csr_base_addr),
      .hw_idx (rvfi_csr_hw_idx),
      .sw_idx (rvfi_csr_sw_idx),
      .fifo_write (fifo_csr_valid_o && fifo_csr_ready_i),
      .flush (flush),
      .m_axis_cmd_tdata (cmd_csr_data_o),
      .m_axis_cmd_tvalid (cmd_csr_valid_o),
      .m_axis_cmd_tready (cmd_csr_ready_i),
      .m_axis_sts_tdata (sts_csr_data_o),
      .m_axis_sts_tvalid (sts_csr_valid_o),
      .m_axis_sts_tready (sts_csr_ready_i)
      );   

endmodule
