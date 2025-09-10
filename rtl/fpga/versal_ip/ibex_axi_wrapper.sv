module ibex_axi_wrapper
  (
   input logic		sys_clk,
   input logic		sys_rstn,

   output logic		led,

   output logic [255:0]	rvfi_tdata,
   output logic		rvfi_tvalid,
   input logic		rvfi_tready,
   output logic [31:0]	rvfi_tkeep,

   output logic [127:0]	rvfi_csr_tdata,
   output logic		rvfi_csr_tvalid,
   input logic		rvfi_csr_tready,
   output logic [15:0]	rvfi_csr_tkeep,

   output logic [71:0]	rvfi_cmd_tdata,
   output logic		rvfi_cmd_tvalid,
   input logic		rvfi_cmd_tready,

   output logic [71:0]	rvfi_csr_cmd_tdata,
   output logic		rvfi_csr_cmd_tvalid,
   input logic		rvfi_csr_cmd_tready,

   input logic		flush,

   output logic [255:0]	debug,

   output logic		m_a_arvalid,
   input logic		m_a_arready,
   output logic [31:0]	m_a_araddr,
   output logic [2:0]	m_a_arsize,
   output logic [1:0]	m_a_arburst,
   output logic [3:0]	m_a_arid,
   output logic [7:0]	m_a_arlen,

   input logic		m_a_rvalid,
   output logic		m_a_rready,
   input logic		m_a_rlast,
   input logic [31:0]	m_a_rdata,
   input logic [1:0]	m_a_rresp,
   input logic [3:0]	m_a_rid,

   output logic		m_a_awvalid,
   input logic		m_a_awready,
   output logic [31:0]	m_a_awaddr,
   output logic [2:0]	m_a_awsize,
   output logic [1:0]	m_a_awburst,
   output logic [3:0]	m_a_awid,
   output logic [7:0]	m_a_awlen,

   output logic		m_a_wvalid,
   input logic		m_a_wready,
   output logic		m_a_wlast,
   output logic [31:0]	m_a_wdata,
   output logic [3:0]	m_a_wstrb,
   output logic [3:0]	m_a_wid,

   input logic		m_a_bvalid,
   output logic		m_a_bready,
   input logic [1:0]	m_a_bresp,
   input logic [3:0]	m_a_bid,


   output logic		m_b_arvalid,
   input logic		m_b_arready,
   output logic [31:0]	m_b_araddr,
   output logic [2:0]	m_b_arsize,
   output logic [1:0]	m_b_arburst,
   output logic [3:0]	m_b_arid,
   output logic [7:0]	m_b_arlen,

   input logic		m_b_rvalid,
   output logic		m_b_rready,
   input logic		m_b_rlast,
   input logic [31:0]	m_b_rdata,
   input logic [1:0]	m_b_rresp,
   input logic [3:0]	m_b_rid
);

   logic			    ibex_ram_a_req;
   logic			    ibex_ram_a_we;
   logic [3:0]			    ibex_ram_a_be;
   logic [31:0]			    ibex_ram_a_addr;
   logic [31:0]			    ibex_ram_a_wdata;
   logic			    ibex_ram_a_rvalid;
   logic [31:0]			    ibex_ram_a_rdata;
   logic			    ibex_ram_a_gnt;   

   logic			    ibex_ram_b_req;
   logic			    ibex_ram_b_we;
   logic [3:0]			    ibex_ram_b_be;
   logic [31:0]			    ibex_ram_b_addr;
   logic [31:0]			    ibex_ram_b_wdata;
   logic			    ibex_ram_b_rvalid;
   logic [31:0]			    ibex_ram_b_rdata;
   logic			    ibex_ram_b_gnt;

   logic [77:0]			    instr_debug;

   always_comb debug = {ibex_ram_b_req, ibex_ram_b_we, ibex_ram_b_addr, ibex_ram_b_rvalid, ibex_ram_b_rdata, ibex_ram_b_gnt, m_b_arvalid, m_b_arready, m_b_araddr, m_b_rvalid, m_b_rready, m_b_rdata, m_b_rid, m_b_rlast, m_b_arid, instr_debug, 4'hf, 25'd0, 4'hf};

   data_ram_to_axi #(.NUM_ID_BITS (4)) 
   u_dr2a
     (
      .clk (sys_clk),
      .rstn (sys_rstn),

      .s_req (ibex_ram_a_req),
      .s_we (ibex_ram_a_we),
      .s_be (ibex_ram_a_be),
      .s_addr (ibex_ram_a_addr),
      .s_wdata (ibex_ram_a_wdata),
      .s_rvalid (ibex_ram_a_rvalid),
      .s_rdata (ibex_ram_a_rdata),
      .s_gnt (ibex_ram_a_gnt),

      .m_arvalid (m_a_arvalid),
      .m_arready (m_a_arready),
      .m_araddr (m_a_araddr),
      .m_arsize (m_a_arsize),
      .m_arburst (m_a_arburst),
      .m_arid (m_a_arid),
      .m_arlen (m_a_arlen),

      .m_rvalid (m_a_rvalid),
      .m_rready (m_a_rready),
      .m_rlast (m_a_rlast),
      .m_rdata (m_a_rdata),
      .m_rresp (m_a_rresp),
      .m_rid (m_a_rid),

      .m_awvalid (m_a_awvalid),
      .m_awready (m_a_awready),
      .m_awaddr (m_a_awaddr),
      .m_awsize (m_a_awsize),
      .m_awburst (m_a_awburst),
      .m_awid (m_a_awid),
      .m_awlen (m_a_awlen),

      .m_wvalid (m_a_wvalid),
      .m_wready (m_a_wready),
      .m_wlast (m_a_wlast),
      .m_wdata (m_a_wdata),
      .m_wstrb (m_a_wstrb),
      .m_wid (m_a_wid),

      .m_bvalid (m_a_bvalid),
      .m_bready (m_a_bready),
      .m_bresp (m_a_bresp),
      .m_bid (m_a_bid)
      );

   instr_ram_to_axi #(.NUM_ID_BITS (4)) 
   u_ir2a
     (
      .clk (sys_clk),
      .rstn (sys_rstn),

      .s_req (ibex_ram_b_req && !ibex_ram_b_we),
      .s_addr (ibex_ram_b_addr),
      .s_rvalid (ibex_ram_b_rvalid),
      .s_rdata (ibex_ram_b_rdata),
      .s_gnt (ibex_ram_b_gnt),

      .debug (instr_debug),

      .m_arvalid (m_b_arvalid),
      .m_arready (m_b_arready),
      .m_araddr (m_b_araddr),
      .m_arsize (m_b_arsize),
      .m_arburst (m_b_arburst),
      .m_arid (m_b_arid),
      .m_arlen (m_b_arlen),

      .m_rvalid (m_b_rvalid),
      .m_rready (m_b_rready),
      .m_rlast (m_b_rlast),
      .m_rdata (m_b_rdata),
      .m_rresp (m_b_rresp),
      .m_rid (m_b_rid)
      );
   

   ibex_rvfi_wrapper u_irw
     (
      .sys_clk,
      .sys_rstn,
      .led,
      
      .ibex_ram_a_req,
      .ibex_ram_a_we,
      .ibex_ram_a_be,
      .ibex_ram_a_addr,
      .ibex_ram_a_wdata,
      .ibex_ram_a_rvalid,
      .ibex_ram_a_rdata,
      .ibex_ram_a_gnt,

      .ibex_ram_b_req,
      .ibex_ram_b_we,
      .ibex_ram_b_be,
      .ibex_ram_b_addr,
      .ibex_ram_b_wdata,
      .ibex_ram_b_rvalid,
      .ibex_ram_b_rdata,
      .ibex_ram_b_gnt,

      .rvfi_tdata,
      .rvfi_tvalid,
      .rvfi_tready,
      .rvfi_tkeep,
      .rvfi_csr_tdata,
      .rvfi_csr_tvalid,
      .rvfi_csr_tready,
      .rvfi_csr_tkeep,
      .rvfi_cmd_tdata,
      .rvfi_cmd_tvalid,
      .rvfi_cmd_tready,
      .rvfi_csr_cmd_tdata,
      .rvfi_csr_cmd_tvalid,
      .rvfi_csr_cmd_tready,
      .flush
      );
   
endmodule
