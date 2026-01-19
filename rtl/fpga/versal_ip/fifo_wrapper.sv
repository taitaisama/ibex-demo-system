

module fifo_wrapper
  # (
     parameter int WIDTH,
     parameter int DEPTH
     )
(
  input wire		   clk,
  input wire		   rst,
  output logic		   data_valid,
  output logic		   fifo_almost_full,
  output logic		   fifo_wr_busy,
  output logic [WIDTH-1:0] fifo_read_rd_data,
  input wire		   fifo_read_rd_en,
  input wire [WIDTH-1:0]   fifo_write_wr_data,
  input wire		   fifo_write_wr_en
 );
  if (WIDTH == 6 && DEPTH == 128) begin : g_fifo_6_128

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
   end else if (WIDTH == 32 && DEPTH == 16) begin : g_fifo_32_16

      fifo_32_16_wrapper u_fifo 
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
   end else if (WIDTH == 40 && DEPTH == 16) begin : g_fifo_40_16

      fifo_40_16_wrapper u_fifo 
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

   end else if (WIDTH == 69 && DEPTH == 16) begin : g_fifo_69_16

      fifo_69_16_wrapper u_fifo 
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

   end else if (WIDTH == 227 && DEPTH == 16) begin : g_fifo_227_16

      fifo_227_16_wrapper u_fifo 
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

   end else if (WIDTH == 664 && DEPTH == 16) begin : g_fifo_664_16

      fifo_664_16_wrapper u_fifo 
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

   end else if (WIDTH == 98 && DEPTH == 16) begin : g_fifo_98_16

      fifo_98_16_wrapper u_fifo 
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
