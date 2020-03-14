# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  ipgui::add_page $IPINST -name "Page 0"

  ipgui::add_param $IPINST -name "CONFIG_AXI_S_BASEADDR"
  ipgui::add_param $IPINST -name "CONFIG_AXI_S_HIGHADDR"
  ipgui::add_param $IPINST -name "CONFIG_AXI_S_DATA_WIDTH"
  ipgui::add_param $IPINST -name "CONFIG_AXI_S_ADDR_WIDTH"

}

proc update_PARAM_VALUE.CONFIG_AXI_S_ADDR_WIDTH { PARAM_VALUE.CONFIG_AXI_S_ADDR_WIDTH } {
	# Procedure called to update CONFIG_AXI_S_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CONFIG_AXI_S_ADDR_WIDTH { PARAM_VALUE.CONFIG_AXI_S_ADDR_WIDTH } {
	# Procedure called to validate CONFIG_AXI_S_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.CONFIG_AXI_S_BASEADDR { PARAM_VALUE.CONFIG_AXI_S_BASEADDR } {
	# Procedure called to update CONFIG_AXI_S_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CONFIG_AXI_S_BASEADDR { PARAM_VALUE.CONFIG_AXI_S_BASEADDR } {
	# Procedure called to validate CONFIG_AXI_S_BASEADDR
	return true
}

proc update_PARAM_VALUE.CONFIG_AXI_S_DATA_WIDTH { PARAM_VALUE.CONFIG_AXI_S_DATA_WIDTH } {
	# Procedure called to update CONFIG_AXI_S_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CONFIG_AXI_S_DATA_WIDTH { PARAM_VALUE.CONFIG_AXI_S_DATA_WIDTH } {
	# Procedure called to validate CONFIG_AXI_S_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.CONFIG_AXI_S_HIGHADDR { PARAM_VALUE.CONFIG_AXI_S_HIGHADDR } {
	# Procedure called to update CONFIG_AXI_S_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CONFIG_AXI_S_HIGHADDR { PARAM_VALUE.CONFIG_AXI_S_HIGHADDR } {
	# Procedure called to validate CONFIG_AXI_S_HIGHADDR
	return true
}


proc update_MODELPARAM_VALUE.CONFIG_AXI_S_DATA_WIDTH { MODELPARAM_VALUE.CONFIG_AXI_S_DATA_WIDTH PARAM_VALUE.CONFIG_AXI_S_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CONFIG_AXI_S_DATA_WIDTH}] ${MODELPARAM_VALUE.CONFIG_AXI_S_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.CONFIG_AXI_S_ADDR_WIDTH { MODELPARAM_VALUE.CONFIG_AXI_S_ADDR_WIDTH PARAM_VALUE.CONFIG_AXI_S_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CONFIG_AXI_S_ADDR_WIDTH}] ${MODELPARAM_VALUE.CONFIG_AXI_S_ADDR_WIDTH}
}

