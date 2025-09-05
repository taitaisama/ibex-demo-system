
module rvfi_to_mem #(
     parameter int NUM_CSR_WORDS = 20,
     parameter int IN_WIDTH = 144,
     parameter int OUT_WIDTH = 208,
     parameter int CSR_WIDTH = 104) 
   (
     input logic		    clk,
     input logic		    rstn,
     input logic		    valid_i,
     input [63:0]		    rvfi_mcycle,
     input [IN_WIDTH-1:0]	    rvfi,
     input [31:0]		    rvfi_csr [NUM_CSR_WORDS],
     output logic		    wready_o,

     output logic [OUT_WIDTH-1:0]   rdata_o,
     output logic		    rvalid_o,
     input logic		    rready_i,

     output logic [CSR_WIDTH-1:0]   rdata_csr_o,
     output logic		    rvalid_csr_o,
     input logic		    rready_csr_i

    );

   logic [63:0]   mcycle;

   logic [31:0]   csr_data;
   logic [7:0]    csr_addr;
   logic          csr_ready, csr_valid;
   
   logic          rvfi_fifo_empty, rvfi_csr_fifo_empty;
   logic          rvfi_fifo_almost_full, rvfi_csr_fifo_almost_full;
   
   always_ff @(posedge clk) begin
      if (valid_i) begin
         mcycle <= rvfi_mcycle;
      end
   end

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

   rvfi_mem_fifo_wrapper u_rvfi_mem_fifo
     (
      .clk (clk),
      .rst (~rstn),
      .fifo_read_almost_empty (),
      .fifo_read_empty (rvfi_fifo_empty),
      .fifo_read_rd_data (rdata_o),
      .fifo_read_rd_en (rready_i && rvalid_o),
      .fifo_write_almost_full (rvfi_fifo_almost_full),
      .fifo_write_full (),
      .fifo_write_wr_data ({rvfi_mcycle, rvfi}),
      .fifo_write_wr_en (valid_i)
      );

   rvfi_csr_fifo_wrapper u_rvfi_csr_fifo
     (
      .clk (clk),
      .rst (~rstn),
      .fifo_read_almost_empty (),
      .fifo_read_empty (rvfi_csr_fifo_empty),
      .fifo_read_rd_data (rdata_csr_o),
      .fifo_read_rd_en (rready_csr_i && rvalid_csr_o),
      .fifo_write_almost_full (rvfi_csr_fifo_almost_full),
      .fifo_write_full (),
      .fifo_write_wr_data ({mcycle, csr_addr, csr_data}),
      .fifo_write_wr_en (csr_valid)
      );

   assign wready_o = csr_ready && !rvfi_fifo_almost_full && !rvfi_csr_fifo_almost_full;
   assign rvalid_o = ~rvfi_fifo_empty;
   assign rvalid_csr_o = ~rvfi_csr_fifo_empty;
   assign csr_addr[7:$clog2(NUM_CSR_WORDS+1)] = '0;   

endmodule
