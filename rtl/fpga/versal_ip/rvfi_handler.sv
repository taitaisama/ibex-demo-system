

module rvfi_handler #(
   parameter     RVFI_WIDTH = 256,
   parameter int CSR_WIDTH = 64,
   parameter int DSIDE_WIDTH = 128,
   parameter int LOG2_BUFFER_SIZE = 20)
( 
  input wire                          clk,
  input wire                          rstn,

  input wire [31:0]                   rvfi_base_addr,
  input wire [LOG2_BUFFER_SIZE-1:0]   rvfi_sw_idx,
  output logic [LOG2_BUFFER_SIZE-1:0] rvfi_hw_idx,

  input wire [31:0]                   csr_base_addr,
  input wire [LOG2_BUFFER_SIZE-1:0]   csr_sw_idx,
  output logic [LOG2_BUFFER_SIZE-1:0] csr_hw_idx,

  input wire [31:0]                   dside_base_addr,
  input wire [LOG2_BUFFER_SIZE-1:0]   dside_sw_idx,
  output logic [LOG2_BUFFER_SIZE-1:0] dside_hw_idx,

  input wire                          rvfi_valid_i,
  input wire                          rvfi_trap_i,
  input wire [ 4:0]                   rvfi_rd_addr_i,
  input wire [31:0]                   rvfi_rd_wdata_i,
  input wire [31:0]                   rvfi_pc_rdata_i,
  input wire [31:0]                   rvfi_ext_pre_mip_i,
  input wire [31:0]                   rvfi_ext_post_mip_i,
  input wire                          rvfi_ext_nmi_i,
  input wire                          rvfi_ext_nmi_int_i,
  input wire                          rvfi_ext_debug_req_i,
  input wire                          rvfi_ext_rf_wr_suppress_i,
  input wire [63:0]                   rvfi_ext_mcycle_i,
  input wire [319:0]                  rvfi_ext_mhpmcounters_i, 
  input wire [319:0]                  rvfi_ext_mhpmcountersh_i,
  input wire                          rvfi_ext_ic_scr_key_valid_i,

  input wire                          dside_access_valid_i,
  input wire                          dside_access_store_i,
  input wire [31:0]                   dside_access_addr_i,
  input wire [3:0]                    dside_access_be_i,
  input wire [31:0]                   dside_access_store_data_i,
  input wire                          dside_access_err_i,
  input wire                          dside_access_misaligned_first_i,
  input wire                          dside_access_misaligned_second_i,
  input wire                          dside_access_misaligned_first_saw_error_i,
  input wire                          dside_access_m_mode_access_i,

  output logic [RVFI_WIDTH-1:0]       rvfi_axis_fifo_data_o,
  output logic                        rvfi_axis_fifo_valid_o,
  input wire                          rvfi_axis_fifo_ready_i,
  output logic [RVFI_WIDTH/8-1:0]     rvfi_axis_fifo_keep_o,
  
  output logic [71:0]                 rvfi_cmd_data_o,
  output logic                        rvfi_cmd_valid_o,
  input wire                          rvfi_cmd_ready_i,

  input wire [7:0]                    rvfi_sts_data_o,
  input wire                          rvfi_sts_valid_o,
  output logic                        rvfi_sts_ready_i,

  output logic [CSR_WIDTH-1:0]        csr_axis_fifo_data_o,
  output logic                        csr_axis_fifo_valid_o,
  input wire                          csr_axis_fifo_ready_i,
  output logic [CSR_WIDTH/8-1:0]      csr_axis_fifo_keep_o,

  output logic [71:0]                 csr_cmd_data_o,
  output logic                        csr_cmd_valid_o,
  input wire                          csr_cmd_ready_i,

  input wire [7:0]                    csr_sts_data_o,
  input wire                          csr_sts_valid_o,
  output logic                        csr_sts_ready_i,

  output logic [DSIDE_WIDTH-1:0]      dside_axis_fifo_data_o,
  output logic                        dside_axis_fifo_valid_o,
  input wire                          dside_axis_fifo_ready_i,
  output logic [DSIDE_WIDTH/8-1:0]    dside_axis_fifo_keep_o,

  output logic [71:0]                 dside_cmd_data_o,
  output logic                        dside_cmd_valid_o,
  input wire                          dside_cmd_ready_i,

  input wire [7:0]                    dside_sts_data_o,
  input wire                          dside_sts_valid_o,
  output logic                        dside_sts_ready_i,

  input wire                          flush,

  output logic                        busy_o
);

   localparam int NUM_CSR_WORDS = 20;

   logic [23:0] sync_counter;

   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         sync_counter     <= '0;
      end else begin
         sync_counter     <= sync_counter + 1;
      end
   end

   // RVFI stuff   
   typedef struct packed {
      logic [23:0] counter;
      logic [63:0] ext_mcycle;
      logic [31:0] rd_wdata;
      logic [31:0] pc_rdata;
      logic [31:0] ext_pre_mip;
      logic [31:0] ext_post_mip;
      logic [ 4:0] rd_addr;
      logic        ext_nmi;
      logic        ext_nmi_int;
      logic        ext_debug_req;
      logic        ext_rf_wr_suppress;
      logic        ext_ic_scr_key_valid;
      logic        trap;
   } rvfi_data_t;

   rvfi_data_t  rvfi_fifo_wr_data;
   rvfi_data_t  rvfi_fifo_rd_data;
   logic        rvfi_fifo_data_valid;
   logic        rvfi_fifo_almost_full;
   logic        rvfi_fifo_rd_en;
   logic        rvfi_fifo_wr_en;

   fifo_wrapper #(.WIDTH($bits(rvfi_data_t)), .DEPTH(16))
   u_rvfi_fifo (
      .clk (clk),
      .rst (~rstn),
      .data_valid (rvfi_fifo_data_valid),
      .fifo_read_rd_data (rvfi_fifo_rd_data),
      .fifo_read_rd_en (rvfi_to_mem_valid),
      .fifo_almost_full (rvfi_fifo_almost_full),
      .fifo_write_wr_data (rvfi_fifo_wr_data),
      .fifo_write_wr_en (rvfi_valid_i)
      );

   always_comb begin
      rvfi_fifo_wr_en = rvfi_valid_i;

      rvfi_fifo_wr_data.counter = sync_counter;
      rvfi_fifo_wr_data.trap = rvfi_trap_i;
      rvfi_fifo_wr_data.rd_addr = rvfi_rd_addr_i;
      rvfi_fifo_wr_data.rd_wdata = rvfi_rd_wdata_i;
      rvfi_fifo_wr_data.pc_rdata = rvfi_pc_rdata_i;
      rvfi_fifo_wr_data.ext_pre_mip = rvfi_ext_pre_mip_i;
      rvfi_fifo_wr_data.ext_post_mip = rvfi_ext_post_mip_i;
      rvfi_fifo_wr_data.ext_nmi = rvfi_ext_nmi_i;
      rvfi_fifo_wr_data.ext_nmi_int = rvfi_ext_nmi_int_i;
      rvfi_fifo_wr_data.ext_debug_req = rvfi_ext_debug_req_i;
      rvfi_fifo_wr_data.ext_rf_wr_suppress = rvfi_ext_rf_wr_suppress_i;
      rvfi_fifo_wr_data.ext_mcycle = rvfi_ext_mcycle_i;
      rvfi_fifo_wr_data.ext_ic_scr_key_valid = rvfi_ext_ic_scr_key_valid_i;

      rvfi_fifo_rd_en  = rvfi_fifo_data_valid & rvfi_axis_fifo_ready_i;

      rvfi_axis_fifo_data_o = {rvfi_fifo_rd_data, {(RVFI_WIDTH-$bits(rvfi_data_t)){1'b0}}};
      rvfi_axis_fifo_valid_o = rvfi_fifo_rd_en;
      rvfi_axis_fifo_keep_o = '1;
   end

   datamover_cmd
     #(.DATA_WIDTH (RVFI_WIDTH),
       .LOG2_BUFFER_SIZE (LOG2_BUFFER_SIZE)
       ) u_rvfi_dmc
     (
      .clk (clk),
      .rstn (rstn),
      .base_addr (rvfi_base_addr),
      .hw_idx (rvfi_hw_idx),
      .sw_idx (rvfi_sw_idx),
      .fifo_write (rvfi_axis_fifo_valid_o && rvfi_axis_fifo_ready_i),
      .flush (flush),
      .m_axis_cmd_tdata (rvfi_cmd_data_o),
      .m_axis_cmd_tvalid (rvfi_cmd_valid_o),
      .m_axis_cmd_tready (rvfi_cmd_ready_i),
      .m_axis_sts_tdata (rvfi_sts_data_o),
      .m_axis_sts_tvalid (rvfi_sts_valid_o),
      .m_axis_sts_tready (rvfi_sts_ready_i)
    );


   // CSR stuff
   typedef struct packed {
      logic [23:0] counter;
      logic [319:0] ext_mhpmcounters;   
      logic [319:0] ext_mhpmcountersh;
   } csr_data_t;

   csr_data_t   csr_fifo_wr_data;
   csr_data_t   csr_fifo_rd_data;
   logic        csr_fifo_data_valid;
   logic        csr_fifo_almost_full;
   logic        csr_fifo_rd_en;
   logic        csr_fifo_wr_en;
   

   logic [31:0] csr_counter_store;
   logic [31:0] csr_counter_store_d;

                  
   logic [31:0] csr_serializer_out_data;
   logic [31:0] csr_serializer_in_data [20];
   logic [7:0]  csr_serializer_out_addr;
   logic        csr_serializer_ready, csr_serializer_in_valid, csr_serializer_out_valid;

   fifo_wrapper #(.WIDTH($bits(csr_data_t)), .DEPTH(16))
   u_csr_fifo (
      .clk (clk),
      .rst (~rstn),
      .data_valid (csr_fifo_data_valid),
      .fifo_read_rd_data (csr_fifo_rd_data),
      .fifo_read_rd_en (csr_to_mem_valid),
      .fifo_almost_full (csr_fifo_almost_full),
      .fifo_write_wr_data (csr_fifo_wr_data),
      .fifo_write_wr_en (csr_valid_i)
      );

   always_comb begin
      csr_fifo_wr_en = rvfi_valid_i;
      
      csr_fifo_wr_data.counter = sync_counter;
      csr_fifo_wr_data.ext_mhpmcounters = rvfi_ext_mhpmcounters_i;
      csr_fifo_wr_data.ext_mhpmcountersh = rvfi_ext_mhpmcountersh_i;
      
      for (int i = 0; i < 10; i ++) begin
         csr_serializer_in_data[i] = csr_fifo_rd_data.ext_mhpmcounters[i*32 +: 32];
         csr_serializer_in_data[10+i] = csr_fifo_rd_data.ext_mhpmcountersh[i*32 +: 32];
      end
      csr_fifo_rd_en  = csr_fifo_data_valid & csr_axis_fifo_ready_i & csr_serializer_ready;
      csr_serializer_in_valid = csr_fifo_rd_en;

      csr_serializer_out_addr[7:$clog2(NUM_CSR_WORDS)] = '0;
   end

   always_ff @(posedge clk) begin
      if (csr_fifo_rd_en) begin
         csr_counter_store    <= csr_fifo_rd_data.counter;
      end
      csr_counter_store_d     <= csr_counter_store;
   end

   csr_serializer #(.NUM_WORDS (NUM_CSR_WORDS), .WIDTH (32)) 
   u_csr (
          .clk (clk),
          .rstn (rstn),
          .data_i (csr_serializer_in_data),
          .valid_i (csr_serializer_in_valid),
          .data_o (csr_serializer_out_data),
          .addr_o (csr_serializer_out_addr[$clog2(NUM_CSR_WORDS)-1:0]),
          .ready_o (csr_serializer_ready),
          .valid_o (csr_serializer_out_valid)
          );

   always_comb begin
      csr_axis_fifo_data_o = {csr_counter_store_d, csr_serializer_out_addr, csr_serializer_out_data};
      csr_axis_fifo_valid_o = csr_serializer_out_valid;
      csr_axis_fifo_keep_o = '1;
   end

   datamover_cmd
     #(.DATA_WIDTH (CSR_WIDTH),
       .LOG2_BUFFER_SIZE (LOG2_BUFFER_SIZE)
       ) u_CSR_dmc
     (
      .clk (clk),
      .rstn (rstn),
      .base_addr (csr_base_addr),
      .hw_idx (csr_hw_idx),
      .sw_idx (csr_sw_idx),
      .fifo_write (csr_axis_fifo_valid_o && csr_axis_fifo_ready_i),
      .flush (flush),
      .m_axis_cmd_tdata (csr_cmd_data_o),
      .m_axis_cmd_tvalid (csr_cmd_valid_o),
      .m_axis_cmd_tready (csr_cmd_ready_i),
      .m_axis_sts_tdata (csr_sts_data_o),
      .m_axis_sts_tvalid (csr_sts_valid_o),
      .m_axis_sts_tready (csr_sts_ready_i)
    );

   
   // Dside stuff
   typedef struct packed {
      logic [23:0] counter;
      logic [3:0]  be;
      logic        store;
      logic        err;
      logic        misaligned_first;
      logic        misaligned_second;
      logic [31:0] addr;
      logic [31:0] store_data;
      logic        misaligned_first_saw_error;
      logic        m_mode_access;
   } dside_data_t;

   dside_data_t  dside_fifo_wr_data;
   dside_data_t  dside_fifo_rd_data;
   logic         dside_fifo_data_valid;
   logic         dside_fifo_almost_full;
   logic         dside_fifo_rd_en;
   logic         dside_fifo_wr_en;

   
   fifo_wrapper #(.WIDTH($bits(dside_data_t)), .DEPTH(16))
   u_disde_fifo (
      .clk (clk),
      .rst (~rstn),
      .data_valid (dside_fifo_data_valid),
      .fifo_read_rd_data (dside_fifo_rd_data),
      .fifo_read_rd_en (dside_to_mem_valid),
      .fifo_almost_full (dside_fifo_almost_full),
      .fifo_write_wr_data (dside_fifo_wr_data),
      .fifo_write_wr_en (dside_valid_i)
      );

   always_comb begin
      dside_fifo_wr_en = dside_access_valid_i;

      dside_fifo_wr_data.counter = sync_counter;
      dside_fifo_wr_data.store = dside_access_store_i;
      dside_fifo_wr_data.addr = dside_access_addr_i;
      dside_fifo_wr_data.be = dside_access_be_i;
      dside_fifo_wr_data.store_data = dside_access_store_data_i;
      dside_fifo_wr_data.err = dside_access_err_i;
      dside_fifo_wr_data.misaligned_first = dside_access_misaligned_first_i;
      dside_fifo_wr_data.misaligned_second = dside_access_misaligned_second_i;
      dside_fifo_wr_data.misaligned_first_saw_error = dside_access_misaligned_first_saw_error_i;
      dside_fifo_wr_data.m_mode_access = dside_access_m_mode_access_i;
      
      dside_fifo_rd_en = dside_fifo_data_valid & dside_axis_fifo_ready_i;

      dside_axis_fifo_data_o = {dside_fifo_rd_data, {(DSIDE_WIDTH-$bits(dside_data_t)){1'b0}}};
      dside_axis_fifo_valid_o = dside_fifo_rd_en;
      dside_axis_fifo_keep_o = '1;
   end

   datamover_cmd
     #(.DATA_WIDTH (DSIDE_WIDTH),
       .LOG2_BUFFER_SIZE (LOG2_BUFFER_SIZE)
       ) u_dside_dmc
     (
      .clk (clk),
      .rstn (rstn),
      .base_addr (dside_base_addr),
      .hw_idx (dside_hw_idx),
      .sw_idx (dside_sw_idx),
      .fifo_write (dside_axis_fifo_valid_o && dside_axis_fifo_ready_i),
      .flush (flush),
      .m_axis_cmd_tdata (dside_cmd_data_o),
      .m_axis_cmd_tvalid (dside_cmd_valid_o),
      .m_axis_cmd_tready (dside_cmd_ready_i),
      .m_axis_sts_tdata (dside_sts_data_o),
      .m_axis_sts_tvalid (dside_sts_valid_o),
      .m_axis_sts_tready (dside_sts_ready_i)
    );

   // always_comb busy_o = rvfi_fifo_almost_full | csr_fifo_almost_full | dside_fifo_almost_full;
   always_comb busy_o = 0;
   
endmodule
