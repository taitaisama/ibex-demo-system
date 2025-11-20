
// (c) Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// (c) Copyright 2022-2025 Advanced Micro Devices, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of AMD and is protected under U.S. and international copyright
// and other intellectual property laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.


`ifndef ibex_rvfi_v1_0
`define ibex_rvfi_v1_0

interface ibex_rvfi_v1_0();
  logic valid = 0;                                      // 
  logic trap = 0;                                       // 
  logic [4:0] rd_addr = 0;                              // 
  logic [31:0] rd_wdata = 0;                            // 
  logic [31:0] pc_rdata = 0;                            // 
  logic [31:0] ext_pre_mip = 0;                         // 
  logic [31:0] ext_post_mip = 0;                        // 
  logic ext_nmi = 0;                                    // 
  logic ext_nmi_int = 0;                                // 
  logic ext_debug_req = 0;                              // 
  logic ext_rf_wr_suppress = 0;                         // 
  logic [63:0] ext_mcycle = 0;                          // 
  logic [319:0] ext_mhpmcounters = 0;                   // 
  logic [319:0] ext_mhpmcountersh = 0;                  // 
  logic ext_ic_scr_key_valid = 0;                       //
  logic force_stop = 0;                                 //

  modport MASTER (
    input force_stop,
    output valid, trap, rd_addr, rd_wdata, pc_rdata, ext_pre_mip, ext_post_mip, ext_nmi, ext_nmi_int, ext_debug_req, ext_rf_wr_suppress, ext_mcycle, ext_mhpmcounters, ext_mhpmcountersh, ext_ic_scr_key_valid
    );

  modport SLAVE (
    input valid, trap, rd_addr, rd_wdata, pc_rdata, ext_pre_mip, ext_post_mip, ext_nmi, ext_nmi_int, ext_debug_req, ext_rf_wr_suppress, ext_mcycle, ext_mhpmcounters, ext_mhpmcountersh, ext_ic_scr_key_valid,
    output force_stop
    );

  modport MONITOR (
    input valid, trap, rd_addr, rd_wdata, pc_rdata, ext_pre_mip, ext_post_mip, ext_nmi, ext_nmi_int, ext_debug_req, ext_rf_wr_suppress, ext_mcycle, ext_mhpmcounters, ext_mhpmcountersh, ext_ic_scr_key_valid, force_stop
    );

endinterface // ibex_rvfi_v1_0

`endif
