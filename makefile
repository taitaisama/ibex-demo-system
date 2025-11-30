CUR_PATH := $(shell pwd)
BUILD_DIR := $(CUR_PATH)/build
STAMP_DIR := $(BUILD_DIR)/.stamps

STAMPS := ibex_wrapper_ip versal_bd hardware petalinux petalinux_sdk petalinux_sw vitis # ibex_io_ip

.PHONY: all clean $(STAMPS)

all: petalinux_sdk

$(STAMP_DIR):
	mkdir -p $(STAMP_DIR)

ibex_wrapper_ip: $(STAMP_DIR)/ibex_wrapper_ip
$(STAMP_DIR)/ibex_wrapper_ip: | $(STAMP_DIR)
	@echo "### Building Ibex Wrapper IP..."
	fusesoc --cores-root=$(CUR_PATH) run --target=synth_ibex_wrapper --setup lowrisc:ibex:demo_system
	cd $(BUILD_DIR)/lowrisc_ibex_demo_system_0/synth_ibex_wrapper-vivado && \
		vivado -mode batch -source lowrisc_ibex_demo_system_0.tcl
	vivado $(BUILD_DIR)/lowrisc_ibex_demo_system_0/synth_ibex_wrapper-vivado/lowrisc_ibex_demo_system_0.xpr \
		-mode batch -source $(CUR_PATH)/tcl/gen_ibex_ip.tcl -tclargs $(CUR_PATH)
	touch $@

# ibex_io_ip: $(STAMP_DIR)/ibex_io_ip
# $(STAMP_DIR)/ibex_io_ip: | $(STAMP_DIR)
# 	@echo "### Building Ibex IO IP..."
# 	fusesoc --cores-root=$(CUR_PATH) run --target=ibex_io_ip --setup ::ibex_versal
# 	cd $(BUILD_DIR)/ibex_versal_0/ibex_io_ip-vivado && \
# 		vivado -mode batch -source ibex_versal_0.tcl
# 	vivado $(BUILD_DIR)/ibex_versal_0/ibex_io_ip-vivado/ibex_versal_0.xpr \
# 		-mode batch -source $(CUR_PATH)/tcl/io_stuff.tcl -tclargs $(CUR_PATH)
# 	touch $@

versal_bd: $(STAMP_DIR)/versal_bd
$(STAMP_DIR)/versal_bd: $(STAMP_DIR)/ibex_wrapper_ip
	@echo "### Building Versal Block Design..."
	fusesoc --cores-root=$(CUR_PATH) run --target=synth_versal --setup ::ibex_versal
	cd $(BUILD_DIR)/ibex_versal_0/synth_versal-vivado && \
		vivado -mode batch -source ibex_versal_0.tcl
	vivado $(BUILD_DIR)/ibex_versal_0/synth_versal-vivado/ibex_versal_0.xpr \
		-mode batch -source $(CUR_PATH)/tcl/io_stuff.tcl -tclargs $(CUR_PATH)
	vivado $(BUILD_DIR)/ibex_versal_0/synth_versal-vivado/ibex_versal_0.xpr \
		-mode batch -source $(CUR_PATH)/tcl/versal_ps.tcl -tclargs $(CUR_PATH)
	touch $@

hardware: $(STAMP_DIR)/hardware
$(STAMP_DIR)/hardware: $(STAMP_DIR)/versal_bd
	@echo "### Exporting Hardware XSA..."
	mkdir -p $(BUILD_DIR)/hardware
	ulimit -v unlimited && vivado $(BUILD_DIR)/ibex_versal_0/synth_versal-vivado/ibex_versal_0.xpr \
		-mode batch -source $(CUR_PATH)/tcl/export_xsa.tcl -tclargs $(BUILD_DIR)/hardware/top_versal.xsa -log $(BUILD_DIR)/vivado_crash.log -jou $(BUILD_DIR)/vivado_crash.jou -stack 2000 | tee $(BUILD_DIR)/vivado_stdout_and_stderr.log
	touch $@

petalinux: $(STAMP_DIR)/petalinux
$(STAMP_DIR)/petalinux: $(STAMP_DIR)/hardware
	@echo "### Building PetaLinux Project..."
	cd $(BUILD_DIR) && petalinux-create -t project --template versal -n petalinux
	cd $(BUILD_DIR)/petalinux && petalinux-config --get-hw-description ../hardware
	cp $(CUR_PATH)/sw/petalinux/system-user.dtsi \
		$(BUILD_DIR)/petalinux/project-spec/meta-user/recipes-bsp/device-tree/files/
	cd $(BUILD_DIR)/petalinux && petalinux-build && \
		petalinux-package --boot --u-boot --force
	touch $@

petalinux_sdk: $(STAMP_DIR)/petalinux_sdk
$(STAMP_DIR)/petalinux_sdk: $(STAMP_DIR)/petalinux
	@echo "### Building PetaLinux SDK..."
	mkdir -p $(BUILD_DIR)/install-sdk
	cd $(BUILD_DIR)/petalinux && petalinux-build --sdk
	cd $(BUILD_DIR)/petalinux/images/linux && ./sdk.sh -y -d $(BUILD_DIR)/install-sdk
	@echo "### To use SDK, run:"
	@echo "source $(BUILD_DIR)/install-sdk/environment-setup-cortexa72-cortexa53-amd-linux"
	touch $@

petalinux_sw: $(STAMP_DIR)/petalinux_sw
$(STAMP_DIR)/petalinux_sw: $(STAMP_DIR)/petalinux_sdk
	@echo "### Building PetaLinux SW..."
	mkdir -p $(BUILD_DIR)/bin
	source $(BUILD_DIR)/install-sdk/environment-setup-cortexa72-cortexa53-amd-linux
	$CC $(CUR_PATH)/sw/petalinux/test.c -o $(BUILD_DIR)/bin/petalinux
	@echo "### Built at:"
	@echo "$(BUILD_DIR)/bin/petalinux"
	touch $@

vitis: $(STAMP_DIR)/vitis
$(STAMP_DIR)/vitis: $(STAMP_DIR)/hardware
	@echo "### Building vitis project..."
	mkdir -p $(BUILD_DIR)/vitis
	vitis -s $(CUR_PATH)/sw/vitis/builder.py $(BUILD_DIR)/vitis $(BUILD_DIR)/hardware/top_versal.xsa $(CUR_PATH)/sw/vitis/test.c

clean:
	@echo "### Cleaning build and stamp files..."
	rm -rf $(BUILD_DIR)
