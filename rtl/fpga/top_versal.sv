// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// This is the top level SystemVerilog file that connects the IO on the board to the Ibex Demo System.
module top_versal #(
  parameter SRAMInitFile = "/home/ritu/dev/work/ibex-demo-system/sw/c/build/demo/hello_world/demo.hex"
) (
  // These inputs are defined in data/pins_artya7.xdc
    input      sys_clk_p,
    input      sys_clk_n,
    input      rst_n,
    output reg led
);

  logic sys_clk;

   IBUFDS IBUFDS_inst (
      .O(sys_clk),   // 1-bit output: Buffer output
      .I(sys_clk_p),   // 1-bit input: Diff_p buffer input (connect directly to top-level port)
      .IB(sys_clk_n)  // 1-bit input: Diff_n buffer input (connect directly to top-level port)
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
    .rst_sys_ni(rst_n),
    .gp_i      (),
    .uart_rx_i (1'b0),

    //output
    .gp_o     (led),
    .pwm_o    (),
    .uart_tx_o(),

    .spi_rx_i (1'b0),
    .spi_tx_o (),
    .spi_sck_o(),

    .trst_ni(1'b1),
    .tms_i  (1'b0),
    .tck_i  (1'b0),
    .td_i   (1'b0),
    .td_o   ()
  );


endmodule
