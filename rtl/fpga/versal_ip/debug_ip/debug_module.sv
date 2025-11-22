

module debug_module
  # (
     parameter int OUTPUT_WIDTH = 128,
     parameter int ADDR_WIDTH = 15
     )
  (

   input wire			     sys_clk,
   input wire			     sys_rstn,

   // INSTR stuff
   input wire			     S_RAM_INSTR_req,
   input wire			     S_RAM_INSTR_we,
   input wire [3:0]		     S_RAM_INSTR_be,
   input wire [31:0]		     S_RAM_INSTR_addr,
   input wire [31:0]		     S_RAM_INSTR_wrdata,
   input wire			     S_RAM_INSTR_rdvalid,
   input wire [31:0]		     S_RAM_INSTR_rddata,
   input wire			     S_RAM_INSTR_gnt,

   input wire			     M_AXI_INSTR_arvalid,
   input wire			     M_AXI_INSTR_arready,
   input wire [31:0]		     M_AXI_INSTR_araddr,
   input wire [2:0]		     M_AXI_INSTR_arsize,
   input wire [1:0]		     M_AXI_INSTR_arburst,
   input wire [3:0]		     M_AXI_INSTR_arid,
   input wire [7:0]		     M_AXI_INSTR_arlen,

   input wire			     M_AXI_INSTR_rvalid,
   input wire			     M_AXI_INSTR_rready,
   input wire			     M_AXI_INSTR_rlast,
   input wire [31:0]		     M_AXI_INSTR_rdata,
   input wire [1:0]		     M_AXI_INSTR_rresp,
   input wire [3:0]		     M_AXI_INSTR_rid,

   // DATA stuff
   input wire			     S_RAM_DATA_req,
   input wire			     S_RAM_DATA_we,
   input wire [3:0]		     S_RAM_DATA_be,
   input wire [31:0]		     S_RAM_DATA_addr,
   input wire [31:0]		     S_RAM_DATA_wrdata,
   input wire			     S_RAM_DATA_rdvalid,
   input wire [31:0]		     S_RAM_DATA_rddata,
   input wire			     S_RAM_DATA_gnt,

   input wire			     M_AXI_DATA_arvalid,
   input wire			     M_AXI_DATA_arready,
   input wire [31:0]		     M_AXI_DATA_araddr,
   input wire [2:0]		     M_AXI_DATA_arsize,
   input wire [1:0]		     M_AXI_DATA_arburst,
   input wire [3:0]		     M_AXI_DATA_arid,
   input wire [7:0]		     M_AXI_DATA_arlen,

   input wire			     M_AXI_DATA_rvalid,
   input wire			     M_AXI_DATA_rready,
   input wire			     M_AXI_DATA_rlast,
   input wire [31:0]		     M_AXI_DATA_rdata,
   input wire [1:0]		     M_AXI_DATA_rresp,
   input wire [3:0]		     M_AXI_DATA_rid,

   input wire			     M_AXI_DATA_awvalid,
   input wire			     M_AXI_DATA_awready,
   input wire [31:0]		     M_AXI_DATA_awaddr,
   input wire [2:0]		     M_AXI_DATA_awsize,
   input wire [1:0]		     M_AXI_DATA_awburst,
   input wire [3:0]		     M_AXI_DATA_awid,
   input wire [7:0]		     M_AXI_DATA_awlen,

   input wire			     M_AXI_DATA_wvalid,
   input wire			     M_AXI_DATA_wready,
   input wire			     M_AXI_DATA_wlast,
   input wire [31:0]		     M_AXI_DATA_wdata,
   input wire [3:0]		     M_AXI_DATA_wstrb,
   input wire [3:0]		     M_AXI_DATA_wid,

   input wire			     M_AXI_DATA_bvalid,
   input wire			     M_AXI_DATA_bready,
   input wire [1:0]		     M_AXI_DATA_bresp,
   input wire [3:0]		     M_AXI_DATA_bid,

   // rvfi stuff
   input wire			     rvfi_valid,
   input wire			     rvfi_trap,
   input wire [ 4:0]		     rvfi_rd_addr,
   input wire [31:0]		     rvfi_rd_wdata,
   input wire [31:0]		     rvfi_pc_rdata,
   input wire [31:0]		     rvfi_ext_pre_mip,
   input wire [31:0]		     rvfi_ext_post_mip,
   input wire			     rvfi_ext_nmi,
   input wire			     rvfi_ext_nmi_int,
   input wire			     rvfi_ext_debug_req,
   input wire			     rvfi_ext_rf_wr_suppress,
   input wire [63:0]		     rvfi_ext_mcycle,
   input wire [319:0]		     rvfi_ext_mhpmcounters, 
   input wire [319:0]		     rvfi_ext_mhpmcountersh,
   input wire			     rvfi_ext_ic_scr_key_valid,
   
   input wire [255:0]		     rvfi_stream_tdata,
   input wire			     rvfi_stream_tvalid,
   input wire			     rvfi_stream_tready,
   input wire [31:0]		     rvfi_stream_tkeep,
  
   input wire [71:0]		     rvfi_cmd_tdata,
   input wire			     rvfi_cmd_tvalid,
   input wire			     rvfi_cmd_tready,

   input wire [7:0]		     rvfi_sts_tdata,
   input wire			     rvfi_sts_tvalid,
   input wire			     rvfi_sts_tready,

   input wire [127:0]		     rvfi_csr_stream_tdata,
   input wire			     rvfi_csr_stream_tvalid,
   input wire			     rvfi_csr_stream_tready,
   input wire [15:0]		     rvfi_csr_stream_tkeep,

   input wire [71:0]		     rvfi_csr_cmd_tdata,
   input wire			     rvfi_csr_cmd_tvalid,
   input wire			     rvfi_csr_cmd_tready,

   input wire [7:0]		     rvfi_csr_sts_tdata,
   input wire			     rvfi_csr_sts_tvalid,
   input wire			     rvfi_csr_sts_tready,

   // DEBUG stuff
   output logic [ADDR_WIDTH-1:0]     DEBUG_addr,
   output logic			     DEBUG_clk,
   output logic [OUTPUT_WIDTH-1:0]   DEBUG_wrdata,
   input wire [OUTPUT_WIDTH-1:0]    DEBUG_rddata,
   output logic			     DEBUG_en,
   output logic			     DEBUG_rst,
   output logic [OUTPUT_WIDTH/8-1:0] DEBUG_we

   );

   localparam logic [ADDR_WIDTH-1:0] MAX_DEBUG_ADDR = 8192;

   logic [25:0]                      last_mcycle;
   logic [7:0]                       last_sts;
   
   always_ff @(posedge sys_clk) begin
      if (rvfi_valid) begin
         last_mcycle <= rvfi_ext_mcycle[25:0];
      end
      if (rvfi_sts_tvalid & rvfi_sts_tready) begin
         last_sts <= rvfi_sts_tdata;
      end
   end

   always_comb begin
      DEBUG_en = 1;
      DEBUG_we = (rvfi_cmd_tvalid & rvfi_cmd_tready) ? {(OUTPUT_WIDTH/8){1'b1}} : '0;
      DEBUG_rst = ~sys_rstn;
      DEBUG_clk = sys_clk;

      DEBUG_wrdata = {rvfi_cmd_tdata,
                      rvfi_cmd_tvalid,
                      rvfi_cmd_tready,
                      last_sts,
                      last_mcycle};
                      
      // DEBUG_wrdata = {S_RAM_INSTR_req, S_RAM_INSTR_addr, S_RAM_INSTR_rdvalid, S_RAM_INSTR_rddata, S_RAM_INSTR_gnt, 16'b0101010101010101, 45'd0};
   end

   always_ff @(posedge sys_clk or negedge sys_rstn) begin
      if (!sys_rstn) begin
	 DEBUG_addr = 0;
      end else begin
	 if (DEBUG_we != 0) begin
	    DEBUG_addr += OUTPUT_WIDTH/8;
	 end
      end
   end
   
endmodule
