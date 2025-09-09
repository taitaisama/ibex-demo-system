module data_ram_to_axi
# (
   parameter int NUM_ID_BITS = 4
   )
(
  input logic			 clk,
  input logic			 rstn,
   
  input logic			 s_req,
  input logic			 s_we,
  input logic [3:0]		 s_be,
  input logic [31:0]		 s_addr,
  input logic [31:0]		 s_wdata,
  output logic			 s_rvalid,
  output logic [31:0]		 s_rdata,
  output logic			 s_gnt,

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
  input logic [NUM_ID_BITS-1:0]	 m_rid,

  output logic			 m_awvalid,
  input logic			 m_awready,
  output logic [31:0]		 m_awaddr,
  output logic [2:0]		 m_awsize,
  output logic [1:0]		 m_awburst,
  output logic [NUM_ID_BITS-1:0] m_awid,
  output logic [7:0]		 m_awlen,

  output logic			 m_wvalid,
  input logic			 m_wready,
  output logic			 m_wlast,
  output logic [31:0]		 m_wdata,
  output logic [3:0]		 m_wstrb,
  output logic [NUM_ID_BITS:0]	 m_wid,

  input logic			 m_bvalid,
  output logic			 m_bready,
  input logic [1:0]		 m_bresp,
  input logic [NUM_ID_BITS:0]	 m_bid
);

   logic			 q_we;
   logic [3:0]			 q_be;
   logic [31:0]			 q_addr;
   logic [31:0]			 q_wdata;
   logic			 q_req, q_gnt;

   logic			 fifo_valid, fifo_busy, fifo_almost_full;

   always_comb begin
      s_gnt = !fifo_almost_full && !fifo_busy;
      q_req = fifo_valid;
   end

   data_ram_fifo_wrapper u_drf
     (
      .clk(clk),
      .rst (~rstn),
      .data_valid (fifo_valid),
      .fifo_wr_busy (fifo_busy),
      .fifo_almost_full (fifo_almost_full),
      .fifo_read_rd_data ({q_we, q_be, q_addr, q_wdata}),
      .fifo_read_rd_en (q_req && q_gnt),
      .fifo_write_wr_data ({s_we, s_be, s_addr, s_wdata}),
      .fifo_write_wr_en (s_gnt && s_req)
      );   

   logic req_to_outstanding;

   logic q_rgnt, q_wgnt;
   logic q_rreq, q_wreq;

   always_comb begin
      q_gnt = q_rgnt && q_wgnt && ~req_to_outstanding;
      q_rreq = (q_req && !q_we) && q_gnt;
      q_wreq = (q_req && q_we) && q_gnt;
   end

   typedef struct packed {
      logic [31:0] addr;
      logic        is_valid;
   } outstanding_req;

   logic [NUM_ID_BITS-1:0] info_rid;

   outstanding_req outstanding_reads  [2**NUM_ID_BITS];
   outstanding_req outstanding_writes [2**NUM_ID_BITS];

   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
	 for (int i = 0; i < 2**NUM_ID_BITS; i ++) begin
	    outstanding_reads[i].is_valid <= 0;
	    outstanding_writes[i].is_valid <= 0;
	 end
      end else begin
	 if (s_rvalid) begin
	    outstanding_reads[info_rid].is_valid <= 0;
	 end
	 if (m_bvalid && m_bready) begin
	    outstanding_writes[m_bid].is_valid <= 0;
	 end
	 if (q_rreq) begin
	    outstanding_reads[m_arid].addr <= q_addr;
	    outstanding_reads[m_arid].is_valid <= 1;
	 end
	 if (q_wreq) begin
	    outstanding_writes[m_awid].addr <= q_addr;
	    outstanding_writes[m_awid].is_valid <= 1;
	 end
      end
   end

   always_comb begin
      req_to_outstanding = 0;
      for (int i = 0; i < 2**NUM_ID_BITS; i ++) begin
	 if (q_req) begin
	    if (outstanding_writes[i].addr == q_addr && outstanding_writes[i].is_valid) begin
	       req_to_outstanding = 1;
	    end
	    if (q_we) begin
	       if (outstanding_reads[i].addr == q_addr && outstanding_reads[i].is_valid) begin
		  req_to_outstanding = 1;
	       end
	    end
	 end
      end
   end

   read_ram_to_axi
     #( .NUM_ID_BITS (NUM_ID_BITS),
	.READ_BURST_LEN (1)
	) u_read_ram
       (
	.clk (clk),
	.rstn (rstn),
       
	.s_req (q_rreq),
	.s_addr (q_addr),
	.s_rvalid (s_rvalid),
	.s_rdata (s_rdata),
	.s_gnt (q_rgnt),

	.info_rid (info_rid),
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

   write_ram_to_axi
     #( .NUM_ID_BITS (NUM_ID_BITS)
	) u_write_ram
       (
	.clk (clk),
	.rstn (rstn),
       
	.s_req (q_wreq),
	.s_be (q_be),
	.s_addr (q_addr),
	.s_wdata (q_wdata),
	.s_gnt (q_wgnt),

	.m_awvalid (m_awvalid),
	.m_awready (m_awready),
	.m_awaddr (m_awaddr),
	.m_awsize (m_awsize),
	.m_awburst (m_awburst),
	.m_awid (m_awid),
	.m_awlen (m_awlen),

	.m_wvalid (m_wvalid),
	.m_wready (m_wready),
	.m_wlast (m_wlast),
	.m_wdata (m_wdata),
	.m_wstrb (m_wstrb),
	.m_wid (m_wid),

	.m_bvalid (m_bvalid),
	.m_bready (m_bready),
	.m_bresp (m_bresp),
	.m_bid (m_bid)
	);   

endmodule
