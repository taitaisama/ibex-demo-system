
`timescale 1 ns / 1 ps

module ps_io2_wrapper #
  (
   // Users to add parameters here

   // User parameters ends
   // Do not modify the parameters beyond this line


   // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 6
   )
   (
    // Users to add ports here

    // User ports ends
    // Do not modify the ports beyond this line


    // Ports of Axi Slave Bus Interface S00_AXI
     input                                  s00_axi_aclk,
     input                                  s00_axi_aresetn,
     input [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_awaddr,
     input [2 : 0]                          s00_axi_awprot,
     input                                  s00_axi_awvalid,
     output                                 s00_axi_awready,
     input [C_S00_AXI_DATA_WIDTH-1 : 0]     s00_axi_wdata,
     input [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
     input                                  s00_axi_wvalid,
     output                                 s00_axi_wready,
     output [1 : 0]                         s00_axi_bresp,
     output                                 s00_axi_bvalid,
     input                                  s00_axi_bready,
     input [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_araddr,
     input [2 : 0]                          s00_axi_arprot,
     input                                  s00_axi_arvalid,
     output                                 s00_axi_arready,
     output [C_S00_AXI_DATA_WIDTH-1 : 0]    s00_axi_rdata,
     output [1 : 0]                         s00_axi_rresp,
     output                                 s00_axi_rvalid,
     input                                  s00_axi_rready,
   
     input [C_S00_AXI_DATA_WIDTH-1:0]       debug1,
     input [C_S00_AXI_DATA_WIDTH-1:0]       debug2,
     input [C_S00_AXI_DATA_WIDTH-1:0]       debug3,
     input [C_S00_AXI_DATA_WIDTH-1:0]       debug4,

     output [C_S00_AXI_DATA_WIDTH-1:0]      prog_addr,
     output                                 sys_rstn,
     output                                 sys_flush,

     output [C_S00_AXI_DATA_WIDTH-1:0]      rvfi_swidx,
     input [C_S00_AXI_DATA_WIDTH-1:0]       rvfi_hwidx,
     output [C_S00_AXI_DATA_WIDTH-1:0]      rvfi_baseaddr,

     output [C_S00_AXI_DATA_WIDTH-1:0]      csr_swidx,
     input [C_S00_AXI_DATA_WIDTH-1:0]       csr_hwidx,
     output [C_S00_AXI_DATA_WIDTH-1:0]      csr_baseaddr,
   
     output [C_S00_AXI_DATA_WIDTH-1:0]      dside_swidx,
     input [C_S00_AXI_DATA_WIDTH-1:0]       dside_hwidx,
     output [C_S00_AXI_DATA_WIDTH-1:0]      dside_baseaddr
    );
   // Instantiation of Axi Bus Interface S00_AXI
   ps_io2 # ( 
	     .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
	     .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
   ) ps_io_inst (
		 .S_AXI_ACLK(s00_axi_aclk),
		 .S_AXI_ARESETN(s00_axi_aresetn),
		 .S_AXI_AWADDR(s00_axi_awaddr),
		 .S_AXI_AWPROT(s00_axi_awprot),
		 .S_AXI_AWVALID(s00_axi_awvalid),
		 .S_AXI_AWREADY(s00_axi_awready),
		 .S_AXI_WDATA(s00_axi_wdata),
		 .S_AXI_WSTRB(s00_axi_wstrb),
		 .S_AXI_WVALID(s00_axi_wvalid),
		 .S_AXI_WREADY(s00_axi_wready),
		 .S_AXI_BRESP(s00_axi_bresp),
		 .S_AXI_BVALID(s00_axi_bvalid),
		 .S_AXI_BREADY(s00_axi_bready),
		 .S_AXI_ARADDR(s00_axi_araddr),
		 .S_AXI_ARPROT(s00_axi_arprot),
		 .S_AXI_ARVALID(s00_axi_arvalid),
		 .S_AXI_ARREADY(s00_axi_arready),
		 .S_AXI_RDATA(s00_axi_rdata),
		 .S_AXI_RRESP(s00_axi_rresp),
		 .S_AXI_RVALID(s00_axi_rvalid),
		 .S_AXI_RREADY(s00_axi_rready),

                 .debug1(debug1),
                 .debug2(debug2),
                 .debug3(debug3),
                 .debug4(debug4),
                 
                 .prog_addr(prog_addr),
                 .sys_rstn(sys_rstn),
                 .sys_flush(sys_flush),

                 .rvfi_swidx(rvfi_swidx),
                 .rvfi_hwidx(rvfi_hwidx),
                 .rvfi_baseaddr(rvfi_baseaddr),

                 .csr_swidx(csr_swidx),
                 .csr_hwidx(csr_hwidx),
                 .csr_baseaddr(csr_baseaddr),
                 
                 .dside_swidx(dside_swidx),
                 .dside_hwidx(dside_hwidx),
                 .dside_baseaddr(dside_baseaddr)
   );

endmodule
