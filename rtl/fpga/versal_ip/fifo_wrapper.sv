`default_nettype none

module fifo_wrapper
  # (
     parameter int WIDTH,
     parameter int DEPTH
     )
(
  input logic		   clk,
  input logic		   rst,
  output logic		   data_valid,
  output logic		   fifo_wr_busy,
  output logic		   fifo_almost_full,
  output logic [WIDTH-1:0] fifo_read_rd_data,
  input logic		   fifo_read_rd_en,
  input logic [WIDTH-1:0]  fifo_write_wr_data,
  input logic		   fifo_write_wr_en
 );

   if (WIDTH == 4 && DEPTH == 128) begin : g_fifo_4_128

      fifo_4_128_wrapper u_fifo 
	(
	 .clk(clk),
	 .rst (rst),
	 .data_valid (data_valid),
	 .fifo_wr_busy (fifo_wr_busy),
	 .fifo_almost_full (fifo_almost_full),
	 .fifo_read_rd_data (fifo_read_rd_data),
	 .fifo_read_rd_en (fifo_read_rd_en),
	 .fifo_write_wr_data (fifo_write_wr_data),
	 .fifo_write_wr_en (fifo_write_wr_en)
	 );      

   end else if (WIDTH == 6 && DEPTH == 128) begin : g_fifo_6_128

      fifo_6_128_wrapper u_fifo 
	(
	 .clk(clk),
	 .rst (rst),
	 .data_valid (data_valid),
	 .fifo_wr_busy (fifo_wr_busy),
	 .fifo_almost_full (fifo_almost_full),
	 .fifo_read_rd_data (fifo_read_rd_data),
	 .fifo_read_rd_en (fifo_read_rd_en),
	 .fifo_write_wr_data (fifo_write_wr_data),
	 .fifo_write_wr_en (fifo_write_wr_en)
	 );      

   end else if (WIDTH == 32 && DEPTH == 128) begin : g_fifo_32_128

      fifo_32_128_wrapper u_fifo 
	(
	 .clk(clk),
	 .rst (rst),
	 .data_valid (data_valid),
	 .fifo_wr_busy (fifo_wr_busy),
	 .fifo_almost_full (fifo_almost_full),
	 .fifo_read_rd_data (fifo_read_rd_data),
	 .fifo_read_rd_en (fifo_read_rd_en),
	 .fifo_write_wr_data (fifo_write_wr_data),
	 .fifo_write_wr_en (fifo_write_wr_en)
	 );      
   end else if (WIDTH == 40 && DEPTH == 128) begin : g_fifo_40_128

      fifo_40_128_wrapper u_fifo 
	(
	 .clk(clk),
	 .rst (rst),
	 .data_valid (data_valid),
	 .fifo_wr_busy (fifo_wr_busy),
	 .fifo_almost_full (fifo_almost_full),
	 .fifo_read_rd_data (fifo_read_rd_data),
	 .fifo_read_rd_en (fifo_read_rd_en),
	 .fifo_write_wr_data (fifo_write_wr_data),
	 .fifo_write_wr_en (fifo_write_wr_en)
	 );      

   end else if (WIDTH == 69 && DEPTH == 128) begin : g_fifo_69_128

      fifo_69_128_wrapper u_fifo 
	(
	 .clk(clk),
	 .rst (rst),
	 .data_valid (data_valid),
	 .fifo_wr_busy (fifo_wr_busy),
	 .fifo_almost_full (fifo_almost_full),
	 .fifo_read_rd_data (fifo_read_rd_data),
	 .fifo_read_rd_en (fifo_read_rd_en),
	 .fifo_write_wr_data (fifo_write_wr_data),
	 .fifo_write_wr_en (fifo_write_wr_en)
	 ); 

   end else if (WIDTH == 856 && DEPTH == 16) begin : g_fifo_856_16

      fifo_856_16_wrapper u_fifo 
	(
	 .clk(clk),
	 .rst (rst),
	 .data_valid (data_valid),
	 .fifo_wr_busy (fifo_wr_busy),
	 .fifo_almost_full (fifo_almost_full),
	 .fifo_read_rd_data (fifo_read_rd_data),
	 .fifo_read_rd_en (fifo_read_rd_en),
	 .fifo_write_wr_data (fifo_write_wr_data),
	 .fifo_write_wr_en (fifo_write_wr_en)
	 ); 

   end else begin : g_fifo_error

      $error($sformatf("Illegal values for parameters WIDTH (%0d) and DEPTH (%0d)", WIDTH, DEPTH));

   end

endmodule
