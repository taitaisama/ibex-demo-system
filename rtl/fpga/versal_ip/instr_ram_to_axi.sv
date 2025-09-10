module instr_ram_to_axi
# (
   parameter int NUM_ID_BITS = 4,
   parameter int READ_BURST_LEN = 4
   )
(
  input logic			 clk,
  input logic			 rstn,
   
  input logic			 s_req,
  input logic [31:0]		 s_addr,
  output logic			 s_rvalid,
  output logic [31:0]		 s_rdata,
  output logic			 s_gnt,

  output logic [77:0]		 debug,

  output logic			 m_arvalid,
  input logic			 m_arready,
  output logic [31:0]		 m_araddr,
  output logic [2:0]		 m_arsize,
  output logic [1:0]		 m_arburst,
  output logic [NUM_ID_BITS-1:0] m_arid,
  output logic [7:0]		 m_arlen,

  input logic			 m_rvalid,
  output logic			 m_rready,
  input logic			 m_rlast,
  input logic [31:0]		 m_rdata,
  input logic [1:0]		 m_rresp,
  input logic [NUM_ID_BITS-1:0]	 m_rid
);

   logic [31:0]			 q_addr;
   logic			 q_req, q_gnt;

   logic			 fifo_valid, fifo_busy, fifo_almost_full;

   logic [37:0]			 read_debug;

   
   logic [3:0]			 info_rid;
   logic [1:0]			 info_rburst;

   always_comb debug = {q_req, q_gnt, q_addr, info_rid, info_rburst, read_debug};

   always_comb begin
      s_gnt = !fifo_almost_full && !fifo_busy;
   end

   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
	 q_req <= 0;
      end else begin
	 q_req <= fifo_valid;
      end
   end

   fifo_wrapper #(.WIDTH (32), .DEPTH (128))
   u_drf (
      .clk(clk),
      .rst (~rstn),
      .data_valid (fifo_valid),
      .fifo_wr_busy (fifo_busy),
      .fifo_almost_full (fifo_almost_full),
      .fifo_read_rd_data (q_addr),
      .fifo_read_rd_en (q_req && q_gnt),
      .fifo_write_wr_data (s_addr),
      .fifo_write_wr_en (s_gnt && s_req)
      );

   read_ram_to_axi
     #( .NUM_ID_BITS (NUM_ID_BITS),
	.READ_BURST_LEN (READ_BURST_LEN)
	) u_read_ram
       (
	.clk (clk),
	.rstn (rstn),
       
	.s_req (q_req),
	.s_addr (q_addr),
	.s_rvalid (s_rvalid),
	.s_rdata (s_rdata),
	.s_gnt (q_gnt),

	.debug (read_debug),

	.info_rid (info_rid),
	.info_rburst (info_rburst),

	.m_arvalid (m_arvalid),
	.m_arready (m_arready),
	.m_araddr (m_araddr),
	.m_arsize (m_arsize),
	.m_arburst (m_arburst),
	.m_arid (m_arid),
	.m_arlen (m_arlen),

	.m_rvalid (m_rvalid),
	.m_rready (m_rready),
	.m_rlast (m_rlast),
	.m_rdata (m_rdata),
	.m_rresp (m_rresp),
	.m_rid (m_rid)
	);

endmodule
