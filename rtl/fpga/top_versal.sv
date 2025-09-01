// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// This is the top level SystemVerilog file that connects the IO on the board to the Ibex Demo System.

module top_versal #(
  parameter SRAMInitFile = "/home/ritu/dev/work/ibex-demo-system/sw/c/build/demo/hello_world/demo.hex"
) (
  // These inputs are defined in data/pins_artya7.xdc
    input         sys_clk_p,
    input         sys_clk_n,
    
    output [0:0]  DDR4_act_n,
    output [16:0] DDR4_adr,
    output [1:0]  DDR4_ba,
    output [0:0]  DDR4_bg,
    output [0:0]  DDR4_ck_c,
    output [0:0]  DDR4_ck_t,
    output [0:0]  DDR4_cke,
    output [0:0]  DDR4_cs_n,
    inout [7:0]   DDR4_dm_n,
    inout [63:0]  DDR4_dq,
    inout [7:0]   DDR4_dqs_c,
    inout [7:0]   DDR4_dqs_t,
    output [0:0]  DDR4_odt,
    output [0:0]  DDR4_reset_n,
  
    output reg    led
);

   logic sys_clk;
   logic axi_rstn, sys_rstn;

   logic        ibex_ram_a_req;
   logic [3:0]  ibex_ram_a_we;
   logic [3:0]  ibex_ram_a_be;
   logic [31:0] ibex_ram_a_addr;
   logic [31:0] ibex_ram_a_wdata;
   logic        ibex_ram_a_rvalid;
   logic [31:0] ibex_ram_a_rdata;

   logic        ibex_ram_b_req;
   logic [3:0]  ibex_ram_b_we;
   logic [3:0]  ibex_ram_b_be;
   logic [31:0] ibex_ram_b_addr;
   logic [31:0] ibex_ram_b_wdata;
   logic        ibex_ram_b_rvalid;
   logic [31:0] ibex_ram_b_rdata;
   
   logic        ps_bram_a_clk;
   logic        ps_bram_a_rst;
   logic [3:0]  ps_bram_a_we;
   logic        ps_bram_a_en;
   logic [31:0] ps_bram_a_addr;
   logic [31:0] ps_bram_a_wdata;
   logic [31:0] ps_bram_a_rdata;

   logic        ram_a_req;
   logic [3:0]  ram_a_we;
   logic [3:0]  ram_a_be;
   logic [31:0] ram_a_addr;
   logic [31:0] ram_a_wdata;
   logic        ram_a_rvalid;
   logic [31:0] ram_a_rdata;

   logic        ps_ctrl, ps_ctrl_d;
   logic        force_stop;
   logic        ps_send_last, pl_send_last, send_last_done, send_last_csr_done, send_last_called;

   logic [31:0]	instr_count;

   logic        rvfi_valid;
   logic        rvfi_trap;
   logic [ 4:0] rvfi_rd_addr;
   logic [31:0] rvfi_rd_wdata;
   logic [31:0] rvfi_pc_rdata;
   logic [31:0] rvfi_ext_pre_mip;
   logic [31:0] rvfi_ext_post_mip;
   logic        rvfi_ext_nmi;
   logic        rvfi_ext_nmi_int;
   logic        rvfi_ext_debug_req;
   logic        rvfi_ext_rf_wr_suppress;
   logic [63:0] rvfi_ext_mcycle;
   logic [31:0] rvfi_ext_mhpmcounters [10];   
   logic [31:0] rvfi_ext_mhpmcountersh [10];
   logic        rvfi_ext_ic_scr_key_valid;
   
   localparam int RVFI_OUT_WIDTH = 256;
   localparam int RVFI_CSR_OUT_WIDTH = 128;
   localparam int RVFI_FIFO_WIDTH = 208;
   localparam int RVFI_CSR_FIFO_WIDTH = 104;

   logic [RVFI_OUT_WIDTH-1:0]	    rvfi_tdata;
   logic			    rvfi_tvalid;
   logic			    rvfi_tready;
   logic			    rvfi_tlast;
   logic [RVFI_OUT_WIDTH/8-1:0]	    rvfi_tkeep;
   
   logic [RVFI_CSR_OUT_WIDTH-1:0]   rvfi_csr_tdata;
   logic			    rvfi_csr_tvalid;
   logic			    rvfi_csr_tready;
   logic			    rvfi_csr_tlast;
   logic [RVFI_CSR_OUT_WIDTH/8-1:0] rvfi_csr_tkeep;

   logic [RVFI_OUT_WIDTH-1:0]	    rvfi_handler_tdata;
   logic			    rvfi_handler_tvalid;
   
   logic [RVFI_CSR_OUT_WIDTH-1:0]   rvfi_handler_csr_tdata;
   logic			    rvfi_handler_csr_tvalid;

   logic			    rvfi_handler_ready;

   localparam logic [31:0]	    DEBUG_MAX_ADDR = 800;
   logic [31:0]			    debug_addr;
   logic [63:0]			    debug_data;

   logic			    pending_request;
   logic [31:0]			    pending_addr;

   always_comb begin
      rvfi_tkeep = {{(RVFI_FIFO_WIDTH/8){1'b1}}, {((RVFI_OUT_WIDTH-RVFI_FIFO_WIDTH)/8){1'b0}}};
      rvfi_csr_tkeep = {{(RVFI_CSR_FIFO_WIDTH/8){1'b1}}, {((RVFI_CSR_OUT_WIDTH-RVFI_CSR_FIFO_WIDTH)/8){1'b0}}};      
   end

   always_ff @(posedge sys_clk or negedge sys_rstn) begin
      if (!sys_rstn) begin
	 pending_request <= 0;
	 pending_addr <= 'x;
      end else begin
	 if (ibex_ram_b_req && force_stop) begin
	    pending_request <= 1;
	    pending_addr <= ibex_ram_b_addr;
	 end
	 if (pending_request && !force_stop) begin
	    pending_request <= 0;
	    pending_addr <= 'x;
	 end
      end
   end

   always_ff @(posedge sys_clk or negedge sys_rstn) begin
      if (!sys_rstn) begin
	 debug_addr <= 0;
      end else begin
	 if (debug_addr < DEBUG_MAX_ADDR) begin
	    debug_addr <= debug_addr + 8;
	 end
      end
   end

   always_comb debug_data = {rvfi_valid, rvfi_tready, rvfi_tlast, rvfi_rd_addr, rvfi_tdata[185:181], rvfi_tkeep, ibex_ram_b_addr[9:0], rvfi_ext_mcycle[8:0]};

   always_comb begin
      ram_a_req = ps_ctrl ? ps_bram_a_en : ibex_ram_a_req;
      ram_a_we = ps_ctrl ? ps_bram_a_we : ibex_ram_a_we;
      ram_a_be = ps_ctrl ? 4'b1111 : ibex_ram_a_be;
      ram_a_addr = ps_ctrl ? ps_bram_a_addr : ibex_ram_a_addr;
      ram_a_wdata = ps_ctrl ? ps_bram_a_wdata : ibex_ram_a_wdata;
      ibex_ram_a_rvalid = (~ps_ctrl) && ram_a_rvalid;
      ibex_ram_a_rdata = ram_a_rdata;
      ps_bram_a_rdata = ram_a_rdata;
   end   
   
   always_ff @(posedge sys_clk) begin
      ps_ctrl_d <= ps_ctrl;
   end

   always_comb pl_send_last = instr_count > 100;

   always_ff @(posedge sys_clk or negedge sys_rstn) begin
      if (!sys_rstn) begin
         send_last_done <= '0;
         send_last_csr_done <= '0;
         send_last_called <= '0;
	 instr_count <= '0;
      end else begin
         if (ps_send_last || pl_send_last) begin
            send_last_called <= '1;
         end
         if (rvfi_tvalid && rvfi_tlast && rvfi_tready) begin
            send_last_done <= '1;
         end
         if (rvfi_csr_tvalid && rvfi_csr_tlast && rvfi_csr_tready) begin
            send_last_csr_done <= '1;
         end
	 if (ibex_ram_b_rvalid && !ps_ctrl) begin
	    instr_count <= instr_count + 1;
	 end
      end
   end
   
   assign sys_rstn = axi_rstn && !(ps_ctrl_d && !ps_ctrl);

   localparam logic [31:0] MEM_SIZE      = 128 * 1024; // 128 KiB   

  ram_2p #(
    .Depth       ( MEM_SIZE / 4 ),
    .MemInitFile ( SRAMInitFile )
  ) u_ram (
   .clk_i (sys_clk),
   .rst_ni(axi_rstn),

   .a_req_i   (ram_a_req),
   .a_we_i    (ram_a_we),
   .a_be_i    (ram_a_be),
   .a_addr_i  (ram_a_addr),
   .a_wdata_i (ram_a_wdata),
   .a_rvalid_o(ram_a_rvalid),
   .a_rdata_o (ram_a_rdata),

   .b_req_i   ((pending_request || ibex_ram_b_req) && !force_stop),
   .b_we_i    (ibex_ram_b_we),
   .b_be_i    (ibex_ram_b_be),
   .b_addr_i  (pending_request ? pending_addr : ibex_ram_b_addr),
   .b_wdata_i (ibex_ram_b_wdata),
   .b_rvalid_o(ibex_ram_b_rvalid),
   .b_rdata_o (ibex_ram_b_rdata)
   );

  // Instantiating the Ibex Demo System.
  ibex_demo_system #(
    .GpiWidth     ( 0            ),
    .GpoWidth     ( 1            ),
    .PwmWidth     ( 0            ),
    .SRAMInitFile ( SRAMInitFile )
  ) u_ibex_demo_system (
    //input
    .clk_sys_i (sys_clk),
    .rst_sys_ni(sys_rstn),
    .gp_i      (),
    .uart_rx_i (1'b0),

    //output
    .gp_o     (led),
    .pwm_o    (),
    .uart_tx_o(),

    .spi_rx_i (1'b0),
    .spi_tx_o (),
    .spi_sck_o(),

    .ibex_ram_a_req_o (ibex_ram_a_req),
    .ibex_ram_a_we_o (ibex_ram_a_we),
    .ibex_ram_a_be_o (ibex_ram_a_be),
    .ibex_ram_a_addr_o (ibex_ram_a_addr),
    .ibex_ram_a_wdata_o (ibex_ram_a_wdata),
    .ibex_ram_a_rvalid_i (ibex_ram_a_rvalid),
    .ibex_ram_a_rdata_i (ibex_ram_a_rdata),
                              
    .ibex_ram_b_req_o (ibex_ram_b_req),
    .ibex_ram_b_we_o (ibex_ram_b_we),
    .ibex_ram_b_be_o (ibex_ram_b_be),
    .ibex_ram_b_addr_o (ibex_ram_b_addr),
    .ibex_ram_b_wdata_o (ibex_ram_b_wdata),
    .ibex_ram_b_rvalid_i (ibex_ram_b_rvalid),
    .ibex_ram_b_rdata_i (ibex_ram_b_rdata),

    .rvfi_valid,
    .rvfi_trap,
    .rvfi_rd_addr,
    .rvfi_rd_wdata,
    .rvfi_pc_rdata,
    .rvfi_ext_pre_mip,
    .rvfi_ext_post_mip,
    .rvfi_ext_nmi,
    .rvfi_ext_nmi_int,
    .rvfi_ext_debug_req,
    .rvfi_ext_rf_wr_suppress,
    .rvfi_ext_mcycle,
    .rvfi_ext_mhpmcounters,
    .rvfi_ext_mhpmcountersh,
    .rvfi_ext_ic_scr_key_valid,

    .trst_ni(1'b1),
    .tms_i  (1'b0),
    .tck_i  (1'b0),
    .td_i   (1'b0),
    .td_o   ()
  );

   always_comb force_stop = ~rvfi_handler_ready;

   rvfi_handler u_rh 
     (
      .clk (sys_clk),
      .rstn (sys_rstn),

      .rvfi_valid_i (rvfi_valid && (!ps_ctrl)),
      .rvfi_trap_i (rvfi_trap),
      .rvfi_rd_addr_i (rvfi_rd_addr),
      .rvfi_rd_wdata_i (rvfi_rd_wdata),
      .rvfi_pc_rdata_i (rvfi_pc_rdata),
      .rvfi_ext_pre_mip_i (rvfi_ext_pre_mip),
      .rvfi_ext_post_mip_i (rvfi_ext_post_mip),
      .rvfi_ext_nmi_i (rvfi_ext_nmi),
      .rvfi_ext_nmi_int_i (rvfi_ext_nmi_int),
      .rvfi_ext_debug_req_i (rvfi_ext_debug_req),
      .rvfi_ext_rf_wr_suppress_i (rvfi_ext_rf_wr_suppress),
      .rvfi_ext_mcycle_i (rvfi_ext_mcycle),
      .rvfi_ext_mhpmcounters_i (rvfi_ext_mhpmcounters),
      .rvfi_ext_mhpmcountersh_i (rvfi_ext_mhpmcountersh),
      .rvfi_ext_ic_scr_key_valid_i (rvfi_ext_ic_scr_key_valid),

      .rdata_o (rvfi_handler_tdata),
      .rvalid_o (rvfi_handler_tvalid),
      .rready_i (rvfi_tready),

      .rdata_csr_o (rvfi_handler_csr_tdata),
      .rvalid_csr_o (rvfi_handler_csr_tvalid),
      .rready_csr_i (rvfi_csr_tready),
      
      .rvfi_ready_o (rvfi_handler_ready)
      );


   always_comb begin
      if (send_last_called) begin
         if (!send_last_done) begin
            rvfi_tdata = '0;
            rvfi_tvalid = '1;
            rvfi_tlast = '1;
         end else begin
            rvfi_tdata = 'x;
            rvfi_tvalid = '0;
            rvfi_tlast = 'x;
         end
         if (!send_last_csr_done) begin
            rvfi_csr_tdata = '0;
            rvfi_csr_tvalid = '1;
            rvfi_csr_tlast = '1;
         end else begin
            rvfi_csr_tdata = 'x;
            rvfi_csr_tvalid = '0;
            rvfi_csr_tlast = 'x;
         end
      end else begin
         rvfi_tdata = rvfi_handler_tdata;
         rvfi_tvalid = rvfi_handler_tvalid;
         rvfi_tlast = '0;
         rvfi_csr_tdata = rvfi_handler_csr_tdata;
         rvfi_csr_tvalid = rvfi_handler_csr_tvalid;
         rvfi_csr_tlast = '0;
      end
   end
   
   ps_subsystem_wrapper u_pssub (
    .DDR4_act_n         (DDR4_act_n    ),
    .DDR4_adr           (DDR4_adr      ),
    .DDR4_ba            (DDR4_ba       ),
    .DDR4_bg            (DDR4_bg       ),
    .DDR4_ck_c          (DDR4_ck_c     ),
    .DDR4_ck_t          (DDR4_ck_t     ),
    .DDR4_cke           (DDR4_cke      ),
    .DDR4_cs_n          (DDR4_cs_n     ),
    .DDR4_dm_n          (DDR4_dm_n     ),
    .DDR4_dq            (DDR4_dq       ),
    .DDR4_dqs_c         (DDR4_dqs_c    ),
    .DDR4_dqs_t         (DDR4_dqs_t    ),
    .DDR4_odt           (DDR4_odt      ),
    .DDR4_reset_n       (DDR4_reset_n  ),

    .PS_BRAM_addr (ps_bram_a_addr),
    .PS_BRAM_clk (ps_bram_a_clk),
    .PS_BRAM_din (ps_bram_a_wdata),
    .PS_BRAM_dout (ps_bram_a_rdata),
    .PS_BRAM_en (ps_bram_a_en),
    .PS_BRAM_rst (ps_bram_a_rst),
    .PS_BRAM_we (ps_bram_a_we),

    .DEBUG_BRAM_addr (debug_addr),
    .DEBUG_BRAM_clk (sys_clk),
    .DEBUG_BRAM_din (debug_data),
    .DEBUG_BRAM_dout (),
    .DEBUG_BRAM_en (1),
    .DEBUG_BRAM_rst (~axi_rstn),
    .DEBUG_BRAM_we (8'b11111111),

    .PS_IO_tri_o ({ps_ctrl, ps_send_last}),

    .rvfi_tdata,
    .rvfi_tvalid,
    .rvfi_tready,
    .rvfi_tkeep,
    .rvfi_tlast,
   
    .rvfi_csr_tdata,
    .rvfi_csr_tvalid,
    .rvfi_csr_tready,
    .rvfi_csr_tkeep,
    .rvfi_csr_tlast,

    .axi_clk (sys_clk),
    .axi_rstn (axi_rstn),
    .sys_clk_n (sys_clk_n),
    .sys_clk_p (sys_clk_p)
   );

endmodule
