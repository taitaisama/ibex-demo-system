module debug_module
  # (
     parameter int OUTPUT_WIDTH = 128,
     parameter int ADDR_WIDTH = 15
     )
  (

   input logic			     sys_clk,
   input logic			     sys_rstn,

   // INSTR stuff
   input logic			     S_RAM_INSTR_req,
   input logic			     S_RAM_INSTR_we,
   input logic [3:0]		     S_RAM_INSTR_be,
   input logic [31:0]		     S_RAM_INSTR_addr,
   input logic [31:0]		     S_RAM_INSTR_wrdata,
   input logic			     S_RAM_INSTR_rdvalid,
   input logic [31:0]		     S_RAM_INSTR_rddata,
   input logic			     S_RAM_INSTR_gnt,

   input logic			     M_AXI_INSTR_arvalid,
   input logic			     M_AXI_INSTR_arready,
   input logic [31:0]		     M_AXI_INSTR_araddr,
   input logic [2:0]		     M_AXI_INSTR_arsize,
   input logic [1:0]		     M_AXI_INSTR_arburst,
   input logic [3:0]		     M_AXI_INSTR_arid,
   input logic [7:0]		     M_AXI_INSTR_arlen,

   input logic			     M_AXI_INSTR_rvalid,
   input logic			     M_AXI_INSTR_rready,
   input logic			     M_AXI_INSTR_rlast,
   input logic [31:0]		     M_AXI_INSTR_rdata,
   input logic [1:0]		     M_AXI_INSTR_rresp,
   input logic [3:0]		     M_AXI_INSTR_rid,

   // DATA stuff
   input logic			     S_RAM_DATA_req,
   input logic			     S_RAM_DATA_we,
   input logic [3:0]		     S_RAM_DATA_be,
   input logic [31:0]		     S_RAM_DATA_addr,
   input logic [31:0]		     S_RAM_DATA_wrdata,
   input logic			     S_RAM_DATA_rdvalid,
   input logic [31:0]		     S_RAM_DATA_rddata,
   input logic			     S_RAM_DATA_gnt,

   input logic			     M_AXI_DATA_arvalid,
   input logic			     M_AXI_DATA_arready,
   input logic [31:0]		     M_AXI_DATA_araddr,
   input logic [2:0]		     M_AXI_DATA_arsize,
   input logic [1:0]		     M_AXI_DATA_arburst,
   input logic [3:0]		     M_AXI_DATA_arid,
   input logic [7:0]		     M_AXI_DATA_arlen,

   input logic			     M_AXI_DATA_rvalid,
   input logic			     M_AXI_DATA_rready,
   input logic			     M_AXI_DATA_rlast,
   input logic [31:0]		     M_AXI_DATA_rdata,
   input logic [1:0]		     M_AXI_DATA_rresp,
   input logic [3:0]		     M_AXI_DATA_rid,

   input logic			     M_AXI_DATA_awvalid,
   input logic			     M_AXI_DATA_awready,
   input logic [31:0]		     M_AXI_DATA_awaddr,
   input logic [2:0]		     M_AXI_DATA_awsize,
   input logic [1:0]		     M_AXI_DATA_awburst,
   input logic [3:0]		     M_AXI_DATA_awid,
   input logic [7:0]		     M_AXI_DATA_awlen,

   input logic			     M_AXI_DATA_wvalid,
   input logic			     M_AXI_DATA_wready,
   input logic			     M_AXI_DATA_wlast,
   input logic [31:0]		     M_AXI_DATA_wdata,
   input logic [3:0]		     M_AXI_DATA_wstrb,
   input logic [3:0]		     M_AXI_DATA_wid,

   input logic			     M_AXI_DATA_bvalid,
   input logic			     M_AXI_DATA_bready,
   input logic [1:0]		     M_AXI_DATA_bresp,
   input logic [3:0]		     M_AXI_DATA_bid,

   // rvfi stuff
   input logic			     rvfi_valid,
   input logic			     rvfi_trap,
   input logic [ 4:0]		     rvfi_rd_addr,
   input logic [31:0]		     rvfi_rd_wdata,
   input logic [31:0]		     rvfi_pc_rdata,
   input logic [31:0]		     rvfi_ext_pre_mip,
   input logic [31:0]		     rvfi_ext_post_mip,
   input logic			     rvfi_ext_nmi,
   input logic			     rvfi_ext_nmi_int,
   input logic			     rvfi_ext_debug_req,
   input logic			     rvfi_ext_rf_wr_suppress,
   input logic [63:0]		     rvfi_ext_mcycle,
   input logic [319:0]		     rvfi_ext_mhpmcounters, 
   input logic [319:0]		     rvfi_ext_mhpmcountersh,
   input logic			     rvfi_ext_ic_scr_key_valid,
   
   input logic [255:0]		     rvfi_stream_tdata,
   input logic			     rvfi_stream_tvalid,
   input logic			     rvfi_stream_tready,
   input logic [31:0]		     rvfi_stream_tkeep,
  
   input logic [71:0]		     rvfi_cmd_tdata,
   input logic			     rvfi_cmd_tvalid,
   input logic			     rvfi_cmd_tready,

   input logic [7:0]		     rvfi_sts_tdata,
   input logic			     rvfi_sts_tvalid,
   input logic			     rvfi_sts_tready,

   input logic [255:0]		     rvfi2_stream_tdata,
   input logic			     rvfi2_stream_tvalid,
   input logic			     rvfi2_stream_tready,
   input logic [15:0]		     rvfi2_stream_tkeep,

   input logic [71:0]		     rvfi_csr_cmd_tdata,
   input logic			     rvfi_csr_cmd_tvalid,
   input logic			     rvfi_csr_cmd_tready,

   input logic [7:0]		     rvfi_csr_sts_tdata,
   input logic			     rvfi_csr_sts_tvalid,
   input logic			     rvfi_csr_sts_tready,

   // DEBUG stuff
   output logic [ADDR_WIDTH-1:0]     DEBUG_addr,
   output logic			     DEBUG_clk,
   output logic [OUTPUT_WIDTH-1:0]   DEBUG_wrdata,
   input logic [OUTPUT_WIDTH-1:0]    DEBUG_rddata,
   output logic			     DEBUG_en,
   output logic			     DEBUG_rst,
   output logic [OUTPUT_WIDTH/8-1:0] DEBUG_we

   );

   localparam logic [ADDR_WIDTH-1:0] MAX_DEBUG_ADDR = 8192;

   always_comb begin
      DEBUG_en = 1;
      DEBUG_we = {(OUTPUT_WIDTH/8){1'b1}};
      DEBUG_rst = ~sys_rstn;
      DEBUG_clk = sys_clk;

      DEBUG_wrdata = {rvfi_valid,
                      rvfi_stream_tvalid,
                      rvfi_stream_tready,
                      rvfi_sts_tdata,
                      rvfi_sts_tvalid,
                      rvfi_sts_tready,
                      rvfi_cmd_tvalid,
                      rvfi_cmd_tready,
                      rvfi2_stream_tvalid,
                      rvfi2_stream_tready,
                      rvfi_cmd_tdata,
                      39'd0};
                      
      // DEBUG_wrdata = {S_RAM_INSTR_req, S_RAM_INSTR_addr, S_RAM_INSTR_rdvalid, S_RAM_INSTR_rddata, S_RAM_INSTR_gnt, 16'b0101010101010101, 45'd0};
   end

   always_ff @(posedge sys_clk or negedge sys_rstn) begin
      if (!sys_rstn) begin
	 DEBUG_addr = 0;
      end else begin
	 if (DEBUG_addr < MAX_DEBUG_ADDR) begin
	    DEBUG_addr += OUTPUT_WIDTH/8;
	 end
      end
   end
   
endmodule
