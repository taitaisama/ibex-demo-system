set devicePart "xcve2302-sfva784-1LP-e-s"

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
    catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" "This script should be run inside an opened project"}
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable design_name

  set design_name ps_subsystem
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
  set DDR4 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 DDR4 ]

  set PS_IO [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 PS_IO ]

  set sys [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sys ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
   ] $sys

  set rvfi [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 rvfi ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {32} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $rvfi

  set rvfi_csr [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 rvfi_csr ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {16} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $rvfi_csr

  set rvfi_cmd [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 rvfi_cmd ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {9} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $rvfi_cmd

  set rvfi_csr_cmd [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 rvfi_csr_cmd ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {9} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $rvfi_csr_cmd

  set DEBUG [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:bram_rtl:1.0 DEBUG ]
  set_property -dict [ list \
   CONFIG.MASTER_TYPE {BRAM_CTRL} \
   CONFIG.MEM_WIDTH {512} \
   CONFIG.READ_WRITE_MODE {WRITE_ONLY} \
   ] $DEBUG

  set RVFI_FIFO_OUT [ create_bd_intf_port -mode Monitor -mon_dir SlaveType -vlnv xilinx.com:interface:axis_rtl:1.0 RVFI_FIFO_OUT ]

  set DM_OUT [ create_bd_intf_port -mode Monitor -mon_dir SlaveType -vlnv xilinx.com:interface:aximm_rtl:1.0 DM_OUT ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.PROTOCOL {AXI4} \
   ] $DM_OUT

  set IBEX_DATA [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 IBEX_DATA ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {4} \
   CONFIG.MAX_BURST_LENGTH {4} \
   CONFIG.NUM_READ_OUTSTANDING {16} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {16} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {1} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $IBEX_DATA

  set IBEX_INSTR [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 IBEX_INSTR ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {4} \
   CONFIG.MAX_BURST_LENGTH {4} \
   CONFIG.NUM_READ_OUTSTANDING {16} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {16} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {READ_ONLY} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {1} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $IBEX_INSTR


  # Create ports
  set axi_clk [ create_bd_port -dir O -from 0 -to 0 -type clk axi_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {RVFI_FIFO_OUT:IBEX_DATA:IBEX_INSTR:DM_OUT:DEBUG:rvfi_cmd:rvfi:rvfi_csr_cmd:rvfi_csr} \
 ] $axi_clk
  set axi_rstn [ create_bd_port -dir O -from 0 -to 0 -type rst axi_rstn ]

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:3.4 versal_cips_0 ]
  set_property -dict [list \
    CONFIG.BOOT_MODE {Custom} \
    CONFIG.DDR_MEMORY_MODE {Custom} \
    CONFIG.DESIGN_MODE {1} \
    CONFIG.IO_CONFIG_MODE {Custom} \
    CONFIG.PS_PMC_CONFIG { \
      BOOT_MODE {Custom} \
      DDR_MEMORY_MODE {Connectivity to DDR via NOC} \
      DESIGN_MODE {1} \
      IO_CONFIG_MODE {Custom} \
      PMC_GPIO_EMIO_PERIPHERAL_ENABLE {0} \
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
      PS_ENET0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 0 .. 11}}} \
      PS_GEN_IPI0_ENABLE {1} \
      PS_GEN_IPI1_ENABLE {1} \
      PS_GEN_IPI2_ENABLE {1} \
      PS_GEN_IPI3_ENABLE {1} \
      PS_GEN_IPI4_ENABLE {1} \
      PS_GEN_IPI5_ENABLE {1} \
      PS_GEN_IPI6_ENABLE {1} \
      PS_GPIO_EMIO_PERIPHERAL_ENABLE {0} \
      PS_NUM_FABRIC_RESETS {1} \
      PS_TTC0_PERIPHERAL_ENABLE {1} \
      PS_TTC1_PERIPHERAL_ENABLE {1} \
      PS_TTC2_PERIPHERAL_ENABLE {1} \
      PS_TTC3_PERIPHERAL_ENABLE {1} \
      PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 16 .. 17}}} \
      PS_USB3_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 13 .. 25}}} \
      PS_USE_FPD_CCI_NOC {1} \
      PS_USE_FPD_CCI_NOC0 {1} \
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
    CONFIG.MC_CHAN_REGION1 {NONE} \
    CONFIG.MC_COMPONENT_WIDTH {x16} \
    CONFIG.MC_INPUTCLK0_PERIOD {5000} \
    CONFIG.MC_MEMORY_SPEEDGRADE {DDR4-3200AA(22-22-22)} \
    CONFIG.MC_SYSTEM_CLOCK {No_Buffer} \
    CONFIG.MI_SIDEBAND_PINS { ,0} \
    CONFIG.NUM_CLKS {7} \
    CONFIG.NUM_MC {1} \
    CONFIG.NUM_MCP {4} \
    CONFIG.NUM_MI {2} \
    CONFIG.NUM_SI {10} \
    CONFIG.SI_SIDEBAND_PINS { ,0,0,0,0,0,0,0,0} \
  ] $axi_noc_0


  set_property -dict [ list \
   CONFIG.APERTURES {{0x201_4000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.APERTURES {{0x201_C000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/M01_AXI]

  set_property -dict [ list \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {M01_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_AXI {read_bw {5} write_bw {5}} MC_3 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {M01_AXI:0xc0:M00_AXI:0x140} \
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
   CONFIG.DEST_IDS {M01_AXI:0xc0:M00_AXI:0x140} \
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
   CONFIG.CONNECTIONS {MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/S08_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_1 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/S09_AXI]

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
   CONFIG.ASSOCIATED_BUSIF {M00_AXI:M01_AXI:S06_AXI:S07_AXI:S08_AXI:S09_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk6]

  # Create instance: rst_sys_clk_100M, and set properties
  set rst_sys_clk_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_sys_clk_100M ]

  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0 ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_GPIO_WIDTH {2} \
  ] $axi_gpio_0


  # Create instance: axi_gpio_0_smc, and set properties
  set axi_gpio_0_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_gpio_0_smc ]
  set_property -dict [list \
    CONFIG.NUM_MI {1} \
    CONFIG.NUM_SI {1} \
  ] $axi_gpio_0_smc


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
    CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {100.000,100.000,100.000,100.000,100.000,100.000,100.000} \
    CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
    CONFIG.CLKOUT_USED {true,false,false,false,false,false,false} \
    CONFIG.PHASESHIFT_MODE {WAVEFORM} \
  ] $clk_wizard_0


  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]

  # Create instance: axis_data_fifo_0, and set properties
  set axis_data_fifo_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_0 ]

  # Create instance: axis_data_fifo_1, and set properties
  set axis_data_fifo_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_1 ]

  # Create instance: axi_datamover_0, and set properties
  set axi_datamover_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_datamover:5.1 axi_datamover_0 ]
  set_property -dict [list \
    CONFIG.c_dummy {1} \
    CONFIG.c_enable_mm2s {0} \
  ] $axi_datamover_0


  # Create instance: axi_datamover_1, and set properties
  set axi_datamover_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_datamover:5.1 axi_datamover_1 ]
  set_property -dict [list \
    CONFIG.c_dummy {1} \
    CONFIG.c_enable_mm2s {0} \
  ] $axi_datamover_1


  # Create instance: axi_bram_ctrl_1, and set properties
  set axi_bram_ctrl_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_1 ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {512} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $axi_bram_ctrl_1


  # Create instance: axi_bram_ctrl_1_bram, and set properties
  set axi_bram_ctrl_1_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen:1.0 axi_bram_ctrl_1_bram ]
  set_property CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} $axi_bram_ctrl_1_bram


  # Create interface connections
  connect_bd_intf_net -intf_net DEBUG_1 [get_bd_intf_ports DEBUG] [get_bd_intf_pins axi_bram_ctrl_1_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net IBEX_DATA_1 [get_bd_intf_ports IBEX_DATA] [get_bd_intf_pins axi_noc_0/S07_AXI]
  connect_bd_intf_net -intf_net IBEX_INSTR_1 [get_bd_intf_ports IBEX_INSTR] [get_bd_intf_pins axi_noc_0/S06_AXI]
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_1_bram/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_datamover_0_M_AXI_S2MM [get_bd_intf_pins axi_datamover_0/M_AXI_S2MM] [get_bd_intf_pins axi_noc_0/S08_AXI]
connect_bd_intf_net -intf_net [get_bd_intf_nets axi_datamover_0_M_AXI_S2MM] [get_bd_intf_pins axi_datamover_0/M_AXI_S2MM] [get_bd_intf_ports DM_OUT]
  connect_bd_intf_net -intf_net axi_datamover_1_M_AXI_S2MM [get_bd_intf_pins axi_datamover_1/M_AXI_S2MM] [get_bd_intf_pins axi_noc_0/S09_AXI]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_ports PS_IO] [get_bd_intf_pins axi_gpio_0/GPIO]
  connect_bd_intf_net -intf_net axi_gpio_0_smc_M00_AXI [get_bd_intf_pins axi_gpio_0/S_AXI] [get_bd_intf_pins axi_gpio_0_smc/M00_AXI]
  connect_bd_intf_net -intf_net axi_noc_0_CH0_DDR4_0 [get_bd_intf_ports DDR4] [get_bd_intf_pins axi_noc_0/CH0_DDR4_0]
  connect_bd_intf_net -intf_net axi_noc_0_M00_AXI [get_bd_intf_pins axi_noc_0/M00_AXI] [get_bd_intf_pins axi_gpio_0_smc/S00_AXI]
  connect_bd_intf_net -intf_net axi_noc_0_M01_AXI [get_bd_intf_pins axi_noc_0/M01_AXI] [get_bd_intf_pins axi_bram_ctrl_1/S_AXI]
  connect_bd_intf_net -intf_net axis_data_fifo_0_M_AXIS [get_bd_intf_pins axis_data_fifo_0/M_AXIS] [get_bd_intf_pins axi_datamover_1/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net axis_data_fifo_1_M_AXIS [get_bd_intf_pins axis_data_fifo_1/M_AXIS] [get_bd_intf_pins axi_datamover_0/S_AXIS_S2MM]
connect_bd_intf_net -intf_net [get_bd_intf_nets axis_data_fifo_1_M_AXIS] [get_bd_intf_pins axis_data_fifo_1/M_AXIS] [get_bd_intf_ports RVFI_FIFO_OUT]
  connect_bd_intf_net -intf_net rvfi_1 [get_bd_intf_ports rvfi] [get_bd_intf_pins axis_data_fifo_1/S_AXIS]
  connect_bd_intf_net -intf_net rvfi_cmd_1 [get_bd_intf_ports rvfi_cmd] [get_bd_intf_pins axi_datamover_0/S_AXIS_S2MM_CMD]
  connect_bd_intf_net -intf_net rvfi_csr_1 [get_bd_intf_ports rvfi_csr] [get_bd_intf_pins axis_data_fifo_0/S_AXIS]
  connect_bd_intf_net -intf_net rvfi_csr_cmd_1 [get_bd_intf_ports rvfi_csr_cmd] [get_bd_intf_pins axi_datamover_1/S_AXIS_S2MM_CMD]
  connect_bd_intf_net -intf_net sys_1 [get_bd_intf_ports sys] [get_bd_intf_pins util_ds_buf_0/CLK_IN_D]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_0 [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_0] [get_bd_intf_pins axi_noc_0/S00_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_1 [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_1] [get_bd_intf_pins axi_noc_0/S01_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_2 [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_2] [get_bd_intf_pins axi_noc_0/S02_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_3 [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_3] [get_bd_intf_pins axi_noc_0/S03_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_LPD_AXI_NOC_0 [get_bd_intf_pins versal_cips_0/LPD_AXI_NOC_0] [get_bd_intf_pins axi_noc_0/S04_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_PMC_NOC_AXI_0 [get_bd_intf_pins versal_cips_0/PMC_NOC_AXI_0] [get_bd_intf_pins axi_noc_0/S05_AXI]

  # Create port connections
  connect_bd_net -net clk_wizard_0_clk_out1  [get_bd_pins clk_wizard_0/clk_out1] \
  [get_bd_pins axi_noc_0/aclk6] \
  [get_bd_pins rst_sys_clk_100M/slowest_sync_clk] \
  [get_bd_pins axi_gpio_0_smc/aclk] \
  [get_bd_pins axi_gpio_0/s_axi_aclk] \
  [get_bd_ports axi_clk] \
  [get_bd_pins axi_datamover_0/m_axi_s2mm_aclk] \
  [get_bd_pins axi_datamover_0/m_axis_s2mm_cmdsts_awclk] \
  [get_bd_pins axi_datamover_1/m_axi_s2mm_aclk] \
  [get_bd_pins axi_datamover_1/m_axis_s2mm_cmdsts_awclk] \
  [get_bd_pins axis_data_fifo_0/s_axis_aclk] \
  [get_bd_pins axis_data_fifo_1/s_axis_aclk] \
  [get_bd_pins axi_bram_ctrl_1/s_axi_aclk]
  connect_bd_net -net rst_sys_clk_100M_peripheral_aresetn  [get_bd_pins rst_sys_clk_100M/peripheral_aresetn] \
  [get_bd_pins axi_gpio_0/s_axi_aresetn] \
  [get_bd_pins axi_gpio_0_smc/aresetn] \
  [get_bd_ports axi_rstn] \
  [get_bd_pins axi_datamover_0/m_axi_s2mm_aresetn] \
  [get_bd_pins axi_datamover_0/m_axis_s2mm_cmdsts_aresetn] \
  [get_bd_pins axi_datamover_1/m_axis_s2mm_cmdsts_aresetn] \
  [get_bd_pins axi_datamover_1/m_axi_s2mm_aresetn] \
  [get_bd_pins axis_data_fifo_0/s_axis_aresetn] \
  [get_bd_pins axis_data_fifo_1/s_axis_aresetn] \
  [get_bd_pins axi_bram_ctrl_1/s_axi_aresetn]
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
  connect_bd_net -net xlconstant_0_dout  [get_bd_pins xlconstant_0/dout] \
  [get_bd_pins axi_datamover_1/m_axis_s2mm_sts_tready] \
  [get_bd_pins axi_datamover_0/m_axis_s2mm_sts_tready] \
  [get_bd_pins axi_bram_ctrl_1_bram/regcea] \
  [get_bd_pins axi_bram_ctrl_1_bram/regceb]

  # Create address segments
  assign_bd_address -offset 0x0201C0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0] -force
  assign_bd_address -offset 0x020140000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_0/S00_AXI/C3_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_0/S01_AXI/C2_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_0/S02_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_0/S03_AXI/C1_DDR_LOW0] -force
  assign_bd_address -offset 0x0201C0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0] -force
  assign_bd_address -offset 0x020140000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S04_AXI/C3_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_0/S05_AXI/C2_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_datamover_0/Data_S2MM] [get_bd_addr_segs axi_noc_0/S08_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_datamover_1/Data_S2MM] [get_bd_addr_segs axi_noc_0/S09_AXI/C1_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces IBEX_DATA] [get_bd_addr_segs axi_noc_0/S07_AXI/C1_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces IBEX_INSTR] [get_bd_addr_segs axi_noc_0/S06_AXI/C0_DDR_LOW0] -force


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

  save_bd_design

  set wrapper_file [make_wrapper -files [get_files $design_name.bd] -top]
  add_files $wrapper_file
  update_compile_order -fileset sources_1
}

create_root_design ""
create_fifo_design "" 128 4 "fifo_4_128"
create_fifo_design "" 128 6 "fifo_6_128"
create_fifo_design "" 128 32 "fifo_32_128"
create_fifo_design "" 128 40 "fifo_40_128"
create_fifo_design "" 128 69 "fifo_69_128"
create_fifo_design "" 16 832 "fifo_832_16"
