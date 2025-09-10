`timescale 1ns/1ps

module tb;

   localparam int NUM_ID_BITS = 4;
   localparam int READ_BURST_LEN = 4;

   logic clk = 0;
   logic rstn = 0;

   logic s_req;
   logic [31:0]	s_addr;
   logic	s_rvalid;
   logic [31:0]	s_rdata;
   logic	s_gnt;

   logic	m_arvalid;
   logic	m_arready;
   logic [31:0]	m_araddr;
   logic [2:0]	m_arsize;
   logic [1:0]	m_arburst;
   logic [NUM_ID_BITS-1:0] m_arid;
   logic [7:0]		   m_arlen;

   logic		   m_rvalid;
   logic		   m_rready;
   logic		   m_rlast;
   logic [31:0]		   m_rdata;
   logic [1:0]		   m_rresp;
   logic [NUM_ID_BITS-1:0] m_rid;


   typedef struct packed {
      logic [31:0] addr;
      logic        is_valid;
   } pending_req_t;

   pending_req_t pending_reqs [2**NUM_ID_BITS];

   logic [$clog2(READ_BURST_LEN)-1:0] remaining_bursts;
   logic [31:0]			      servicing_addr;

   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
	 remaining_bursts <= 0;
	 m_rvalid = 0;
	 for (int i = 0; i < 2**NUM_ID_BITS; i ++) begin
	    pending_reqs[i].is_valid = 0;
	 end
      end else begin
	 if (remaining_bursts != 0) begin
	    m_rvalid = 1;
	 end else begin	 
	    // service a random request
	    automatic int rand_req = $urandom_range((2**NUM_ID_BITS)-1, 0);
	    if (pending_reqs[rand_req].is_valid) begin
	       m_rvalid = 1;
	       servicing_addr <= pending_reqs[rand_req].addr;
	       m_rid <= rand_req;
	       pending_reqs[rand_req].is_valid <= 0;
	    end else begin
	       m_rvalid = 0;
	    end
	 end

	 if (m_arvalid && m_arready) begin
	    pending_reqs[m_arid].is_valid <= 1;
	    pending_reqs[m_arid].addr <= m_araddr;
	 end

	 if (m_rvalid && m_rready) begin
	    if (remaining_bursts == 0) begin
	       remaining_bursts <= READ_BURST_LEN-1;
	    end else begin
	       remaining_bursts <= remaining_bursts-1;
	    end
	 end
      end
   end
   
   always_comb begin
      m_rdata = servicing_addr + ((4 - remaining_bursts) * 4);
      m_rlast = remaining_bursts == 0;
      m_rresp = 0;
   end


   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
	 s_req <= 0;
	 s_addr <= 0;
	 m_arready <= 0;
      end else begin
	 s_req <= $urandom_range(1, 0);
	 m_arready <= $urandom_range(1, 0);
	 if (s_req && s_gnt) begin
	    s_addr <= s_addr + (($urandom_range(1, 0) == 1) ? 4 : 8);
	 end
      end
   end

   logic prev_diff;
   logic [31:0] prev_rdata;
   
   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
	 prev_rdata <= 0;
      end else begin
	 if (s_rvalid) begin
	    $display("s_rdata %d, prev_rdata+4 %d", s_rdata, prev_rdata+4);
	    // assert (s_rdata == prev_rdata + 4) else $error("Data mismatch!");
	    prev_rdata <= s_rdata;
	    prev_diff <= (s_rdata ==  prev_rdata + 4) || (s_rdata ==  prev_rdata + 8);
	 end 
      end
   end

   read_ram_to_axi #( .NUM_ID_BITS (NUM_ID_BITS),
   .READ_BURST_LEN (READ_BURST_LEN))
   u_dut
   (
    .clk (clk),
    .rstn (rstn),
   
    .s_req (s_req),
    .s_addr (s_addr),
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
    .m_rid (m_rid)
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
