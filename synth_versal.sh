CUR_PATH=`pwd`

# make the ibex wrapper ip
fusesoc --cores-root=$CUR_PATH run --target=synth_ibex_wrapper --setup lowrisc:ibex:demo_system
cd $CUR_PATH/build/lowrisc_ibex_demo_system_0/synth_ibex_wrapper-vivado/
vivado -mode batch -source lowrisc_ibex_demo_system_0.tcl
vivado $CUR_PATH/build/lowrisc_ibex_demo_system_0/synth_ibex_wrapper-vivado/lowrisc_ibex_demo_system_0.xpr -mode batch -source $CUR_PATH/tcl/gen_ibex_ip.tcl -tclargs $CUR_PATH


# make the versal block design
cd $CUR_PATH
fusesoc --cores-root=. run --target=synth_versal --setup ::ibex_versal
cd $CUR_PATH/build/ibex_versal_0/synth_versal-vivado
vivado -mode batch -source ibex_versal_0.tcl
vivado $CUR_PATH/build/ibex_versal_0/synth_versal-vivado/ibex_versal_0.xpr -mode batch -source $CUR_PATH/tcl/versal_ps.tcl -tclargs $CUR_PATH


# export hardware
mkdir $CUR_PATH/build/hardware
vivado $CUR_PATH/build/ibex_versal_0/synth_versal-vivado/ibex_versal_0.xpr -mode batch -source $CUR_PATH/tcl/export_xsa.tcl -tclargs $CUR_PATH

# build petalinux
cd $CUR_PATH/build
petalinux-create -t project --template versal -n petalinux
cd ./petalinux && petalinux-config --get-hw-description ../hardware
cp $CUR_PATH/petalinux/system-user.dtsi $CUR_PATH/build/petalinux/project-spec/meta-user/recipes-bsp/device-tree/files/
petalinux-build && petalinux-package --boot --u-boot --force


# build petalinux sdk
mkdir $CUR_PATH/build/install-sdk
cd $CUR_PATH/build/petalinux
petalinux-build --sdk
cd ./images/linux
./sdk.sh -y -d $CUR_PATH/build/install-sdk/
cd $CUR_PATH/build/install-sdk
source environment-setup-cortexa72-cortexa53-amd-linux


# now $CC contains command to compile c files
