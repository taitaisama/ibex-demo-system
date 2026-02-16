

module data_ram_to_axi
  # (
      parameter int READ_BURST_BITS = 2,
      parameter int NUM_ID_BITS = 4
     )
   (
     input wire                     clk,
     input wire                     rstn,
   
     input wire                     s_req,
     input wire                     s_we,
     input wire [3:0]               s_be,
     input wire [31:0]              s_addr,
     input wire [31:0]              s_wdata,
     output logic                   s_rvalid,
     output logic [31:0]            s_rdata,
     output logic                   s_gnt,

     output logic                   m_arvalid,
     input wire                     m_arready,
     output logic [31:0]            m_araddr,
     output logic [2:0]             m_arsize,
     output logic [1:0]             m_arburst,
     output logic [NUM_ID_BITS-1:0] m_arid,
     output logic [7:0]             m_arlen,

     input wire                     m_rvalid,
     output logic                   m_rready,
     input wire                     m_rlast,
     input wire [31:0]              m_rdata,
     input wire [1:0]               m_rresp,
     input wire [NUM_ID_BITS-1:0]   m_rid,

     output logic                   m_awvalid,
     input wire                     m_awready,
     output logic [31:0]            m_awaddr,
     output logic [2:0]             m_awsize,
     output logic [1:0]             m_awburst,
     output logic [NUM_ID_BITS-1:0] m_awid,
     output logic [7:0]             m_awlen,

     output logic                   m_wvalid,
     input wire                     m_wready,
     output logic                   m_wlast,
     output logic [31:0]            m_wdata,
     output logic [3:0]             m_wstrb,
     output logic [NUM_ID_BITS-1:0] m_wid,

     input wire                   m_bvalid,
     output logic                 m_bready,
     input wire [1:0]             m_bresp,
     input wire [NUM_ID_BITS-1:0] m_bid
    );
   logic pending_read = 0;
   logic pending_write = 0;

   always_comb begin
      s_gnt = !pending_read && !pending_write && m_arready && m_awready;
   end

   always_comb begin
      m_bready = 1;
      m_araddr = s_addr;
      m_arvalid = s_req & s_gnt & ~s_we;
      m_arsize = 2;
      m_arburst = 0;
      m_arid = 0;
      m_arlen = 0;

      m_awaddr = s_addr;
      m_awvalid = s_req & s_gnt & s_we;
      m_awsize = 2;
      m_awburst = 0;
      m_awid = 0;
      m_awlen = 0;

      m_wlast = 1;
      m_wid   = 0;
   end

   always_comb begin
      s_rvalid = m_bvalid | m_rvalid;
      s_rdata = m_rdata;
   end

   always_ff @(posedge clk) begin
      if (s_gnt & s_req & s_we) begin
         m_wdata <= s_wdata;
         m_wstrb <= s_be;
         m_wvalid <= 1;
      end
      if (m_wvalid & m_wready) begin
         m_wvalid <= 0;
      end
   end

   always_ff @(posedge clk) begin
      if (s_gnt && s_req) begin
         if (s_we) begin
            pending_write <= 1;
         end else begin
            pending_read <= 1;
         end
      end
      if (m_bvalid) begin
         pending_write <= 0;
      end
      if (m_rvalid) begin
         pending_read <= 0;
      end
   end

endmodule
