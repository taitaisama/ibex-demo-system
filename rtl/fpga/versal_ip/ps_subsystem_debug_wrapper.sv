module ps_subsystem_debug_wrapper
  (

output [0:0] DDR4_act_n,
output [16:0] DDR4_adr,
output [1:0] DDR4_ba,
output [0:0] DDR4_bg,
output [0:0] DDR4_ck_c,
output [0:0] DDR4_ck_t,
output [0:0] DDR4_cke,
output [0:0] DDR4_cs_n,
inout [7:0] DDR4_dm_n,
inout [63:0] DDR4_dq,
inout [7:0] DDR4_dqs_c,
inout [7:0] DDR4_dqs_t,
output [0:0] DDR4_odt,
output [0:0] DDR4_reset_n,
input [71:0] rvfi_cmd_tdata,
output [0:0] rvfi_cmd_tready,
input [0:0] rvfi_cmd_tvalid,
input [255:0] rvfi_tdata,
input [31:0] rvfi_tkeep,
output [0:0] rvfi_tready,
input [0:0] rvfi_tvalid,
output [15:0] PS_BRAM_addr,
output [0:0] PS_BRAM_clk,
output [31:0] PS_BRAM_din,
input [31:0] PS_BRAM_dout,
output [0:0] PS_BRAM_en,
output [0:0] PS_BRAM_rst,
output [3:0] PS_BRAM_we,
output [1:0] PS_IO_tri_o,
output [0:0] axi_clk,
output [0:0] axi_rstn,
input [71:0] rvfi_csr_cmd_tdata,
output [0:0] rvfi_csr_cmd_tready,
input [0:0] rvfi_csr_cmd_tvalid,
input [127:0] rvfi_csr_tdata,
input [15:0] rvfi_csr_tkeep,
output [0:0] rvfi_csr_tready,
input [0:0] rvfi_csr_tvalid,
input [0:0] sys_clk_n,
input [0:0] sys_clk_p

   );

   localparam logic [15:0] MAX_DEBUG_ADDR = 256*(512/8);
   
   logic [15:0]  DEBUG_addr;
   logic         DEBUG_clk;
   logic [511:0] DEBUG_din;
   logic [511:0] DEBUG_dout;
   logic	 DEBUG_en;
   logic	 DEBUG_rst;
   logic [63:0]	 DEBUG_we;


logic [31:0]DM_OUT_awaddr;
logic [1:0]DM_OUT_awburst;
logic [3:0]DM_OUT_awcache;
logic [3:0]DM_OUT_awid;
logic [7:0]DM_OUT_awlen;
logic [2:0]DM_OUT_awprot;
logic [0:0]DM_OUT_awready;
logic [2:0]DM_OUT_awsize;
logic [3:0]DM_OUT_awuser;
logic [0:0]DM_OUT_awvalid;
logic [0:0]DM_OUT_bready;
logic [1:0]DM_OUT_bresp;
logic [0:0]DM_OUT_bvalid;
logic [255:0]DM_OUT_wdata;
logic [0:0]DM_OUT_wlast;
logic [0:0]DM_OUT_wready;
logic [31:0]DM_OUT_wstrb;
logic [0:0]DM_OUT_wvalid;
logic [255:0]RVFI_FIFO_OUT_tdata;
logic [31:0]RVFI_FIFO_OUT_tkeep;
logic [0:0]RVFI_FIFO_OUT_tready;
logic [0:0]RVFI_FIFO_OUT_tvalid;


   always_comb begin
      DEBUG_din = {DM_OUT_awaddr, DM_OUT_awburst, DM_OUT_awcache, DM_OUT_awid, DM_OUT_awlen, DM_OUT_awprot, DM_OUT_awready, DM_OUT_awsize, DM_OUT_awuser, DM_OUT_awvalid, DM_OUT_bready, DM_OUT_bresp, DM_OUT_bvalid, DM_OUT_wdata[223:192], DM_OUT_wlast, DM_OUT_wready, DM_OUT_wstrb, DM_OUT_wvalid, RVFI_FIFO_OUT_tdata[223:192], RVFI_FIFO_OUT_tkeep, RVFI_FIFO_OUT_tready, RVFI_FIFO_OUT_tvalid, DDR4_act_n, DDR4_adr, DDR4_ba, DDR4_bg, DDR4_ck_c, DDR4_ck_t, DDR4_cke, DDR4_cs_n, DDR4_dm_n, DDR4_dq, DDR4_dqs_c, DDR4_dqs_t, DDR4_odt, DDR4_reset_n, rvfi_cmd_tdata, rvfi_cmd_tready, rvfi_cmd_tvalid, rvfi_tdata[223:192], rvfi_tkeep, rvfi_tready, rvfi_tvalid, 4'hf, {50{1'b0}}, 4'hf};
      DEBUG_clk = axi_clk;
      DEBUG_rst = ~axi_rstn;
      DEBUG_we = 64'hffffffffffffffff;
      DEBUG_en = 1;
   end

   always_ff @(posedge DEBUG_clk or negedge DEBUG_rst) begin
      if (DEBUG_rst) begin
	 DEBUG_addr = 0;
      end else begin
	 if (DEBUG_addr < MAX_DEBUG_ADDR) begin
	    DEBUG_addr += (512/8);
	 end
      end
   end

ps_subsystem_wrapper u_ps
  (
   .DM_OUT_awaddr (DM_OUT_awaddr),
.DM_OUT_awburst (DM_OUT_awburst),
.DM_OUT_awcache (DM_OUT_awcache),
.DM_OUT_awid (DM_OUT_awid),
.DM_OUT_awlen (DM_OUT_awlen),
.DM_OUT_awprot (DM_OUT_awprot),
.DM_OUT_awready (DM_OUT_awready),
.DM_OUT_awsize (DM_OUT_awsize),
.DM_OUT_awuser (DM_OUT_awuser),
.DM_OUT_awvalid (DM_OUT_awvalid),
.DM_OUT_bready (DM_OUT_bready),
.DM_OUT_bresp (DM_OUT_bresp),
.DM_OUT_bvalid (DM_OUT_bvalid),
.DM_OUT_wdata (DM_OUT_wdata),
.DM_OUT_wlast (DM_OUT_wlast),
.DM_OUT_wready (DM_OUT_wready),
.DM_OUT_wstrb (DM_OUT_wstrb),
.DM_OUT_wvalid (DM_OUT_wvalid),
.RVFI_FIFO_OUT_tdata (RVFI_FIFO_OUT_tdata),
.RVFI_FIFO_OUT_tkeep (RVFI_FIFO_OUT_tkeep),
.RVFI_FIFO_OUT_tready (RVFI_FIFO_OUT_tready),
.RVFI_FIFO_OUT_tvalid (RVFI_FIFO_OUT_tvalid),
.DDR4_act_n (DDR4_act_n),
.DDR4_adr (DDR4_adr),
.DDR4_ba (DDR4_ba),
.DDR4_bg (DDR4_bg),
.DDR4_ck_c (DDR4_ck_c),
.DDR4_ck_t (DDR4_ck_t),
.DDR4_cke (DDR4_cke),
.DDR4_cs_n (DDR4_cs_n),
.DDR4_dm_n (DDR4_dm_n),
.DDR4_dq (DDR4_dq),
.DDR4_dqs_c (DDR4_dqs_c),
.DDR4_dqs_t (DDR4_dqs_t),
.DDR4_odt (DDR4_odt),
.DDR4_reset_n (DDR4_reset_n),
.rvfi_cmd_tdata (rvfi_cmd_tdata),
.rvfi_cmd_tready (rvfi_cmd_tready),
.rvfi_cmd_tvalid (rvfi_cmd_tvalid),
.rvfi_tdata (rvfi_tdata),
.rvfi_tkeep (rvfi_tkeep),
.rvfi_tready (rvfi_tready),
.rvfi_tvalid (rvfi_tvalid),
.PS_BRAM_addr (PS_BRAM_addr),
.PS_BRAM_clk (PS_BRAM_clk),
.PS_BRAM_din (PS_BRAM_din),
.PS_BRAM_dout (PS_BRAM_dout),
.PS_BRAM_en (PS_BRAM_en),
.PS_BRAM_rst (PS_BRAM_rst),
.PS_BRAM_we (PS_BRAM_we),
.PS_IO_tri_o (PS_IO_tri_o),
.axi_clk (axi_clk),
.axi_rstn (axi_rstn),
.rvfi_csr_cmd_tdata (rvfi_csr_cmd_tdata),
.rvfi_csr_cmd_tready (rvfi_csr_cmd_tready),
.rvfi_csr_cmd_tvalid (rvfi_csr_cmd_tvalid),
.rvfi_csr_tdata (rvfi_csr_tdata),
.rvfi_csr_tkeep (rvfi_csr_tkeep),
.rvfi_csr_tready (rvfi_csr_tready),
.rvfi_csr_tvalid (rvfi_csr_tvalid),
.sys_clk_n (sys_clk_n),
.sys_clk_p (sys_clk_p),

   .DEBUG_addr,
   .DEBUG_clk,
   .DEBUG_din,
   .DEBUG_dout,
   .DEBUG_en,
   .DEBUG_rst,
   .DEBUG_we
);

endmodule
