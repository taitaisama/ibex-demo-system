

module instr_ram_to_axi
# (
   parameter int NUM_ID_BITS = 4,
   parameter int READ_BURST_BITS = 2
   )
(
  input wire			 clk,
  input wire			 rstn,
   
  input wire			 s_req,
  input wire [31:0]		 s_addr,
  output logic			 s_rvalid,
  output logic [31:0]		 s_rdata,
  output logic			 s_gnt,

  output logic			 m_arvalid,
  input wire			 m_arready,
  output logic [31:0]		 m_araddr,
  output logic [2:0]		 m_arsize,
  output logic [1:0]		 m_arburst,
  output logic [NUM_ID_BITS-1:0] m_arid,
  output logic [7:0]		 m_arlen,

  input wire			 m_rvalid,
  output logic			 m_rready,
  input wire			 m_rlast,
  input wire [31:0]		 m_rdata,
  input wire [1:0]		 m_rresp,
  input wire [NUM_ID_BITS-1:0]	 m_rid
);

   logic [31:0]			 q_addr;
   logic			 q_req, q_gnt;

   logic                         r_req;
   logic [31:0]                  r_addr;
   logic                         r_rvalid;
   logic [31:0]                  r_rdata;
   logic                         r_gnt;

   always_ff @(posedge clk) begin
      s_gnt <= r_gnt;
      s_rdata <= r_rdata;
      s_rvalid <= r_rvalid;
      r_req <= s_req && s_gnt;
      r_addr <= s_addr;
   end

   logic			 fifo_valid, fifo_almost_full, fifo_busy;

   always_comb begin
      r_gnt = !fifo_almost_full && !fifo_busy;
      q_req = fifo_valid;
   end

   fifo_wrapper #(.WIDTH(32), .DEPTH(16)) u_drf
     (
      .clk(clk),
      .rst (~rstn),
      .data_valid (fifo_valid),
      .fifo_wr_busy (fifo_busy),
      .fifo_almost_full (fifo_almost_full),
      .fifo_read_rd_data (q_addr),
      .fifo_read_rd_en (q_req && q_gnt),
      .fifo_write_wr_data (r_addr),
      .fifo_write_wr_en (r_req)
      );   


   read_ram_to_axi
     #( .NUM_ID_BITS (NUM_ID_BITS),
	.READ_BURST_BITS (READ_BURST_BITS)
	) u_read_ram
       (
	.clk (clk),
	.rstn (rstn),
       
	.s_req (q_req),
	.s_addr (q_addr),
	.s_rvalid (r_rvalid),
	.s_rdata (r_rdata),
	.s_gnt (q_gnt),

	.info_rid (),
	.info_rburst (),

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
