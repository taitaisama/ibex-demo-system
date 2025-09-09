`timescale 1ns/1ps

module tb;

   localparam int NUM_ID_BITS = 4;

   logic			 clk = 0;
   logic			 rstn = 0;
   
   logic			 s_req;
   logic			 s_we;
   logic [3:0]			 s_be;
   logic [31:0]			 s_addr;
   logic [31:0]			 s_wdata;
   logic			 s_rvalid;
   logic [31:0]			 s_rdata;
   logic			 s_gnt;

   logic			 m_arvalid;
   logic			 m_arready;
   logic [31:0]			 m_araddr;
   logic [2:0]			 m_arsize;
   logic [1:0]			 m_arburst;
   logic [NUM_ID_BITS-1:0]	 m_arid;
   logic [7:0]			 m_arlen;

   logic			 m_rvalid;
   logic			 m_rready;
   logic			 m_rlast;
   logic [31:0]			 m_rdata;
   logic [1:0]			 m_rresp;
   logic [NUM_ID_BITS-1:0]	 m_rid;

   logic			 m_awvalid;
   logic			 m_awready;
   logic [31:0]			 m_awaddr;
   logic [2:0]			 m_awsize;
   logic [1:0]			 m_awburst;
   logic [NUM_ID_BITS-1:0]	 m_awid;
   logic [7:0]			 m_awlen;

   logic			 m_wvalid;
   logic			 m_wready;
   logic			 m_wlast;
   logic [31:0]			 m_wdata;
   logic [3:0]			 m_wstrb;
   logic [NUM_ID_BITS:0]	 m_wid;

   logic			 m_bvalid;
   logic			 m_bready;
   logic [1:0]			 m_bresp;
   logic [NUM_ID_BITS:0]	 m_bid;

   typedef struct packed {
      logic [31:0] addr;
      logic        is_valid;
      logic        is_value_pending; // only for writes
   } pending_req_t;


   pending_req_t p_rreqs [2**NUM_ID_BITS];
   pending_req_t p_wreqs [2**NUM_ID_BITS];

   logic check_conflict;
   logic check_error;
   
   logic [NUM_ID_BITS-1:0] rand_rreq, rand_breq;

   always_comb begin
      check_conflict = 0;
      for (int i = 0; i < 2**NUM_ID_BITS; i ++) begin
	 for (int j = 0; j < 2**NUM_ID_BITS; j ++) begin	 
	    if (p_rreqs[i].is_valid && p_wreqs[j].is_valid && p_rreqs[i].addr == p_wreqs[j].addr) begin
	       check_conflict = 1;
	    end
	    if (i != j && p_wreqs[i].is_valid && p_wreqs[j].is_valid && p_wreqs[i].addr == p_wreqs[j].addr) begin
	       check_conflict = 1;
	    end
	 end
      end
   end

   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
	 for (int i = 0; i < 2**NUM_ID_BITS; i ++) begin
	    p_rreqs[i].is_valid <= 0;
	    p_wreqs[i].is_valid <= 0;
	    p_wreqs[i].is_value_pending <= 0;
	 end
	 
	 s_req <= 0;
	 s_we <= 0;
      end else begin
	 
	 
	 rand_rreq = $urandom_range((2**NUM_ID_BITS)-1, 0);
	 rand_breq = $urandom_range((2**NUM_ID_BITS)-1, 0);

	 check_error = 0;
	 
	 s_req <= $urandom_range(1, 0);
	 s_we <= $urandom_range(1, 0);
	 s_addr <= $urandom_range(9, 0);
	 s_be <= 4'b1111;
	 s_wdata <= $urandom_range(1000, 0);

	 m_arready <= $urandom_range(1, 0);
	 m_awready <= $urandom_range(1, 0);
	 m_wready <= $urandom_range(1, 0);

	 m_rvalid <= 0;
	 m_bvalid <= 0;

	 m_bresp <= 0;
	 m_rresp <= 0;
	 m_rlast <= 1;
	 
	 if (m_rready && p_rreqs[rand_rreq].is_valid) begin
	    m_rvalid <= 1;
	    m_rid <= rand_rreq;
	    m_rdata <= $urandom_range(1000, 0);
	 end	 

	 if (m_bready && p_wreqs[rand_breq].is_valid && !p_wreqs[rand_breq].is_value_pending) begin
	    m_bvalid <= 1;
	    m_bid <= rand_breq;
	 end

	 if (m_rvalid && m_rready) begin
	    p_rreqs[m_rid].is_valid <= 0;
	 end

	 if (m_bvalid && m_bready) begin
	    p_wreqs[m_bid].is_valid <= 0;
	 end

	 if (m_arvalid && m_arready) begin
	    check_error = check_error || (p_rreqs[m_arid].is_valid == 1);

	    p_rreqs[m_arid].is_valid <= 1;
	    p_rreqs[m_arid].addr <= m_araddr;
	 end

	 if (m_awready && m_awvalid) begin
	    check_error = check_error || (p_wreqs[m_awid].is_valid == 1) || (p_wreqs[m_awid].is_value_pending == 1);

	    p_wreqs[m_awid].is_valid <= 1;
	    p_wreqs[m_awid].addr <= m_awaddr;
	    p_wreqs[m_awid].is_value_pending <= 1;
	 end

	 if (m_wready && m_wvalid) begin
	    check_error = check_error || (p_wreqs[m_wid].is_valid == 0) || (p_wreqs[m_wid].is_value_pending == 0);
	    
	    p_wreqs[m_wid].is_value_pending <= 0;
	 end	 
      end
   end

   data_ram_to_axi
  # (
      .NUM_ID_BITS (NUM_ID_BITS)
     ) u_dut
   (
    .clk (clk),
    .rstn (rstn),   
    .s_req (s_req),
    .s_we (s_we),
    .s_be (s_be),
    .s_addr (s_addr),
    .s_wdata (s_wdata),
    .s_rvalid (s_rvalid),
    .s_rdata (s_rdata),
    .s_gnt (s_gnt),
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
    .m_rid (m_rid),
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
   
   // Clock generation
   always #5 clk = ~clk; // 100MHz

   initial begin
      rstn = 0;

      #20;
      
      rstn = 1;
      

      #1000000;
      $finish;
   end
   

endmodule
