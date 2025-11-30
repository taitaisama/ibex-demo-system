set devicePart "xcve2302-sfva784-1LP-e-s"

proc create_fifo_design { parentCell depth width design_name } {

  create_bd_design $design_name
  current_bd_design $design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set fifo_read [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:fifo_read_rtl:1.0 fifo_read ]

  set fifo_write [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:fifo_write_rtl:1.0 fifo_write ]


  # Create ports
  set clk [ create_bd_port -dir I -type clk -freq_hz 150000000 clk ]
  set rst [ create_bd_port -dir I -type rst rst ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $rst
  set data_valid [ create_bd_port -dir O data_valid ]
  set fifo_wr_busy [ create_bd_port -dir O fifo_wr_busy ]
  set fifo_almost_full [ create_bd_port -dir O fifo_almost_full ]

  set full_thresh [expr {$depth - 5}]

  # Create instance: emb_fifo_gen_0, and set properties
  set emb_fifo_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_fifo_gen:1.0 emb_fifo_gen_0 ]
  set_property -dict [list \
    CONFIG.ENABLE_ALMOST_EMPTY {false} \
    CONFIG.ENABLE_ALMOST_FULL {false} \
    CONFIG.ENABLE_DATA_COUNT {false} \
    CONFIG.ENABLE_OVERFLOW {false} \
    CONFIG.ENABLE_PROGRAMMABLE_EMPTY {false} \
    CONFIG.ENABLE_PROGRAMMABLE_FULL {true} \
    CONFIG.ENABLE_UNDERFLOW {false} \
    CONFIG.ENABLE_WRITE_ACK {false} \
    CONFIG.FIFO_WRITE_DEPTH $depth \
    CONFIG.PROG_FULL_THRESH $full_thresh \
    CONFIG.READ_MODE {FWFT} \
    CONFIG.WRITE_DATA_WIDTH $width \
  ] $emb_fifo_gen_0


  # Create interface connections
  connect_bd_intf_net -intf_net fifo_read_1 [get_bd_intf_ports fifo_read] [get_bd_intf_pins emb_fifo_gen_0/FIFO_READ]
  connect_bd_intf_net -intf_net fifo_write_1 [get_bd_intf_ports fifo_write] [get_bd_intf_pins emb_fifo_gen_0/FIFO_WRITE]

  # Create port connections
  connect_bd_net -net clk_1  [get_bd_ports clk] \
  [get_bd_pins emb_fifo_gen_0/wr_clk]
  connect_bd_net -net emb_fifo_gen_0_data_valid  [get_bd_pins emb_fifo_gen_0/data_valid] \
  [get_bd_ports data_valid]
  connect_bd_net -net emb_fifo_gen_0_prog_full  [get_bd_pins emb_fifo_gen_0/prog_full] \
  [get_bd_ports fifo_almost_full]
  connect_bd_net -net emb_fifo_gen_0_wr_rst_busy  [get_bd_pins emb_fifo_gen_0/wr_rst_busy] \
  [get_bd_ports fifo_wr_busy]
  connect_bd_net -net rst_1  [get_bd_ports rst] \
  [get_bd_pins emb_fifo_gen_0/rst]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design

  set wrapper_file [make_wrapper -files [get_files $design_name.bd] -top]
  add_files $wrapper_file
  update_compile_order -fileset sources_1
}

proc create_ps_io_design { } {

  set_property source_mgmt_mode All [current_project]
  update_compile_order -fileset sources_1

  variable design_name

  set design_name ps_io
  create_bd_design $design_name
  current_bd_design $design_name

  set parentCell [get_bd_cells /]

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set S_AXI [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {1} \
   CONFIG.HAS_LOCK {1} \
   CONFIG.HAS_PROT {1} \
   CONFIG.HAS_QOS {1} \
   CONFIG.HAS_REGION {1} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {16} \
   CONFIG.MAX_BURST_LENGTH {256} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {1} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $S_AXI

  set csr_ctrl [ create_bd_intf_port -mode Master -vlnv ibex:user:stream_ctrl_rtl:1.0 csr_ctrl ]

  set rvfi_ctrl [ create_bd_intf_port -mode Master -vlnv ibex:user:stream_ctrl_rtl:1.0 rvfi_ctrl ]

  set dside_ctrl [ create_bd_intf_port -mode Master -vlnv ibex:user:stream_ctrl_rtl:1.0 dside_ctrl ]


  # Create ports
  set clk [ create_bd_port -dir I -type clk -freq_hz 100000000 clk ]
  set rstn [ create_bd_port -dir I -type rst rstn ]
  set flush [ create_bd_port -dir O -from 0 -to 0 flush ]
  set ps_rstn [ create_bd_port -dir O -from 0 -to 0 ps_rstn ]
  set prog_addr [ create_bd_port -dir O -from 31 -to 0 prog_addr ]

  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]
  set_property -dict [list \
    CONFIG.NUM_MI {6} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_0


  # Create instance: ctrl, and set properties
  set ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 ctrl ]
  set_property -dict [list \
    CONFIG.C_ALL_INPUTS_2 {0} \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_ALL_OUTPUTS_2 {1} \
    CONFIG.C_GPIO2_WIDTH {1} \
    CONFIG.C_GPIO_WIDTH {1} \
    CONFIG.C_IS_DUAL {1} \
  ] $ctrl


  # Create instance: rvfi_idx, and set properties
  set rvfi_idx [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 rvfi_idx ]
  set_property -dict [list \
    CONFIG.C_ALL_INPUTS {1} \
    CONFIG.C_ALL_INPUTS_2 {0} \
    CONFIG.C_ALL_OUTPUTS_2 {1} \
    CONFIG.C_GPIO_WIDTH {32} \
    CONFIG.C_IS_DUAL {1} \
  ] $rvfi_idx


  # Create instance: csr_idx, and set properties
  set csr_idx [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 csr_idx ]
  set_property -dict [list \
    CONFIG.C_ALL_INPUTS {1} \
    CONFIG.C_ALL_INPUTS_2 {0} \
    CONFIG.C_ALL_OUTPUTS_2 {1} \
    CONFIG.C_GPIO_WIDTH {32} \
    CONFIG.C_IS_DUAL {1} \
  ] $csr_idx


  # Create instance: dside_idx, and set properties
  set dside_idx [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 dside_idx ]
  set_property -dict [list \
    CONFIG.C_ALL_INPUTS {1} \
    CONFIG.C_ALL_INPUTS_2 {0} \
    CONFIG.C_ALL_OUTPUTS_2 {1} \
    CONFIG.C_GPIO_WIDTH {32} \
    CONFIG.C_IS_DUAL {1} \
  ] $dside_idx


  # Create instance: addr2, and set properties
  set addr2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 addr2 ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_ALL_OUTPUTS_2 {1} \
    CONFIG.C_GPIO_WIDTH {32} \
    CONFIG.C_IS_DUAL {1} \
  ] $addr2


  # Create instance: addr1, and set properties
  set addr1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 addr1 ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_ALL_OUTPUTS_2 {1} \
    CONFIG.C_GPIO_WIDTH {32} \
    CONFIG.C_IS_DUAL {1} \
  ] $addr1


  # Create instance: csr_ctrl_bridge, and set properties
  set block_name stream_ctrl_bridge
  set block_cell_name csr_ctrl_bridge
  if { [catch {set csr_ctrl_bridge [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $csr_ctrl_bridge eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: rvfi_ctrl_bridge, and set properties
  set block_name stream_ctrl_bridge
  set block_cell_name rvfi_ctrl_bridge
  if { [catch {set rvfi_ctrl_bridge [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $rvfi_ctrl_bridge eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: dside_ctrl_bridge, and set properties
  set block_name stream_ctrl_bridge
  set block_cell_name dside_ctrl_bridge
  if { [catch {set dside_ctrl_bridge [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dside_ctrl_bridge eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create interface connections
  connect_bd_intf_net -intf_net S_AXI_1 [get_bd_intf_ports S_AXI] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net dside_ctrl_bridge_ctrl_out [get_bd_intf_ports dside_ctrl] [get_bd_intf_pins dside_ctrl_bridge/ctrl_out]
  connect_bd_intf_net -intf_net rvfi_ctrl_bridge_ctrl_out [get_bd_intf_ports rvfi_ctrl] [get_bd_intf_pins rvfi_ctrl_bridge/ctrl_out]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins ctrl/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins smartconnect_0/M01_AXI] [get_bd_intf_pins csr_idx/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M02_AXI [get_bd_intf_pins smartconnect_0/M02_AXI] [get_bd_intf_pins addr2/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M03_AXI [get_bd_intf_pins smartconnect_0/M03_AXI] [get_bd_intf_pins rvfi_idx/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M04_AXI [get_bd_intf_pins smartconnect_0/M04_AXI] [get_bd_intf_pins addr1/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M05_AXI [get_bd_intf_pins smartconnect_0/M05_AXI] [get_bd_intf_pins dside_idx/S_AXI]
  connect_bd_intf_net -intf_net stream_ctrl_bridge_0_ctrl_out [get_bd_intf_ports csr_ctrl] [get_bd_intf_pins csr_ctrl_bridge/ctrl_out]

  # Create port connections
  connect_bd_net -net addr1_gpio2_io_o  [get_bd_pins addr1/gpio2_io_o] \
  [get_bd_pins rvfi_ctrl_bridge/ctrl_in_baseaddr]
  connect_bd_net -net addr2_gpio2_io_o  [get_bd_pins addr2/gpio2_io_o] \
  [get_bd_pins dside_ctrl_bridge/ctrl_in_baseaddr]
  connect_bd_net -net addr2_gpio_io_o  [get_bd_pins addr2/gpio_io_o] \
  [get_bd_pins csr_ctrl_bridge/ctrl_in_baseaddr]
  connect_bd_net -net clk_1  [get_bd_ports clk] \
  [get_bd_pins smartconnect_0/aclk] \
  [get_bd_pins csr_idx/s_axi_aclk] \
  [get_bd_pins ctrl/s_axi_aclk] \
  [get_bd_pins rvfi_idx/s_axi_aclk] \
  [get_bd_pins addr2/s_axi_aclk] \
  [get_bd_pins addr1/s_axi_aclk] \
  [get_bd_pins dside_idx/s_axi_aclk]
  connect_bd_net -net csr_ctrl_bridge_0_ctrl_in_hwidx  [get_bd_pins csr_ctrl_bridge/ctrl_in_hwidx] \
  [get_bd_pins csr_idx/gpio_io_i]
  connect_bd_net -net csr_idx_gpio2_io_o  [get_bd_pins csr_idx/gpio2_io_o] \
  [get_bd_pins csr_ctrl_bridge/ctrl_in_swidx]
  connect_bd_net -net dside_ctrl_bridge_ctrl_in_hwidx  [get_bd_pins dside_ctrl_bridge/ctrl_in_hwidx] \
  [get_bd_pins dside_idx/gpio_io_i]
  connect_bd_net -net dside_idx_gpio2_io_o  [get_bd_pins dside_idx/gpio2_io_o] \
  [get_bd_pins dside_ctrl_bridge/ctrl_in_swidx]
  connect_bd_net -net gpi_gpio2_io_o  [get_bd_pins ctrl/gpio2_io_o] \
  [get_bd_ports ps_rstn]
  connect_bd_net -net gpi_gpio_io_o  [get_bd_pins ctrl/gpio_io_o] \
  [get_bd_ports flush]
  connect_bd_net -net gpio1_gpio_io_o  [get_bd_pins addr1/gpio_io_o] \
  [get_bd_ports prog_addr]
  connect_bd_net -net rstn_1  [get_bd_ports rstn] \
  [get_bd_pins smartconnect_0/aresetn] \
  [get_bd_pins rvfi_idx/s_axi_aresetn] \
  [get_bd_pins csr_idx/s_axi_aresetn] \
  [get_bd_pins ctrl/s_axi_aresetn] \
  [get_bd_pins addr2/s_axi_aresetn] \
  [get_bd_pins addr1/s_axi_aresetn] \
  [get_bd_pins dside_idx/s_axi_aresetn]
  connect_bd_net -net rvfi_ctrl_bridge_ctrl_in_hwidx  [get_bd_pins rvfi_ctrl_bridge/ctrl_in_hwidx] \
  [get_bd_pins rvfi_idx/gpio_io_i]
  connect_bd_net -net rvfi_idx_gpio2_io_o  [get_bd_pins rvfi_idx/gpio2_io_o] \
  [get_bd_pins rvfi_ctrl_bridge/ctrl_in_swidx]

  # Create address segments
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S_AXI] [get_bd_addr_segs addr1/S_AXI/Reg] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S_AXI] [get_bd_addr_segs dside_idx/S_AXI/Reg] -force
  assign_bd_address -offset 0x80010000 -range 0x00010000 -with_name SEG_ps_ctrl_Reg -target_address_space [get_bd_addr_spaces S_AXI] [get_bd_addr_segs ctrl/S_AXI/Reg] -force
  assign_bd_address -offset 0x80020000 -range 0x00010000 -with_name SEG_rvfi_curr_addrs_Reg -target_address_space [get_bd_addr_spaces S_AXI] [get_bd_addr_segs csr_idx/S_AXI/Reg] -force
  assign_bd_address -offset 0x80030000 -range 0x00010000 -with_name SEG_rvfi_end_addrs_Reg -target_address_space [get_bd_addr_spaces S_AXI] [get_bd_addr_segs addr2/S_AXI/Reg] -force
  assign_bd_address -offset 0x80040000 -range 0x00010000 -with_name SEG_rvfi_start_addrs_Reg -target_address_space [get_bd_addr_spaces S_AXI] [get_bd_addr_segs rvfi_idx/S_AXI/Reg] -force

  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design

  update_compile_order -fileset sources_1
}
# End of create_root_design()



set dir_path [lindex $argv 0]

set_property  ip_repo_paths  [list "$dir_path/rtl/fpga/versal_ip/intf_ip" "$dir_path/build/ip_repo"] [current_project]

create_ps_io_design
create_fifo_design "" 128 4 "fifo_4_128"
create_fifo_design "" 128 6 "fifo_6_128"
create_fifo_design "" 128 32 "fifo_32_128"
create_fifo_design "" 128 40 "fifo_40_128"
create_fifo_design "" 128 69 "fifo_69_128"
create_fifo_design "" 16 98 "fifo_98_16"
create_fifo_design "" 16 664 "fifo_664_16"
create_fifo_design "" 16 227 "fifo_227_16"
