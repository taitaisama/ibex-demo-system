`default_nettype none
`timescale 1ns/1ps

module tb;
   logic clk = 0;
   logic rstn = 0;

   localparam logic [7:0] max_counter = 8'd200;

   localparam int	  OUT_WIDTH = 208;
   localparam int	  CSR_WIDTH = 104;

   logic [7:0] counter = 0;

   logic        rvfi_valid = 0;
   logic	rvfi_trap = 0;
   logic [ 4:0]	rvfi_rd_addr = 'b11001;
   logic [31:0]	rvfi_rd_wdata = 'd999;
   logic [31:0]	rvfi_pc_rdata = 'd897;
   logic [31:0]	rvfi_ext_pre_mip = 'd3423;
   logic [31:0]	rvfi_ext_post_mip = 'd1023998;
   logic	rvfi_ext_nmi = 0;
   logic	rvfi_ext_nmi_int = 0;
   logic	rvfi_ext_debug_req = 0;
   logic	rvfi_ext_rf_wr_suppress = 0;
   logic [63:0]	rvfi_ext_mcycle = 1000;
   logic [31:0]	rvfi_ext_mhpmcounters [10];   
   logic [31:0]	rvfi_ext_mhpmcountersh [10];
   logic	rvfi_ext_ic_scr_key_valid = 0;

   logic [OUT_WIDTH-1:0]        rvfi_tdata;
   logic			rvfi_tvalid;
   logic			rvfi_tready;
   
   logic [CSR_WIDTH-1:0]	rvfi_csr_tdata;
   logic			rvfi_csr_tvalid;
   logic			rvfi_csr_tready;


   assign rvfi_tready = 1;
   assign rvfi_csr_tready = 1;

   logic [202:0]		acc_data;

   always_comb acc_data = {rvfi_trap, rvfi_rd_addr, rvfi_rd_wdata, rvfi_pc_rdata, rvfi_ext_pre_mip, rvfi_ext_post_mip, rvfi_ext_nmi, rvfi_ext_nmi_int, rvfi_ext_debug_req, rvfi_ext_rf_wr_suppress, rvfi_ext_mcycle, rvfi_ext_ic_scr_key_valid};

   
   logic [1:0]	rvfi_num_csrs = 0;
   
   logic [4:0]	rvfi_csr_1 = 0;
   logic [4:0]	rvfi_csr_2 = 0;
   logic [4:0]	rvfi_csr_3 = 0;

   logic	rvfi_ready;
   
   // Clock generation
   always #5 clk = ~clk; // 100MHz

   always @(posedge clk) begin
      rvfi_valid <= rvfi_ready && (counter < max_counter) && rstn;

      rvfi_trap <= rvfi_rd_addr[0] ^ rvfi_ext_nmi;
      rvfi_rd_addr <= ((~rvfi_rd_addr) + 'd23) ^ rvfi_pc_rdata[4:0];
      rvfi_rd_wdata <= ((~rvfi_rd_wdata) + 'd32575) ^ rvfi_ext_pre_mip ^ rvfi_ext_mcycle[31:0];
      rvfi_pc_rdata <= ((~rvfi_pc_rdata) + 'd2349870) ^ rvfi_rd_wdata;
      rvfi_ext_pre_mip <= ((~rvfi_ext_pre_mip) + 'd34237836) ^ rvfi_ext_post_mip;
      rvfi_ext_post_mip <= ((~rvfi_ext_post_mip) + 'd10239989) ^ rvfi_ext_mcycle[63:32];
      rvfi_ext_nmi <= rvfi_pc_rdata[0] ^ rvfi_ext_post_mip[11];
      rvfi_ext_nmi_int <= rvfi_ext_nmi ^ rvfi_trap;
      rvfi_ext_debug_req <= rvfi_ext_nmi_int ^ rvfi_ext_debug_req ^ rvfi_ext_rf_wr_suppress;
      rvfi_ext_rf_wr_suppress <= rvfi_pc_rdata[13];
      rvfi_ext_mcycle <= (~rvfi_ext_mcycle + 'd349870) ^ {rvfi_pc_rdata, rvfi_rd_wdata};
      rvfi_ext_ic_scr_key_valid <=  ~rvfi_ext_nmi_int ^ rvfi_pc_rdata[15];
      rvfi_num_csrs <= 2'b01; // rvfi_ext_pre_mip[4:3];

      rvfi_csr_1 <= rvfi_ext_pre_mip[5:1];
      rvfi_csr_2 <= rvfi_ext_pre_mip[10:6];
      rvfi_csr_3 <= rvfi_ext_pre_mip[18:14];

      if (rvfi_num_csrs >= 2'b01) begin
	 if (rvfi_csr_1 < 10) begin
	    rvfi_ext_mhpmcounters[rvfi_csr_1] <= (~rvfi_ext_mhpmcounters[rvfi_csr_1] + 'd34897) ^ rvfi_ext_post_mip;
	 end else if (rvfi_csr_1 < 20) begin
	    rvfi_ext_mhpmcountersh[rvfi_csr_1-10] <= (~rvfi_ext_mhpmcountersh[rvfi_csr_1-10] + 'd3434098) ^ rvfi_pc_rdata;
	 end
      end 
      if (rvfi_num_csrs >= 2'b10) begin
	 if (rvfi_csr_2 < 10) begin
	    rvfi_ext_mhpmcounters[rvfi_csr_2] <= (~rvfi_ext_mhpmcounters[rvfi_csr_2] + 'd85475) ^ rvfi_ext_post_mip;
	 end else if (rvfi_csr_2 < 20) begin
	    rvfi_ext_mhpmcountersh[rvfi_csr_2-10] <= (~rvfi_ext_mhpmcountersh[rvfi_csr_2-10] + 'd453456) ^ rvfi_pc_rdata;
	 end
      end 
      if (rvfi_num_csrs >= 2'b11) begin
	 if (rvfi_csr_3 < 10) begin
	    rvfi_ext_mhpmcounters[rvfi_csr_3] <= (~rvfi_ext_mhpmcounters[rvfi_csr_3] + 'd85478675) ^ rvfi_ext_post_mip;
	 end else if (rvfi_csr_3 < 20) begin
	    rvfi_ext_mhpmcountersh[rvfi_csr_3-10] <= (~rvfi_ext_mhpmcountersh[rvfi_csr_3-10] + 'd453456348) ^ rvfi_pc_rdata;
	 end
      end

      if (counter < max_counter) begin
	 counter <= counter + 1;
      end
   end

   rvfi_handler u_dut
     (
      .clk (clk),
      .rstn (rstn),

      .rvfi_valid_i (rvfi_valid),
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

      .rdata_o (rvfi_tdata),
      .rvalid_o (rvfi_tvalid),
      .rready_i (rvfi_tready),

      .rdata_csr_o (rvfi_csr_tdata),
      .rvalid_csr_o (rvfi_csr_tvalid),
      .rready_csr_i (rvfi_csr_tready),

      .rvfi_ready_o (rvfi_ready)
      );

   initial begin
      rstn = 0;
      for (int i = 0; i < 10; i ++) begin
	 rvfi_ext_mhpmcounters[i] = 0;
	 rvfi_ext_mhpmcountersh[i] = 0;
      end

      #20 rstn = 1;
      
      #5;

      for (int i = 0; i < 50; i ++) begin
	 $display("data %b\n", acc_data);
	 $display("rvfi_num_csrs %d\n", rvfi_num_csrs);
	 $display("rvfi_csr_1 %d\n", rvfi_csr_1);
	 $display("rvfi_csr_2 %d\n", rvfi_csr_2);
	 $display("rvfi_csr_3 %d\n", rvfi_csr_3);

	 $display("rvfi_tdata %b\n", rvfi_tdata);
	 $display("rvfi_tvalid %b\n", rvfi_tvalid);

	 $display("rvfi_csr_tdata %b\n", rvfi_csr_tdata);
	 $display("rvfi_csr_tvalid %b\n", rvfi_csr_tvalid);
	 
	 #10;
      end
      
      #5;
      #5;
      
      $finish;
   end
   
endmodule
