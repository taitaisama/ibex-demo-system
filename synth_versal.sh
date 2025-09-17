CUR_PATH=`pwd`
fusesoc --cores-root=$CUR_PATH run --target=synth_versal --setup lowrisc:ibex:demo_system
cd $CUR_PATH/build/lowrisc_ibex_demo_system_0/synth_versal-vivado/
vivado -mode batch -source lowrisc_ibex_demo_system_0.tcl
mkdir $CUR_PATH/build/hardware
echo "launch_runs synth_1 -quiet -jobs 16
launch_runs impl_1 -to_step write_bitstream -jobs 16
wait_on_run impl_1
write_hw_platform -fixed -include_bit -force -file $CUR_PATH/build/hardware/top_versal.xsa" > $CUR_PATH/build/hardware/export_xsa.tcl
vivado $CUR_PATH/build/lowrisc_ibex_demo_system_0/synth_versal-vivado/lowrisc_ibex_demo_system_0.xpr -mode batch -source $CUR_PATH/build/hardware/export_xsa.tcl
cd $CUR_PATH/build
petalinux-create -t project --template versal -n petalinux
cd ./petalinux && petalinux-config --get-hw-description ../hardware
petalinux-build && petalinux-package --boot --u-boot --force
cd $CUR_PATH

