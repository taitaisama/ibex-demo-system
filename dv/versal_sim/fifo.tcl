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

  # Create instance: emb_fifo_gen_0, and set properties
  set emb_fifo_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_fifo_gen:1.0 emb_fifo_gen_0 ]
  set_property -dict [list \
    CONFIG.FIFO_WRITE_DEPTH $depth \
    CONFIG.READ_MODE {FWFT} \
    CONFIG.WRITE_DATA_WIDTH $width \
  ] $emb_fifo_gen_0


  # Create interface connections
  connect_bd_intf_net -intf_net fifo_read_1 [get_bd_intf_ports fifo_read] [get_bd_intf_pins emb_fifo_gen_0/FIFO_READ]
  connect_bd_intf_net -intf_net fifo_write_1 [get_bd_intf_ports fifo_write] [get_bd_intf_pins emb_fifo_gen_0/FIFO_WRITE]

  # Create port connections
  connect_bd_net -net clk_1  [get_bd_ports clk] \
  [get_bd_pins emb_fifo_gen_0/wr_clk]
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

create_fifo_design "" 16 832 "rvfi_fifo"
create_fifo_design "" 256 256 "rvfi_mem_fifo"
create_fifo_design "" 256 128 "rvfi_csr_fifo"
