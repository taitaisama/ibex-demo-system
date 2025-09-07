module ram_to_axi
(
  input logic	      clk,
  input logic	      rstn,
   
  input logic	      s_req,
  input logic	      s_we,
  input logic [3:0]   s_be,
  input logic [31:0]  s_addr,
  input logic [31:0]  s_wdata,
  output logic	      s_rvalid,
  output logic [31:0] s_rdata,
  output logic	      s_gnt,

  // output logic [36:0] debug,

  output logic [31:0] m_awaddr,
  output logic	      m_awvalid,
  input logic	      m_awready,

  output logic [31:0] m_wdata,
  output logic [3:0]  m_wstrb,
  output logic	      m_wvalid,
  input logic	      m_wready,

  input logic [1:0]   m_bresp,
  input logic	      m_bvalid,
  output logic	      m_bready,

  output logic [31:0] m_araddr,
  output logic	      m_arvalid,
  input logic	      m_arready, 

  input logic [31:0]  m_rdata,
  input logic [1:0]   m_rresp,
  input logic	      m_rvalid,
  output logic	      m_rready
);

   logic s_wgnt, s_rgnt;

   logic	buffered_arreq;
   logic [31:0]	buffered_raddr;

   logic        buffered_awreq;
   logic [31:0]	buffered_waddr;

   logic [3:0]	buffered_be;
   logic [31:0]	buffered_wdata;

   // always_comb s_gnt = (s_rgnt || m_arready) && (s_wgnt || m_bvalid);
   always_comb s_gnt = 1;

   // assign debug = {s_wgnt, s_rgnt, s_gnt, buffered_arreq, buffered_awreq, buffered_raddr};

   always_comb begin
      m_araddr = buffered_arreq ? buffered_raddr : s_addr;
      m_awaddr = buffered_awreq ? buffered_waddr : s_addr;
      m_arvalid = buffered_arreq || (s_gnt && s_req && !s_we);
      m_awvalid = buffered_awreq || (s_gnt && s_req && s_we);
   end



   // s_rgnt will be given after the address has been sent to axi
   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
	 buffered_arreq <= 0;
	 s_rgnt <= 1;
      end else begin
	 if (s_gnt && s_req && !s_we && !m_arready) begin
	    s_rgnt <= 0;
	    buffered_arreq <= 1;
	    buffered_raddr <= s_addr;
	 end else if (m_arready) begin
	    buffered_arreq <= 0;
	    s_rgnt <= 1;
	 end
      end
   end

   // s_wgnt will only be given after the whole write is complete
   // this means that we should get the write ack from axi
   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
	 buffered_awreq <= 0;
	 s_wgnt <= 1;
      end else begin
   	 if (s_gnt && s_req && s_we) begin
	    buffered_be <= s_be;
	    buffered_wdata <= s_wdata;
	    s_wgnt <= 0;
	    if (!m_awready) begin
	       buffered_awreq <= 1;
	       buffered_waddr <= s_addr;
	    end
	 end else if (m_awready) begin
	    buffered_awreq <= 0;
	 end if (m_bvalid) begin
	    s_wgnt <= 1;
	 end
      end
   end

   always_comb begin
      s_rdata = m_rdata;
      s_rvalid = m_rvalid;
      m_rready = 1;
   end

   always_comb begin
      m_wdata = buffered_wdata;
      m_wstrb = buffered_be;
   end

   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
	 m_wvalid <= 0;
      end else begin
	 if (m_awvalid && m_awready) begin
	    m_wvalid <= 1;
	 end else if (m_wready) begin
	    m_wvalid <= 0;
	 end
      end
   end

   always_comb begin
      m_bready = 1;
   end

endmodule
