

proc generate {drv_handle} {
	xdefine_include_file $drv_handle "xparameters.h" "packet_switcher_ip" "NUM_INSTANCES" "DEVICE_ID"  "CONFIG_AXI_S_BASEADDR" "CONFIG_AXI_S_HIGHADDR"
}
