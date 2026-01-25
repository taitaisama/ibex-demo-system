set devicePart "xcve2302-sfva784-1LP-e-s"

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
    catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" "This script should be run inside an opened project"}
}


proc create_ps_io_design { parentCell } {

  variable design_name

  set design_name ps_io
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
  set S_AXI [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.ARUSER_WIDTH {16} \
   CONFIG.AWUSER_WIDTH {16} \
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


  # Create ports
  set clk [ create_bd_port -dir I -type clk -freq_hz 100000000 clk ]
  set rstn [ create_bd_port -dir I -type rst rstn ]
  set flush_rvfi [ create_bd_port -dir O -from 0 -to 0 flush_rvfi ]
  set ps_rstn [ create_bd_port -dir O -from 0 -to 0 ps_rstn ]
  set rvfi_sw_idx [ create_bd_port -dir O -from 31 -to 0 rvfi_sw_idx ]
  set rvfi_csr_sw_idx [ create_bd_port -dir O -from 31 -to 0 rvfi_csr_sw_idx ]
  set rvfi_base_addr [ create_bd_port -dir O -from 31 -to 0 rvfi_base_addr ]
  set rvfi_csr_base_addr [ create_bd_port -dir O -from 31 -to 0 rvfi_csr_base_addr ]
  set prog_addr [ create_bd_port -dir O -from 31 -to 0 prog_addr ]
  set rvfi_hw_idx [ create_bd_port -dir I -from 31 -to 0 rvfi_hw_idx ]
  set rvfi_csr_hw_idx [ create_bd_port -dir I -from 31 -to 0 rvfi_csr_hw_idx ]

  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]
  set_property -dict [list \
    CONFIG.NUM_MI {4} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_0


  # Create instance: ibex_ctrl, and set properties
  set ibex_ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 ibex_ctrl ]
  set_property -dict [list \
    CONFIG.C_ALL_INPUTS_2 {0} \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_ALL_OUTPUTS_2 {1} \
    CONFIG.C_GPIO2_WIDTH {32} \
    CONFIG.C_GPIO_WIDTH {2} \
    CONFIG.C_IS_DUAL {1} \
  ] $ibex_ctrl


  # Create instance: sw_idx, and set properties
  set sw_idx [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 sw_idx ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_ALL_OUTPUTS_2 {1} \
    CONFIG.C_GPIO_WIDTH {32} \
    CONFIG.C_IS_DUAL {1} \
  ] $sw_idx


  # Create instance: rvfi_base_addrs, and set properties
  set rvfi_base_addrs [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 rvfi_base_addrs ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_ALL_OUTPUTS_2 {1} \
    CONFIG.C_GPIO_WIDTH {32} \
    CONFIG.C_IS_DUAL {1} \
  ] $rvfi_base_addrs


  # Create instance: hw_idx, and set properties
  set hw_idx [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 hw_idx ]
  set_property -dict [list \
    CONFIG.C_ALL_INPUTS {1} \
    CONFIG.C_ALL_INPUTS_2 {1} \
    CONFIG.C_GPIO_WIDTH {32} \
    CONFIG.C_IS_DUAL {1} \
  ] $hw_idx


  # Create instance: ilslice_0, and set properties
  set ilslice_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice:1.0 ilslice_0 ]
  set_property CONFIG.DIN_WIDTH {2} $ilslice_0


  # Create instance: ilslice_1, and set properties
  set ilslice_1 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice:1.0 ilslice_1 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {1} \
    CONFIG.DIN_TO {1} \
    CONFIG.DIN_WIDTH {2} \
  ] $ilslice_1


  # Create interface connections
  connect_bd_intf_net -intf_net S_AXI_1 [get_bd_intf_ports S_AXI] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins ibex_ctrl/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins smartconnect_0/M01_AXI] [get_bd_intf_pins hw_idx/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M02_AXI [get_bd_intf_pins smartconnect_0/M02_AXI] [get_bd_intf_pins rvfi_base_addrs/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M03_AXI [get_bd_intf_pins smartconnect_0/M03_AXI] [get_bd_intf_pins sw_idx/S_AXI]

  # Create port connections
  connect_bd_net -net clk_1  [get_bd_ports clk] \
  [get_bd_pins smartconnect_0/aclk] \
  [get_bd_pins hw_idx/s_axi_aclk] \
  [get_bd_pins ibex_ctrl/s_axi_aclk] \
  [get_bd_pins rvfi_base_addrs/s_axi_aclk] \
  [get_bd_pins sw_idx/s_axi_aclk]
  connect_bd_net -net ibex_ctrl_gpio2_io_o  [get_bd_pins ibex_ctrl/gpio2_io_o] \
  [get_bd_ports prog_addr]
  connect_bd_net -net ilslice_0_Dout  [get_bd_pins ilslice_0/Dout] \
  [get_bd_ports flush_rvfi]
  connect_bd_net -net ilslice_1_Dout  [get_bd_pins ilslice_1/Dout] \
  [get_bd_ports ps_rstn]
  connect_bd_net -net ps_ctrl_gpio_io_o  [get_bd_pins ibex_ctrl/gpio_io_o] \
  [get_bd_pins ilslice_0/Din] \
  [get_bd_pins ilslice_1/Din]
  connect_bd_net -net rstn_1  [get_bd_ports rstn] \
  [get_bd_pins smartconnect_0/aresetn] \
  [get_bd_pins sw_idx/s_axi_aresetn] \
  [get_bd_pins rvfi_base_addrs/s_axi_aresetn] \
  [get_bd_pins hw_idx/s_axi_aresetn] \
  [get_bd_pins ibex_ctrl/s_axi_aresetn]
  connect_bd_net -net rvfi_csr_curr_addr_1  [get_bd_ports rvfi_csr_hw_idx] \
  [get_bd_pins hw_idx/gpio2_io_i]
  connect_bd_net -net rvfi_curr_addr_1  [get_bd_ports rvfi_hw_idx] \
  [get_bd_pins hw_idx/gpio_io_i]
  connect_bd_net -net rvfi_end_addrs_gpio2_io_o  [get_bd_pins rvfi_base_addrs/gpio2_io_o] \
  [get_bd_ports rvfi_csr_base_addr]
  connect_bd_net -net rvfi_end_addrs_gpio_io_o  [get_bd_pins rvfi_base_addrs/gpio_io_o] \
  [get_bd_ports rvfi_base_addr]
  connect_bd_net -net rvfi_start_addrs_gpio2_io_o  [get_bd_pins sw_idx/gpio2_io_o] \
  [get_bd_ports rvfi_csr_sw_idx]
  connect_bd_net -net rvfi_start_addrs_gpio_io_o  [get_bd_pins sw_idx/gpio_io_o] \
  [get_bd_ports rvfi_sw_idx]

  # Create address segments
  assign_bd_address -offset 0x80010000 -range 0x00010000 -with_name SEG_ps_ctrl_Reg -target_address_space [get_bd_addr_spaces S_AXI] [get_bd_addr_segs ibex_ctrl/S_AXI/Reg] -force
  assign_bd_address -offset 0x80020000 -range 0x00010000 -with_name SEG_rvfi_curr_addrs_Reg -target_address_space [get_bd_addr_spaces S_AXI] [get_bd_addr_segs hw_idx/S_AXI/Reg] -force
  assign_bd_address -offset 0x80030000 -range 0x00010000 -with_name SEG_rvfi_end_addrs_Reg -target_address_space [get_bd_addr_spaces S_AXI] [get_bd_addr_segs rvfi_base_addrs/S_AXI/Reg] -force
  assign_bd_address -offset 0x80040000 -range 0x00010000 -with_name SEG_rvfi_start_addrs_Reg -target_address_space [get_bd_addr_spaces S_AXI] [get_bd_addr_segs sw_idx/S_AXI/Reg] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
  
  set wrapper_file [make_wrapper -files [get_files $design_name.bd] -top]
  add_files $wrapper_file
  update_compile_order -fileset sources_1
}
# End of create_root_design()



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable design_name

  set design_name ps_subsystem
  create_bd_design $design_name
  current_bd_design $design_name

  set DEBUG_WIDTH 128

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
  set DDR4 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 DDR4 ]

  set sys [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sys ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
   ] $sys


  # Create ports
  set led [ create_bd_port -dir O led ]

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:3.4 versal_cips_0 ]
  set_property -dict [list \
    CONFIG.BOOT_MODE {Custom} \
    CONFIG.DDR_MEMORY_MODE {Custom} \
    CONFIG.DESIGN_MODE {1} \
    CONFIG.IO_CONFIG_MODE {Custom} \
    CONFIG.PS_PL_CONNECTIVITY_MODE {Custom} \
    CONFIG.PS_PMC_CONFIG { \
      BOOT_MODE {Custom} \
      DDR_MEMORY_MODE {Connectivity to DDR via NOC} \
      DESIGN_MODE {1} \
      IO_CONFIG_MODE {Custom} \
      PMC_GPIO_EMIO_PERIPHERAL_ENABLE {0} \
      PMC_I2CPMC_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 2 .. 3}}} \
      PMC_QSPI_FBCLK {{ENABLE 1} {IO {PMC_MIO 6}}} \
      PMC_QSPI_PERIPHERAL_DATA_MODE {x4} \
      PMC_QSPI_PERIPHERAL_ENABLE {1} \
      PMC_QSPI_PERIPHERAL_MODE {Dual Parallel} \
      PMC_REF_CLK_FREQMHZ {33.333333} \
      PMC_SD0_DATA_TRANSFER_MODE {8Bit} \
      PMC_SD0_PERIPHERAL {{CLK_100_SDR_OTAP_DLY 0x00} {CLK_200_SDR_OTAP_DLY 0x2} {CLK_50_DDR_ITAP_DLY 0x1E} {CLK_50_DDR_OTAP_DLY 0x5} {CLK_50_SDR_ITAP_DLY 0x2C} {CLK_50_SDR_OTAP_DLY 0x5} {ENABLE 1} {IO\
{PMC_MIO 37 .. 49}}} \
      PMC_SD0_SLOT_TYPE {eMMC} \
      PMC_SD1_PERIPHERAL {{CLK_100_SDR_OTAP_DLY 0x00} {CLK_200_SDR_OTAP_DLY 0x00} {CLK_50_DDR_ITAP_DLY 0x00} {CLK_50_DDR_OTAP_DLY 0x00} {CLK_50_SDR_ITAP_DLY 0x2C} {CLK_50_SDR_OTAP_DLY 0x4} {ENABLE 1} {IO\
{PMC_MIO 26 .. 36}}} \
      PMC_USE_PMC_NOC_AXI0 {1} \
      PS_BOARD_INTERFACE {Custom} \
      PS_CAN0_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 8 .. 9}}} \
      PS_ENET0_MDIO {{ENABLE 1} {IO {PMC_MIO 50 .. 51}}} \
      PS_ENET0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 0 .. 11}}} \
      PS_ENET1_MDIO {{ENABLE 0} {IO {PMC_MIO 50 .. 51}}} \
      PS_ENET1_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 38 .. 49}}} \
      PS_GEN_IPI0_ENABLE {1} \
      PS_GEN_IPI1_ENABLE {1} \
      PS_GEN_IPI2_ENABLE {1} \
      PS_GEN_IPI3_ENABLE {1} \
      PS_GEN_IPI4_ENABLE {1} \
      PS_GEN_IPI5_ENABLE {1} \
      PS_GEN_IPI6_ENABLE {1} \
      PS_GPIO_EMIO_PERIPHERAL_ENABLE {0} \
      PS_I2C0_PERIPHERAL {{ENABLE 0} {IO {PS_MIO 2 .. 3}}} \
      PS_I2C1_PERIPHERAL {{ENABLE 0} {IO {PS_MIO 0 .. 1}}} \
      PS_NUM_FABRIC_RESETS {1} \
      PS_PL_CONNECTIVITY_MODE {Custom} \
      PS_TTC0_PERIPHERAL_ENABLE {1} \
      PS_TTC1_PERIPHERAL_ENABLE {1} \
      PS_TTC2_PERIPHERAL_ENABLE {1} \
      PS_TTC3_PERIPHERAL_ENABLE {1} \
      PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 16 .. 17}}} \
      PS_USB3_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 13 .. 25}}} \
      PS_USE_FPD_CCI_NOC {1} \
      PS_USE_FPD_CCI_NOC0 {1} \
      PS_USE_M_AXI_LPD {1} \
      PS_USE_NOC_LPD_AXI0 {1} \
      PS_USE_PMCPL_CLK0 {0} \
      PS_USE_PMCPL_CLK1 {0} \
      PS_USE_PMCPL_CLK2 {0} \
      PS_USE_PMCPL_CLK3 {0} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_ENABLE_TEMP_AVERAGING {0} \
      SMON_TEMP_AVERAGING_SAMPLES {0} \
    } \
  ] $versal_cips_0


  # Create instance: axi_noc_0, and set properties
  set axi_noc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:1.1 axi_noc_0 ]
  set_property -dict [list \
    CONFIG.CONTROLLERTYPE {DDR4_SDRAM} \
    CONFIG.MC_CASLATENCY {22} \
    CONFIG.MC_CHAN_REGION1 {NONE} \
    CONFIG.MC_COMPONENT_WIDTH {x16} \
    CONFIG.MC_ECC_SCRUB_SIZE {4096} \
    CONFIG.MC_F1_TFAW {30000} \
    CONFIG.MC_F1_TFAWMIN {30000} \
    CONFIG.MC_F1_TRCD {13750} \
    CONFIG.MC_F1_TRCDMIN {13750} \
    CONFIG.MC_F1_TRRD_L {11} \
    CONFIG.MC_F1_TRRD_L_MIN {11} \
    CONFIG.MC_F1_TRRD_S {9} \
    CONFIG.MC_F1_TRRD_S_MIN {9} \
    CONFIG.MC_INPUTCLK0_PERIOD {5000} \
    CONFIG.MC_MEMORY_SPEEDGRADE {DDR4-3200AA(22-22-22)} \
    CONFIG.MC_SYSTEM_CLOCK {No_Buffer} \
    CONFIG.MC_TFAW {30000} \
    CONFIG.MC_TFAWMIN {30000} \
    CONFIG.MC_TRC {45750} \
    CONFIG.MC_TRCD {13750} \
    CONFIG.MC_TRCDMIN {13750} \
    CONFIG.MC_TRCMIN {45750} \
    CONFIG.MC_TRP {13750} \
    CONFIG.MC_TRPMIN {13750} \
    CONFIG.MC_TRRD_L {11} \
    CONFIG.MC_TRRD_L_MIN {11} \
    CONFIG.MC_TRRD_S {9} \
    CONFIG.MC_TRRD_S_MIN {9} \
    CONFIG.MC_USER_DEFINED_ADDRESS_MAP {16RA-2BA-1BG-10CA} \
    CONFIG.MI_SIDEBAND_PINS { ,0} \
    CONFIG.NUM_CLKS {7} \
    CONFIG.NUM_MC {1} \
    CONFIG.NUM_MCP {4} \
    CONFIG.NUM_MI {2} \
    CONFIG.NUM_SI {11} \
    CONFIG.SI_SIDEBAND_PINS { ,0,0,0,0,0,0,0,0} \
  ] $axi_noc_0


  set_property -dict [ list \
   CONFIG.APERTURES {{0x201_0000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.APERTURES {{0x201_8000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/M01_AXI]

  set_property -dict [ list \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {M01_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_3 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {M01_AXI:0x180:M00_AXI:0x100} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_2 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4} initial_boot {false}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4} initial_boot {false}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S02_AXI]

  set_property -dict [ list \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_1 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4} initial_boot {false}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S03_AXI]

  set_property -dict [ list \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {M01_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_3 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4} initial_boot {false}}} \
   CONFIG.DEST_IDS {M01_AXI:0x180:M00_AXI:0x100} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_rpu} \
 ] [get_bd_intf_pins /axi_noc_0/S04_AXI]

  set_property -dict [ list \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_2 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins /axi_noc_0/S05_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/S06_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/S07_AXI]

  set_property -dict [ list \
   CONFIG.R_TRAFFIC_CLASS {BEST_EFFORT} \
   CONFIG.CONNECTIONS {MC_2 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/S08_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_3 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/S09_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/S10_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S02_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk2]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S03_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk3]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S04_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk4]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S05_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk5]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M00_AXI:M01_AXI:S06_AXI:S07_AXI:S08_AXI:S09_AXI:S10_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk6]

  # Create instance: rst_sys_clk_100M, and set properties
  set rst_sys_clk_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_sys_clk_100M ]

  # Create instance: util_ds_buf_0, and set properties
  set util_ds_buf_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf_0 ]

  # Create instance: clk_wizard_0, and set properties
  set clk_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wizard:1.0 clk_wizard_0 ]
  set_property -dict [list \
    CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
    CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
    CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
    CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
    CONFIG.CLKOUT_PORT {clk_out1,clk_out2,clk_out3,clk_out4,clk_out5,clk_out6,clk_out7} \
    CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
    CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {100.000,300.000,100.000,100.000,100.000,100.000,100.000} \
    CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
    CONFIG.CLKOUT_USED {true,false,false,false,false,false,false} \
    CONFIG.PHASESHIFT_MODE {LATENCY} \
  ] $clk_wizard_0


  # Create instance: rvfi_fifo, and set properties
  set rvfi_fifo [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 rvfi_fifo ]

  # Create instance: csr_stream_fifo, and set properties
  set csr_stream_fifo [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 csr_stream_fifo ]

  # Create instance: csr_datamover, and set properties
  set csr_datamover [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_datamover:5.1 csr_datamover ]
  set_property -dict [list \
    CONFIG.c_dummy {1} \
    CONFIG.c_enable_mm2s {0} \
  ] $csr_datamover


  # Create instance: rvfi_datamover, and set properties
  set rvfi_datamover [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_datamover:5.1 rvfi_datamover ]
  set_property -dict [list \
    CONFIG.c_dummy {1} \
    CONFIG.c_enable_mm2s {0} \
  ] $rvfi_datamover


  # Create instance: rvfi_to_stream_0, and set properties
  set block_name rvfi_to_stream
  set block_cell_name rvfi_to_stream_0
  if { [catch {set rvfi_to_stream_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $rvfi_to_stream_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: data_ram_to_axi_brid_0, and set properties
  set block_name data_ram_to_axi_bridge
  set block_cell_name data_ram_to_axi_brid_0
  if { [catch {set data_ram_to_axi_brid_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $data_ram_to_axi_brid_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: instr_ram_to_axi_bri_0, and set properties
  set block_name instr_ram_to_axi_bridge
  set block_cell_name instr_ram_to_axi_bri_0
  if { [catch {set instr_ram_to_axi_bri_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $instr_ram_to_axi_bri_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: ilvector_logic_0, and set properties
  set ilvector_logic_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilvector_logic:1.0 ilvector_logic_0 ]
  set_property CONFIG.C_SIZE {1} $ilvector_logic_0


  # Create instance: ibex_demo_system_wra_0, and set properties
  set ibex_demo_system_wra_0 [ create_bd_cell -type ip -vlnv user.org:user:ibex_demo_system_wrapper:1.0 ibex_demo_system_wra_0 ]

  # Create instance: debug_module_wrapper_0, and set properties
  set debug_module_wrapper_0 [ create_bd_cell -type ip -vlnv user.org:user:debug_module_wrapper:1.0 debug_module_wrapper_0 ]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {rvfi_cmd:rvfi_csr_cmd:rvfi_csr_stream:rvfi_csr_sts:rvfi_stream:rvfi_sts:M_AXI_DATA:M_AXI_INSTR} \
 ] [get_bd_pins /debug_module_wrapper_0/sys_clk]

  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {128} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $axi_bram_ctrl_0


  # Create instance: emb_mem_gen_0, and set properties
  set emb_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen:1.0 emb_mem_gen_0 ]
  set_property CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} $emb_mem_gen_0


  # Create instance: ilconstant_0, and set properties
  set ilconstant_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant:1.0 ilconstant_0 ]

  # Create instance: ps_io2_wrapper_0, and set properties
  set block_name ps_io2_wrapper
  set block_cell_name ps_io2_wrapper_0
  if { [catch {set ps_io2_wrapper_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $ps_io2_wrapper_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]
  set_property CONFIG.NUM_SI {1} $smartconnect_0


  # Create instance: dside_fifo, and set properties
  set dside_fifo [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 dside_fifo ]

  # Create instance: dside_datamover, and set properties
  set dside_datamover [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_datamover:5.1 dside_datamover ]
  set_property -dict [list \
    CONFIG.c_dummy {1} \
    CONFIG.c_enable_mm2s {0} \
  ] $dside_datamover


  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins emb_mem_gen_0/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_datamover_0_M_AXIS_S2MM_STS [get_bd_intf_pins csr_datamover/M_AXIS_S2MM_STS] [get_bd_intf_pins rvfi_to_stream_0/csr_sts]
connect_bd_intf_net -intf_net [get_bd_intf_nets axi_datamover_0_M_AXIS_S2MM_STS] [get_bd_intf_pins csr_datamover/M_AXIS_S2MM_STS] [get_bd_intf_pins debug_module_wrapper_0/rvfi_csr_sts]
  connect_bd_intf_net -intf_net axi_datamover_0_M_AXI_S2MM [get_bd_intf_pins csr_datamover/M_AXI_S2MM] [get_bd_intf_pins axi_noc_0/S08_AXI]
  connect_bd_intf_net -intf_net axi_datamover_1_M_AXIS_S2MM_STS [get_bd_intf_pins rvfi_datamover/M_AXIS_S2MM_STS] [get_bd_intf_pins rvfi_to_stream_0/rvfi_sts]
connect_bd_intf_net -intf_net [get_bd_intf_nets axi_datamover_1_M_AXIS_S2MM_STS] [get_bd_intf_pins rvfi_datamover/M_AXIS_S2MM_STS] [get_bd_intf_pins debug_module_wrapper_0/rvfi_sts]
  connect_bd_intf_net -intf_net axi_datamover_1_M_AXI_S2MM [get_bd_intf_pins rvfi_datamover/M_AXI_S2MM] [get_bd_intf_pins axi_noc_0/S09_AXI]
  connect_bd_intf_net -intf_net axi_noc_0_CH0_DDR4_0 [get_bd_intf_ports DDR4] [get_bd_intf_pins axi_noc_0/CH0_DDR4_0]
  connect_bd_intf_net -intf_net axi_noc_0_M00_AXI [get_bd_intf_pins axi_noc_0/M00_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
  connect_bd_intf_net -intf_net axi_noc_0_M01_AXI [get_bd_intf_pins axi_noc_0/M01_AXI] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axis_data_fifo_0_M_AXIS [get_bd_intf_pins rvfi_fifo/M_AXIS] [get_bd_intf_pins rvfi_datamover/S_AXIS_S2MM]
connect_bd_intf_net -intf_net [get_bd_intf_nets axis_data_fifo_0_M_AXIS] [get_bd_intf_pins rvfi_fifo/M_AXIS] [get_bd_intf_pins debug_module_wrapper_0/rvfi_csr_stream]
  connect_bd_intf_net -intf_net axis_data_fifo_1_M_AXIS [get_bd_intf_pins csr_stream_fifo/M_AXIS] [get_bd_intf_pins csr_datamover/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net data_ram_to_axi_brid_0_M_AXI [get_bd_intf_pins data_ram_to_axi_brid_0/M_AXI] [get_bd_intf_pins axi_noc_0/S07_AXI]
connect_bd_intf_net -intf_net [get_bd_intf_nets data_ram_to_axi_brid_0_M_AXI] [get_bd_intf_pins data_ram_to_axi_brid_0/M_AXI] [get_bd_intf_pins debug_module_wrapper_0/M_AXI_DATA]
  connect_bd_intf_net -intf_net debug_module_wrapper_0_DEBUG [get_bd_intf_pins debug_module_wrapper_0/DEBUG] [get_bd_intf_pins emb_mem_gen_0/BRAM_PORTB]
  connect_bd_intf_net -intf_net dside_datamover_M_AXIS_S2MM_STS [get_bd_intf_pins rvfi_to_stream_0/dside_sts] [get_bd_intf_pins dside_datamover/M_AXIS_S2MM_STS]
  connect_bd_intf_net -intf_net dside_datamover_M_AXI_S2MM [get_bd_intf_pins dside_datamover/M_AXI_S2MM] [get_bd_intf_pins axi_noc_0/S10_AXI]
  connect_bd_intf_net -intf_net dside_fifo_M_AXIS [get_bd_intf_pins dside_fifo/M_AXIS] [get_bd_intf_pins dside_datamover/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net ibex_demo_system_wra_0_dside_access [get_bd_intf_pins ibex_demo_system_wra_0/dside_access] [get_bd_intf_pins rvfi_to_stream_0/dside_access]
  connect_bd_intf_net -intf_net ibex_demo_system_wra_0_ibex_ram_a [get_bd_intf_pins ibex_demo_system_wra_0/ibex_ram_a] [get_bd_intf_pins data_ram_to_axi_brid_0/S_RAM]
connect_bd_intf_net -intf_net [get_bd_intf_nets ibex_demo_system_wra_0_ibex_ram_a] [get_bd_intf_pins ibex_demo_system_wra_0/ibex_ram_a] [get_bd_intf_pins debug_module_wrapper_0/S_RAM_DATA]
  connect_bd_intf_net -intf_net ibex_demo_system_wra_0_ibex_ram_b [get_bd_intf_pins ibex_demo_system_wra_0/ibex_ram_b] [get_bd_intf_pins instr_ram_to_axi_bri_0/S_RAM]
connect_bd_intf_net -intf_net [get_bd_intf_nets ibex_demo_system_wra_0_ibex_ram_b] [get_bd_intf_pins ibex_demo_system_wra_0/ibex_ram_b] [get_bd_intf_pins debug_module_wrapper_0/S_RAM_INSTR]
  connect_bd_intf_net -intf_net ibex_demo_system_wra_0_rvfi [get_bd_intf_pins ibex_demo_system_wra_0/rvfi] [get_bd_intf_pins rvfi_to_stream_0/rvfi_in]
connect_bd_intf_net -intf_net [get_bd_intf_nets ibex_demo_system_wra_0_rvfi] [get_bd_intf_pins ibex_demo_system_wra_0/rvfi] [get_bd_intf_pins debug_module_wrapper_0/rvfi]
  connect_bd_intf_net -intf_net instr_ram_to_axi_bri_0_M_AXI [get_bd_intf_pins instr_ram_to_axi_bri_0/M_AXI] [get_bd_intf_pins axi_noc_0/S06_AXI]
connect_bd_intf_net -intf_net [get_bd_intf_nets instr_ram_to_axi_bri_0_M_AXI] [get_bd_intf_pins instr_ram_to_axi_bri_0/M_AXI] [get_bd_intf_pins debug_module_wrapper_0/M_AXI_INSTR]
  connect_bd_intf_net -intf_net ps_io2_wrapper_0_csr [get_bd_intf_pins ps_io2_wrapper_0/csr] [get_bd_intf_pins rvfi_to_stream_0/csr_ctrl]
  connect_bd_intf_net -intf_net ps_io2_wrapper_0_dside [get_bd_intf_pins ps_io2_wrapper_0/dside] [get_bd_intf_pins rvfi_to_stream_0/dside_ctrl]
  connect_bd_intf_net -intf_net ps_io2_wrapper_0_rvfi [get_bd_intf_pins ps_io2_wrapper_0/rvfi] [get_bd_intf_pins rvfi_to_stream_0/rvfi_ctrl]
  connect_bd_intf_net -intf_net rvfi_to_stream_0_csr_axis_fifo [get_bd_intf_pins rvfi_to_stream_0/csr_axis_fifo] [get_bd_intf_pins csr_stream_fifo/S_AXIS]
  connect_bd_intf_net -intf_net rvfi_to_stream_0_csr_cmd [get_bd_intf_pins rvfi_to_stream_0/csr_cmd] [get_bd_intf_pins csr_datamover/S_AXIS_S2MM_CMD]
connect_bd_intf_net -intf_net [get_bd_intf_nets rvfi_to_stream_0_csr_cmd] [get_bd_intf_pins rvfi_to_stream_0/csr_cmd] [get_bd_intf_pins debug_module_wrapper_0/rvfi_csr_cmd]
  connect_bd_intf_net -intf_net rvfi_to_stream_0_dside_axis_fifo [get_bd_intf_pins rvfi_to_stream_0/dside_axis_fifo] [get_bd_intf_pins dside_fifo/S_AXIS]
  connect_bd_intf_net -intf_net rvfi_to_stream_0_dside_cmd [get_bd_intf_pins rvfi_to_stream_0/dside_cmd] [get_bd_intf_pins dside_datamover/S_AXIS_S2MM_CMD]
  connect_bd_intf_net -intf_net rvfi_to_stream_0_rvfi_axis_fifo [get_bd_intf_pins rvfi_to_stream_0/rvfi_axis_fifo] [get_bd_intf_pins rvfi_fifo/S_AXIS]
connect_bd_intf_net -intf_net [get_bd_intf_nets rvfi_to_stream_0_rvfi_axis_fifo] [get_bd_intf_pins rvfi_to_stream_0/rvfi_axis_fifo] [get_bd_intf_pins debug_module_wrapper_0/rvfi_stream]
  connect_bd_intf_net -intf_net rvfi_to_stream_0_rvfi_cmd [get_bd_intf_pins rvfi_to_stream_0/rvfi_cmd] [get_bd_intf_pins rvfi_datamover/S_AXIS_S2MM_CMD]
connect_bd_intf_net -intf_net [get_bd_intf_nets rvfi_to_stream_0_rvfi_cmd] [get_bd_intf_pins rvfi_to_stream_0/rvfi_cmd] [get_bd_intf_pins debug_module_wrapper_0/rvfi_cmd]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins ps_io2_wrapper_0/s00_axi]
  connect_bd_intf_net -intf_net sys_1 [get_bd_intf_ports sys] [get_bd_intf_pins util_ds_buf_0/CLK_IN_D]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_0 [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_0] [get_bd_intf_pins axi_noc_0/S00_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_1 [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_1] [get_bd_intf_pins axi_noc_0/S01_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_2 [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_2] [get_bd_intf_pins axi_noc_0/S02_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_3 [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_3] [get_bd_intf_pins axi_noc_0/S03_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_LPD_AXI_NOC_0 [get_bd_intf_pins versal_cips_0/LPD_AXI_NOC_0] [get_bd_intf_pins axi_noc_0/S04_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_PMC_NOC_AXI_0 [get_bd_intf_pins versal_cips_0/PMC_NOC_AXI_0] [get_bd_intf_pins axi_noc_0/S05_AXI]

  # Create port connections
  connect_bd_net -net clk_wizard_0_clk_out1  [get_bd_pins clk_wizard_0/clk_out1] \
  [get_bd_pins rst_sys_clk_100M/slowest_sync_clk] \
  [get_bd_pins csr_datamover/m_axi_s2mm_aclk] \
  [get_bd_pins csr_datamover/m_axis_s2mm_cmdsts_awclk] \
  [get_bd_pins rvfi_datamover/m_axi_s2mm_aclk] \
  [get_bd_pins rvfi_datamover/m_axis_s2mm_cmdsts_awclk] \
  [get_bd_pins rvfi_fifo/s_axis_aclk] \
  [get_bd_pins csr_stream_fifo/s_axis_aclk] \
  [get_bd_pins axi_noc_0/aclk6] \
  [get_bd_pins versal_cips_0/m_axi_lpd_aclk] \
  [get_bd_pins rvfi_to_stream_0/clk] \
  [get_bd_pins instr_ram_to_axi_bri_0/clk] \
  [get_bd_pins data_ram_to_axi_brid_0/clk] \
  [get_bd_pins ibex_demo_system_wra_0/sys_clk] \
  [get_bd_pins debug_module_wrapper_0/sys_clk] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] \
  [get_bd_pins ps_io2_wrapper_0/s00_axi_aclk] \
  [get_bd_pins smartconnect_0/aclk] \
  [get_bd_pins dside_fifo/s_axis_aclk] \
  [get_bd_pins dside_datamover/m_axi_s2mm_aclk] \
  [get_bd_pins dside_datamover/m_axis_s2mm_cmdsts_awclk]
  connect_bd_net -net ibex_demo_system_wra_0_led  [get_bd_pins ibex_demo_system_wra_0/led] \
  [get_bd_ports led]
  connect_bd_net -net ilconstant_0_dout  [get_bd_pins ilconstant_0/dout] \
  [get_bd_pins emb_mem_gen_0/regcea] \
  [get_bd_pins emb_mem_gen_0/regceb]
  connect_bd_net -net ilvector_logic_0_Res  [get_bd_pins ilvector_logic_0/Res] \
  [get_bd_pins data_ram_to_axi_brid_0/rstn] \
  [get_bd_pins instr_ram_to_axi_bri_0/rstn] \
  [get_bd_pins rvfi_to_stream_0/rstn] \
  [get_bd_pins ibex_demo_system_wra_0/sys_rstn] \
  [get_bd_pins debug_module_wrapper_0/sys_rstn]
  connect_bd_net -net ps_io2_wrapper_0_csr_baseaddr  [get_bd_pins ps_io2_wrapper_0/csr_baseaddr] \
  [get_bd_pins ps_io2_wrapper_0/debug2]
  connect_bd_net -net ps_io2_wrapper_0_prog_addr  [get_bd_pins ps_io2_wrapper_0/prog_addr] \
  [get_bd_pins ibex_demo_system_wra_0/ibex_ram_base_addr]
  connect_bd_net -net ps_io2_wrapper_0_rvfi_baseaddr  [get_bd_pins ps_io2_wrapper_0/rvfi_baseaddr] \
  [get_bd_pins ps_io2_wrapper_0/debug1]
  connect_bd_net -net ps_io2_wrapper_0_rvfi_swidx  [get_bd_pins ps_io2_wrapper_0/rvfi_swidx] \
  [get_bd_pins ps_io2_wrapper_0/debug3]
  connect_bd_net -net ps_io2_wrapper_0_sys_flush  [get_bd_pins ps_io2_wrapper_0/sys_flush] \
  [get_bd_pins rvfi_to_stream_0/flush]
  connect_bd_net -net ps_io2_wrapper_0_sys_rstn  [get_bd_pins ps_io2_wrapper_0/sys_rstn] \
  [get_bd_pins ilvector_logic_0/Op1]
  connect_bd_net -net rst_sys_clk_100M_peripheral_aresetn  [get_bd_pins rst_sys_clk_100M/peripheral_aresetn] \
  [get_bd_pins csr_datamover/m_axi_s2mm_aresetn] \
  [get_bd_pins csr_datamover/m_axis_s2mm_cmdsts_aresetn] \
  [get_bd_pins rvfi_datamover/m_axis_s2mm_cmdsts_aresetn] \
  [get_bd_pins rvfi_datamover/m_axi_s2mm_aresetn] \
  [get_bd_pins rvfi_fifo/s_axis_aresetn] \
  [get_bd_pins csr_stream_fifo/s_axis_aresetn] \
  [get_bd_pins ilvector_logic_0/Op2] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] \
  [get_bd_pins ps_io2_wrapper_0/s00_axi_aresetn] \
  [get_bd_pins smartconnect_0/aresetn] \
  [get_bd_pins dside_fifo/s_axis_aresetn] \
  [get_bd_pins dside_datamover/m_axi_s2mm_aresetn] \
  [get_bd_pins dside_datamover/m_axis_s2mm_cmdsts_aresetn]
  connect_bd_net -net rvfi_to_stream_0_force_stop  [get_bd_pins rvfi_to_stream_0/force_stop] \
  [get_bd_pins ibex_demo_system_wra_0/force_stop]
  connect_bd_net -net rvfi_to_stream_0_rvfi_ctrl_hwidx  [get_bd_pins rvfi_to_stream_0/rvfi_ctrl_hwidx] \
  [get_bd_pins ps_io2_wrapper_0/debug4]
  connect_bd_net -net util_ds_buf_0_IBUF_OUT  [get_bd_pins util_ds_buf_0/IBUF_OUT] \
  [get_bd_pins clk_wizard_0/clk_in1] \
  [get_bd_pins axi_noc_0/sys_clk0]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi0_clk  [get_bd_pins versal_cips_0/fpd_cci_noc_axi0_clk] \
  [get_bd_pins axi_noc_0/aclk0]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi1_clk  [get_bd_pins versal_cips_0/fpd_cci_noc_axi1_clk] \
  [get_bd_pins axi_noc_0/aclk1]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi2_clk  [get_bd_pins versal_cips_0/fpd_cci_noc_axi2_clk] \
  [get_bd_pins axi_noc_0/aclk2]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi3_clk  [get_bd_pins versal_cips_0/fpd_cci_noc_axi3_clk] \
  [get_bd_pins axi_noc_0/aclk3]
  connect_bd_net -net versal_cips_0_lpd_axi_noc_clk  [get_bd_pins versal_cips_0/lpd_axi_noc_clk] \
  [get_bd_pins axi_noc_0/aclk4]
  connect_bd_net -net versal_cips_0_pl0_resetn  [get_bd_pins versal_cips_0/pl0_resetn] \
  [get_bd_pins rst_sys_clk_100M/ext_reset_in]
  connect_bd_net -net versal_cips_0_pmc_axi_noc_axi0_clk  [get_bd_pins versal_cips_0/pmc_axi_noc_axi0_clk] \
  [get_bd_pins axi_noc_0/aclk5]

  # Create address segments
  assign_bd_address -offset 0x020100000000 -range 0x00004000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_0/S00_AXI/C3_DDR_LOW0] -force
  assign_bd_address -offset 0x020180000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs ps_io2_wrapper_0/s00_axi/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_0/S01_AXI/C2_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_0/S02_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_0/S03_AXI/C1_DDR_LOW0] -force
  assign_bd_address -offset 0x020100000000 -range 0x00004000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S04_AXI/C3_DDR_LOW0] -force
  assign_bd_address -offset 0x020180000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs ps_io2_wrapper_0/s00_axi/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_0/S05_AXI/C2_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces csr_datamover/Data_S2MM] [get_bd_addr_segs axi_noc_0/S08_AXI/C2_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces rvfi_datamover/Data_S2MM] [get_bd_addr_segs axi_noc_0/S09_AXI/C3_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces data_ram_to_axi_brid_0/M_AXI] [get_bd_addr_segs axi_noc_0/S07_AXI/C1_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces instr_ram_to_axi_bri_0/M_AXI] [get_bd_addr_segs axi_noc_0/S06_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces dside_datamover/Data_S2MM] [get_bd_addr_segs axi_noc_0/S10_AXI/C0_DDR_LOW0] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design

  set wrapper_file [make_wrapper -files [get_files $design_name.bd] -top]
  add_files $wrapper_file
  update_compile_order -fileset sources_1
}


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

set dir_path [lindex $argv 0]

set_property source_mgmt_mode All [current_project]

set_property  ip_repo_paths  [list "$dir_path/rtl/fpga/versal_ip/intf_ip" "$dir_path/build/ip_repo" "$dir_path/rtl/fpga/versal_ip/debug_ip"] [current_project]
update_ip_catalog

create_ps_io_design ""
create_root_design ""

create_fifo_design "" 128 6 "fifo_6_128"
create_fifo_design "" 16 32 "fifo_32_16"
create_fifo_design "" 16 40 "fifo_40_16"
create_fifo_design "" 16 69 "fifo_69_16"
create_fifo_design "" 16 98 "fifo_98_16"
create_fifo_design "" 16 227 "fifo_227_16"
create_fifo_design "" 16 664 "fifo_664_16"

set_property top ps_subsystem_wrapper [current_fileset]
