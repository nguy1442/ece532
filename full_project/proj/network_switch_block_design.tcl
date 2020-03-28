
################################################################
# This is a generated script based on design: design_1
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2018.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source design_1_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7a100tcsg324-1
   set_property BOARD_PART digilentinc.com:nexys4_ddr:part0:1.1 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name design_1

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
digilentinc.com:user:PmodESP32:1.0\
xilinx.com:ip:axi_ethernetlite:3.0\
xilinx.com:ip:axi_fifo_mm_s:4.1\
xilinx.com:ip:axi_timer:2.0\
xilinx.com:ip:axi_uartlite:2.0\
xilinx.com:ip:clk_wiz:6.0\
xilinx.com:ip:microblaze:10.0\
xilinx.com:ip:mdm:3.2\
xilinx.com:ip:axi_intc:4.1\
xilinx.com:ip:xlconcat:2.1\
xilinx.com:ip:mig_7series:4.1\
xilinx.com:ip:mii_to_rmii:2.0\
xilinx.com:user:packet_switcher_ip:1.0\
xilinx.com:user:pmod_nic100_axi_stream_ip:1.0\
xilinx.com:ip:ila:6.2\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:lmb_bram_if_cntlr:4.0\
xilinx.com:ip:lmb_v10:3.0\
xilinx.com:ip:blk_mem_gen:8.4\
"

   set list_ips_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_msg_id "BD_TCL-1003" "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: wifi_microblaze_local_memory
proc create_hier_cell_wifi_microblaze_local_memory { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_wifi_microblaze_local_memory() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB

  # Create pins
  create_bd_pin -dir I -type clk LMB_Clk
  create_bd_pin -dir I -type rst SYS_Rst

  # Create instance: dlmb_bram_if_cntlr, and set properties
  set dlmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 dlmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $dlmb_bram_if_cntlr

  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 dlmb_v10 ]

  # Create instance: ilmb_bram_if_cntlr, and set properties
  set ilmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 ilmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $ilmb_bram_if_cntlr

  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 ilmb_v10 ]

  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 lmb_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.use_bram_block {BRAM_Controller} \
 ] $lmb_bram

  # Create interface connections
  connect_bd_intf_net -intf_net wifi_microblaze_dlmb [get_bd_intf_pins DLMB] [get_bd_intf_pins dlmb_v10/LMB_M]
  connect_bd_intf_net -intf_net wifi_microblaze_dlmb_bus [get_bd_intf_pins dlmb_bram_if_cntlr/SLMB] [get_bd_intf_pins dlmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net wifi_microblaze_dlmb_cntlr [get_bd_intf_pins dlmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net wifi_microblaze_ilmb [get_bd_intf_pins ILMB] [get_bd_intf_pins ilmb_v10/LMB_M]
  connect_bd_intf_net -intf_net wifi_microblaze_ilmb_bus [get_bd_intf_pins ilmb_bram_if_cntlr/SLMB] [get_bd_intf_pins ilmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net wifi_microblaze_ilmb_cntlr [get_bd_intf_pins ilmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTB]

  # Create port connections
  connect_bd_net -net SYS_Rst_1 [get_bd_pins SYS_Rst] [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst] [get_bd_pins dlmb_v10/SYS_Rst] [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst] [get_bd_pins ilmb_v10/SYS_Rst]
  connect_bd_net -net wifi_microblaze_Clk [get_bd_pins LMB_Clk] [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk] [get_bd_pins dlmb_v10/LMB_Clk] [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk] [get_bd_pins ilmb_v10/LMB_Clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: microblaze_0_local_memory
proc create_hier_cell_microblaze_0_local_memory { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_microblaze_0_local_memory() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB

  # Create pins
  create_bd_pin -dir I -type clk LMB_Clk
  create_bd_pin -dir I -type rst SYS_Rst

  # Create instance: dlmb_bram_if_cntlr, and set properties
  set dlmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 dlmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $dlmb_bram_if_cntlr

  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 dlmb_v10 ]

  # Create instance: ilmb_bram_if_cntlr, and set properties
  set ilmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 ilmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $ilmb_bram_if_cntlr

  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 ilmb_v10 ]

  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 lmb_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.use_bram_block {BRAM_Controller} \
 ] $lmb_bram

  # Create interface connections
  connect_bd_intf_net -intf_net microblaze_0_dlmb [get_bd_intf_pins DLMB] [get_bd_intf_pins dlmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_bus [get_bd_intf_pins dlmb_bram_if_cntlr/SLMB] [get_bd_intf_pins dlmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_cntlr [get_bd_intf_pins dlmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net microblaze_0_ilmb [get_bd_intf_pins ILMB] [get_bd_intf_pins ilmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_bus [get_bd_intf_pins ilmb_bram_if_cntlr/SLMB] [get_bd_intf_pins ilmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_cntlr [get_bd_intf_pins ilmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTB]

  # Create port connections
  connect_bd_net -net SYS_Rst_1 [get_bd_pins SYS_Rst] [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst] [get_bd_pins dlmb_v10/SYS_Rst] [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst] [get_bd_pins ilmb_v10/SYS_Rst]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins LMB_Clk] [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk] [get_bd_pins dlmb_v10/LMB_Clk] [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk] [get_bd_pins ilmb_v10/LMB_Clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set DDR2_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR2_0 ]
  set eth_mdio_mdc [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:mdio_rtl:1.0 eth_mdio_mdc ]
  set eth_rmii [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:rmii_rtl:1.0 eth_rmii ]
  set jc [ create_bd_intf_port -mode Master -vlnv digilentinc.com:interface:pmod_rtl:1.0 jc ]
  set usb_uart [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 usb_uart ]

  # Create ports
  set eth_ref_clk [ create_bd_port -dir O -type clk eth_ref_clk ]
  set ja_cs [ create_bd_port -dir O ja_cs ]
  set ja_miso [ create_bd_port -dir I ja_miso ]
  set ja_mosi [ create_bd_port -dir O ja_mosi ]
  set ja_sclk [ create_bd_port -dir O ja_sclk ]
  set jb_cs [ create_bd_port -dir O jb_cs ]
  set jb_miso [ create_bd_port -dir I jb_miso ]
  set jb_mosi [ create_bd_port -dir O jb_mosi ]
  set jb_sclk [ create_bd_port -dir O jb_sclk ]
  set reset [ create_bd_port -dir I -type rst reset ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $reset
  set sys_clock [ create_bd_port -dir I -type clk sys_clock ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   CONFIG.PHASE {0.000} \
 ] $sys_clock

  # Create instance: PmodESP32_0, and set properties
  set PmodESP32_0 [ create_bd_cell -type ip -vlnv digilentinc.com:user:PmodESP32:1.0 PmodESP32_0 ]
  set_property -dict [ list \
   CONFIG.PMOD {jc} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $PmodESP32_0

  # Create instance: axi_ethernetlite_0, and set properties
  set axi_ethernetlite_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernetlite:3.0 axi_ethernetlite_0 ]
  set_property -dict [ list \
   CONFIG.MDIO_BOARD_INTERFACE {eth_mdio_mdc} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_ethernetlite_0

  # Create instance: axi_fifo_mm_s_0, and set properties
  set axi_fifo_mm_s_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_fifo_mm_s:4.1 axi_fifo_mm_s_0 ]
  set_property -dict [ list \
   CONFIG.C_RX_FIFO_DEPTH {2048} \
   CONFIG.C_RX_FIFO_PE_THRESHOLD {2} \
   CONFIG.C_RX_FIFO_PF_THRESHOLD {2043} \
   CONFIG.C_TX_FIFO_DEPTH {2048} \
   CONFIG.C_TX_FIFO_PE_THRESHOLD {2} \
   CONFIG.C_TX_FIFO_PF_THRESHOLD {2043} \
   CONFIG.C_USE_TX_CTRL {0} \
 ] $axi_fifo_mm_s_0

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {2} \
 ] $axi_interconnect_0

  # Create instance: axi_interconnect_1, and set properties
  set axi_interconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_1 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {2} \
 ] $axi_interconnect_1

  # Create instance: axi_timer_0, and set properties
  set axi_timer_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer:2.0 axi_timer_0 ]

  # Create instance: axi_uartlite_0, and set properties
  set axi_uartlite_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0 ]
  set_property -dict [ list \
   CONFIG.UARTLITE_BOARD_INTERFACE {usb_uart} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_uartlite_0

  # Create instance: clk_wiz, and set properties
  set clk_wiz [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz ]
  set_property -dict [ list \
   CONFIG.CLKOUT2_JITTER {209.588} \
   CONFIG.CLKOUT2_PHASE_ERROR {98.575} \
   CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {10.000} \
   CONFIG.CLKOUT2_USED {true} \
   CONFIG.CLKOUT3_JITTER {114.829} \
   CONFIG.CLKOUT3_PHASE_ERROR {98.575} \
   CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {200.000} \
   CONFIG.CLKOUT3_USED {true} \
   CONFIG.CLKOUT4_JITTER {151.636} \
   CONFIG.CLKOUT4_PHASE_ERROR {98.575} \
   CONFIG.CLKOUT4_REQUESTED_OUT_FREQ {50} \
   CONFIG.CLKOUT4_USED {true} \
   CONFIG.CLK_IN1_BOARD_INTERFACE {sys_clock} \
   CONFIG.MMCM_CLKOUT1_DIVIDE {100} \
   CONFIG.MMCM_CLKOUT2_DIVIDE {5} \
   CONFIG.MMCM_CLKOUT3_DIVIDE {20} \
   CONFIG.MMCM_DIVCLK_DIVIDE {1} \
   CONFIG.NUM_OUT_CLKS {4} \
   CONFIG.RESET_BOARD_INTERFACE {reset} \
   CONFIG.RESET_PORT {resetn} \
   CONFIG.RESET_TYPE {ACTIVE_LOW} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $clk_wiz

  # Create instance: config_microblaze, and set properties
  set config_microblaze [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:10.0 config_microblaze ]
  set_property -dict [ list \
   CONFIG.C_DEBUG_ENABLED {1} \
   CONFIG.C_D_AXI {1} \
   CONFIG.C_D_LMB {1} \
   CONFIG.C_I_AXI {1} \
   CONFIG.C_I_LMB {1} \
 ] $config_microblaze

  # Create instance: mdm_1, and set properties
  set mdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm:3.2 mdm_1 ]
  set_property -dict [ list \
   CONFIG.C_MB_DBG_PORTS {2} \
 ] $mdm_1

  # Create instance: microblaze_0_axi_intc, and set properties
  set microblaze_0_axi_intc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 microblaze_0_axi_intc ]
  set_property -dict [ list \
   CONFIG.C_HAS_FAST {1} \
 ] $microblaze_0_axi_intc

  # Create instance: microblaze_0_axi_periph, and set properties
  set microblaze_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 microblaze_0_axi_periph ]
  set_property -dict [ list \
   CONFIG.NUM_MI {6} \
   CONFIG.NUM_SI {2} \
 ] $microblaze_0_axi_periph

  # Create instance: microblaze_0_local_memory
  create_hier_cell_microblaze_0_local_memory [current_bd_instance .] microblaze_0_local_memory

  # Create instance: microblaze_0_xlconcat, and set properties
  set microblaze_0_xlconcat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 microblaze_0_xlconcat ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {3} \
 ] $microblaze_0_xlconcat

  # Create instance: mig_7series_0, and set properties
  set mig_7series_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mig_7series:4.1 mig_7series_0 ]
  set_property -dict [ list \
   CONFIG.RESET_BOARD_INTERFACE {reset} \
 ] $mig_7series_0

  # Create instance: mii_to_rmii_0, and set properties
  set mii_to_rmii_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mii_to_rmii:2.0 mii_to_rmii_0 ]
  set_property -dict [ list \
   CONFIG.RESET_BOARD_INTERFACE {reset} \
   CONFIG.RMII_BOARD_INTERFACE {eth_rmii} \
 ] $mii_to_rmii_0

  # Create instance: packet_switcher_ip_0, and set properties
  set packet_switcher_ip_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:packet_switcher_ip:1.0 packet_switcher_ip_0 ]

  # Create instance: pmod_nic100_axi_stre_0, and set properties
  set pmod_nic100_axi_stre_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:pmod_nic100_axi_stream_ip:1.0 pmod_nic100_axi_stre_0 ]

  # Create instance: pmod_nic100_axi_stre_1, and set properties
  set pmod_nic100_axi_stre_1 [ create_bd_cell -type ip -vlnv xilinx.com:user:pmod_nic100_axi_stream_ip:1.0 pmod_nic100_axi_stre_1 ]

  # Create instance: pmod_port_a_in, and set properties
  set pmod_port_a_in [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 pmod_port_a_in ]
  set_property -dict [ list \
   CONFIG.C_DATA_DEPTH {4096} \
   CONFIG.C_NUM_OF_PROBES {9} \
   CONFIG.C_SLOT_0_AXI_PROTOCOL {AXI4S} \
 ] $pmod_port_a_in

  # Create instance: pmod_port_a_out, and set properties
  set pmod_port_a_out [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 pmod_port_a_out ]
  set_property -dict [ list \
   CONFIG.C_DATA_DEPTH {4096} \
   CONFIG.C_NUM_OF_PROBES {9} \
   CONFIG.C_SLOT_0_AXI_PROTOCOL {AXI4S} \
 ] $pmod_port_a_out

  # Create instance: pmod_port_b_in, and set properties
  set pmod_port_b_in [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 pmod_port_b_in ]
  set_property -dict [ list \
   CONFIG.C_DATA_DEPTH {4096} \
   CONFIG.C_NUM_OF_PROBES {9} \
   CONFIG.C_SLOT_0_AXI_PROTOCOL {AXI4S} \
 ] $pmod_port_b_in

  # Create instance: pmod_port_b_out, and set properties
  set pmod_port_b_out [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 pmod_port_b_out ]
  set_property -dict [ list \
   CONFIG.C_DATA_DEPTH {4096} \
   CONFIG.C_NUM_OF_PROBES {9} \
   CONFIG.C_SLOT_0_AXI_PROTOCOL {AXI4S} \
 ] $pmod_port_b_out

  # Create instance: pmod_port_c_in, and set properties
  set pmod_port_c_in [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 pmod_port_c_in ]
  set_property -dict [ list \
   CONFIG.C_DATA_DEPTH {4096} \
   CONFIG.C_NUM_OF_PROBES {9} \
   CONFIG.C_SLOT_0_AXI_PROTOCOL {AXI4S} \
 ] $pmod_port_c_in

  # Create instance: pmod_port_c_out, and set properties
  set pmod_port_c_out [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 pmod_port_c_out ]
  set_property -dict [ list \
   CONFIG.C_DATA_DEPTH {4096} \
   CONFIG.C_NUM_OF_PROBES {9} \
   CONFIG.C_SLOT_0_AXI_PROTOCOL {AXI4S} \
 ] $pmod_port_c_out

  # Create instance: rst_clk_wiz_100M, and set properties
  set rst_clk_wiz_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_100M ]
  set_property -dict [ list \
   CONFIG.RESET_BOARD_INTERFACE {reset} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $rst_clk_wiz_100M

  # Create instance: rst_clk_wiz_100M_1, and set properties
  set rst_clk_wiz_100M_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_100M_1 ]
  set_property -dict [ list \
   CONFIG.RESET_BOARD_INTERFACE {reset} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $rst_clk_wiz_100M_1

  # Create instance: rst_clk_wiz_200M, and set properties
  set rst_clk_wiz_200M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_200M ]
  set_property -dict [ list \
   CONFIG.RESET_BOARD_INTERFACE {reset} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $rst_clk_wiz_200M

  # Create instance: rst_mig_7series_0_81M, and set properties
  set rst_mig_7series_0_81M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_mig_7series_0_81M ]

  # Create instance: wifi_microblaze, and set properties
  set wifi_microblaze [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:10.0 wifi_microblaze ]
  set_property -dict [ list \
   CONFIG.C_ADDR_TAG_BITS {0} \
   CONFIG.C_CACHE_BYTE_SIZE {8192} \
   CONFIG.C_DCACHE_ADDR_TAG {0} \
   CONFIG.C_DCACHE_BYTE_SIZE {8192} \
   CONFIG.C_DEBUG_ENABLED {1} \
   CONFIG.C_D_AXI {1} \
   CONFIG.C_D_LMB {1} \
   CONFIG.C_I_AXI {1} \
   CONFIG.C_I_LMB {1} \
   CONFIG.C_USE_DCACHE {0} \
   CONFIG.C_USE_ICACHE {0} \
 ] $wifi_microblaze

  # Create instance: wifi_microblaze_axi_intc, and set properties
  set wifi_microblaze_axi_intc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 wifi_microblaze_axi_intc ]
  set_property -dict [ list \
   CONFIG.C_HAS_FAST {1} \
 ] $wifi_microblaze_axi_intc

  # Create instance: wifi_microblaze_axi_periph, and set properties
  set wifi_microblaze_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 wifi_microblaze_axi_periph ]
  set_property -dict [ list \
   CONFIG.NUM_MI {6} \
   CONFIG.NUM_SI {2} \
 ] $wifi_microblaze_axi_periph

  # Create instance: wifi_microblaze_local_memory
  create_hier_cell_wifi_microblaze_local_memory [current_bd_instance .] wifi_microblaze_local_memory

  # Create instance: wifi_microblaze_xlconcat, and set properties
  set wifi_microblaze_xlconcat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 wifi_microblaze_xlconcat ]

  catch {apply_bd_automation -rule xilinx.com:bd_rule:mig_7series -config {Board_Interface "ddr2_sdram" }  [get_bd_cells mig_7series_0]}

  # Create interface connections
  connect_bd_intf_net -intf_net Conn [get_bd_intf_pins axi_fifo_mm_s_0/AXI_STR_TXD] [get_bd_intf_pins packet_switcher_ip_0/pmod_c_axis_s]
connect_bd_intf_net -intf_net [get_bd_intf_nets Conn] [get_bd_intf_pins axi_fifo_mm_s_0/AXI_STR_TXD] [get_bd_intf_pins pmod_port_c_in/SLOT_0_AXIS]
  connect_bd_intf_net -intf_net PmodESP32_0_Pmod_out [get_bd_intf_ports jc] [get_bd_intf_pins PmodESP32_0/Pmod_out]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins axi_interconnect_1/S00_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net axi_ethernetlite_0_MDIO [get_bd_intf_ports eth_mdio_mdc] [get_bd_intf_pins axi_ethernetlite_0/MDIO]
  connect_bd_intf_net -intf_net axi_ethernetlite_0_MII [get_bd_intf_pins axi_ethernetlite_0/MII] [get_bd_intf_pins mii_to_rmii_0/MII]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins mig_7series_0/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M00_AXI [get_bd_intf_pins axi_interconnect_1/M00_AXI] [get_bd_intf_pins axi_uartlite_0/S_AXI]
  connect_bd_intf_net -intf_net axi_uartlite_0_UART [get_bd_intf_ports usb_uart] [get_bd_intf_pins axi_uartlite_0/UART]
  connect_bd_intf_net -intf_net config_microblaze_M_AXI_IP [get_bd_intf_pins config_microblaze/M_AXI_IP] [get_bd_intf_pins microblaze_0_axi_periph/S01_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_dp [get_bd_intf_pins config_microblaze/M_AXI_DP] [get_bd_intf_pins microblaze_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M02_AXI [get_bd_intf_pins microblaze_0_axi_periph/M02_AXI] [get_bd_intf_pins packet_switcher_ip_0/config_axi_s]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M03_AXI [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M04_AXI [get_bd_intf_pins axi_ethernetlite_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M04_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M05_AXI [get_bd_intf_pins axi_timer_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M05_AXI]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins config_microblaze/DEBUG] [get_bd_intf_pins mdm_1/MBDEBUG_0]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins config_microblaze/DLMB] [get_bd_intf_pins microblaze_0_local_memory/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins config_microblaze/ILMB] [get_bd_intf_pins microblaze_0_local_memory/ILMB]
  connect_bd_intf_net -intf_net microblaze_0_intc_axi [get_bd_intf_pins microblaze_0_axi_intc/s_axi] [get_bd_intf_pins microblaze_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_interrupt [get_bd_intf_pins config_microblaze/INTERRUPT] [get_bd_intf_pins microblaze_0_axi_intc/interrupt]
  connect_bd_intf_net -intf_net mig_7series_0_DDR2 [get_bd_intf_ports DDR2_0] [get_bd_intf_pins mig_7series_0/DDR2]
  connect_bd_intf_net -intf_net mii_to_rmii_0_RMII_PHY_M [get_bd_intf_ports eth_rmii] [get_bd_intf_pins mii_to_rmii_0/RMII_PHY_M]
  connect_bd_intf_net -intf_net packet_switcher_ip_0_pmod_a_axis_m [get_bd_intf_pins packet_switcher_ip_0/pmod_a_axis_m] [get_bd_intf_pins pmod_nic100_axi_stre_1/s_axis]
connect_bd_intf_net -intf_net [get_bd_intf_nets packet_switcher_ip_0_pmod_a_axis_m] [get_bd_intf_pins packet_switcher_ip_0/pmod_a_axis_m] [get_bd_intf_pins pmod_port_a_out/SLOT_0_AXIS]
  connect_bd_intf_net -intf_net packet_switcher_ip_0_pmod_b_axis_m [get_bd_intf_pins packet_switcher_ip_0/pmod_b_axis_m] [get_bd_intf_pins pmod_nic100_axi_stre_0/s_axis]
connect_bd_intf_net -intf_net [get_bd_intf_nets packet_switcher_ip_0_pmod_b_axis_m] [get_bd_intf_pins packet_switcher_ip_0/pmod_b_axis_m] [get_bd_intf_pins pmod_port_b_out/SLOT_0_AXIS]
  connect_bd_intf_net -intf_net packet_switcher_ip_0_pmod_c_axis_m [get_bd_intf_pins axi_fifo_mm_s_0/AXI_STR_RXD] [get_bd_intf_pins packet_switcher_ip_0/pmod_c_axis_m]
connect_bd_intf_net -intf_net [get_bd_intf_nets packet_switcher_ip_0_pmod_c_axis_m] [get_bd_intf_pins axi_fifo_mm_s_0/AXI_STR_RXD] [get_bd_intf_pins pmod_port_c_out/SLOT_0_AXIS]
  connect_bd_intf_net -intf_net pmod_nic100_axi_stre_0_m_axis [get_bd_intf_pins packet_switcher_ip_0/pmod_b_axis_s] [get_bd_intf_pins pmod_nic100_axi_stre_0/m_axis]
connect_bd_intf_net -intf_net [get_bd_intf_nets pmod_nic100_axi_stre_0_m_axis] [get_bd_intf_pins pmod_nic100_axi_stre_0/m_axis] [get_bd_intf_pins pmod_port_b_in/SLOT_0_AXIS]
  connect_bd_intf_net -intf_net pmod_nic100_axi_stre_1_m_axis [get_bd_intf_pins packet_switcher_ip_0/pmod_a_axis_s] [get_bd_intf_pins pmod_nic100_axi_stre_1/m_axis]
connect_bd_intf_net -intf_net [get_bd_intf_nets pmod_nic100_axi_stre_1_m_axis] [get_bd_intf_pins pmod_nic100_axi_stre_1/m_axis] [get_bd_intf_pins pmod_port_a_in/SLOT_0_AXIS]
  connect_bd_intf_net -intf_net wifi_microblaze_M_AXI_DP [get_bd_intf_pins wifi_microblaze/M_AXI_DP] [get_bd_intf_pins wifi_microblaze_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net wifi_microblaze_M_AXI_IP [get_bd_intf_pins wifi_microblaze/M_AXI_IP] [get_bd_intf_pins wifi_microblaze_axi_periph/S01_AXI]
  connect_bd_intf_net -intf_net wifi_microblaze_axi_periph_M01_AXI [get_bd_intf_pins axi_interconnect_0/S01_AXI] [get_bd_intf_pins wifi_microblaze_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net wifi_microblaze_axi_periph_M02_AXI [get_bd_intf_pins axi_fifo_mm_s_0/S_AXI] [get_bd_intf_pins wifi_microblaze_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net wifi_microblaze_axi_periph_M03_AXI [get_bd_intf_pins axi_interconnect_1/S01_AXI] [get_bd_intf_pins wifi_microblaze_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net wifi_microblaze_axi_periph_M04_AXI [get_bd_intf_pins PmodESP32_0/AXI_LITE_UART] [get_bd_intf_pins wifi_microblaze_axi_periph/M04_AXI]
  connect_bd_intf_net -intf_net wifi_microblaze_axi_periph_M05_AXI [get_bd_intf_pins PmodESP32_0/AXI_LITE_GPIO] [get_bd_intf_pins wifi_microblaze_axi_periph/M05_AXI]
  connect_bd_intf_net -intf_net wifi_microblaze_debug [get_bd_intf_pins mdm_1/MBDEBUG_1] [get_bd_intf_pins wifi_microblaze/DEBUG]
  connect_bd_intf_net -intf_net wifi_microblaze_dlmb_1 [get_bd_intf_pins wifi_microblaze/DLMB] [get_bd_intf_pins wifi_microblaze_local_memory/DLMB]
  connect_bd_intf_net -intf_net wifi_microblaze_ilmb_1 [get_bd_intf_pins wifi_microblaze/ILMB] [get_bd_intf_pins wifi_microblaze_local_memory/ILMB]
  connect_bd_intf_net -intf_net wifi_microblaze_intc_axi [get_bd_intf_pins wifi_microblaze_axi_intc/s_axi] [get_bd_intf_pins wifi_microblaze_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net wifi_microblaze_interrupt [get_bd_intf_pins wifi_microblaze/INTERRUPT] [get_bd_intf_pins wifi_microblaze_axi_intc/interrupt]

  # Create port connections
  connect_bd_net -net axi_ethernetlite_0_ip2intc_irpt [get_bd_pins axi_ethernetlite_0/ip2intc_irpt] [get_bd_pins microblaze_0_xlconcat/In1]
  connect_bd_net -net axi_fifo_mm_s_0_interrupt [get_bd_pins axi_fifo_mm_s_0/interrupt] [get_bd_pins wifi_microblaze_xlconcat/In0]
  connect_bd_net -net axi_timer_0_interrupt [get_bd_pins axi_timer_0/interrupt] [get_bd_pins microblaze_0_xlconcat/In0]
  connect_bd_net -net axi_uartlite_0_interrupt [get_bd_pins axi_uartlite_0/interrupt] [get_bd_pins microblaze_0_xlconcat/In2] [get_bd_pins wifi_microblaze_xlconcat/In1]
  connect_bd_net -net clk_wiz_clk_out2 [get_bd_pins axi_fifo_mm_s_0/s_axi_aclk] [get_bd_pins clk_wiz/clk_out2] [get_bd_pins microblaze_0_axi_periph/M02_ACLK] [get_bd_pins packet_switcher_ip_0/clk] [get_bd_pins pmod_nic100_axi_stre_0/axis_aclk] [get_bd_pins pmod_nic100_axi_stre_1/axis_aclk] [get_bd_pins pmod_port_a_in/clk] [get_bd_pins pmod_port_a_out/clk] [get_bd_pins pmod_port_b_in/clk] [get_bd_pins pmod_port_b_out/clk] [get_bd_pins pmod_port_c_in/clk] [get_bd_pins pmod_port_c_out/clk] [get_bd_pins rst_clk_wiz_100M/slowest_sync_clk] [get_bd_pins wifi_microblaze_axi_periph/M02_ACLK]
  connect_bd_net -net clk_wiz_clk_out3 [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_interconnect_0/S01_ACLK] [get_bd_pins clk_wiz/clk_out3] [get_bd_pins microblaze_0_axi_periph/M03_ACLK] [get_bd_pins mig_7series_0/sys_clk_i] [get_bd_pins rst_clk_wiz_200M/slowest_sync_clk] [get_bd_pins wifi_microblaze_axi_periph/M01_ACLK]
  connect_bd_net -net clk_wiz_clk_out4 [get_bd_ports eth_ref_clk] [get_bd_pins clk_wiz/clk_out4] [get_bd_pins mii_to_rmii_0/ref_clk]
  connect_bd_net -net clk_wiz_locked [get_bd_pins clk_wiz/locked] [get_bd_pins rst_clk_wiz_100M/dcm_locked] [get_bd_pins rst_clk_wiz_100M_1/dcm_locked] [get_bd_pins rst_clk_wiz_200M/dcm_locked]
  connect_bd_net -net ja_miso_1 [get_bd_ports ja_miso] [get_bd_pins pmod_nic100_axi_stre_1/pmod_miso]
  connect_bd_net -net jb_miso_1 [get_bd_ports jb_miso] [get_bd_pins pmod_nic100_axi_stre_0/pmod_miso]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins mdm_1/Debug_SYS_Rst] [get_bd_pins rst_clk_wiz_100M_1/mb_debug_sys_rst]
  connect_bd_net -net microblaze_0_intr [get_bd_pins microblaze_0_axi_intc/intr] [get_bd_pins microblaze_0_xlconcat/dout]
  connect_bd_net -net mig_7series_0_mmcm_locked [get_bd_pins mig_7series_0/mmcm_locked] [get_bd_pins rst_mig_7series_0_81M/dcm_locked]
  connect_bd_net -net mig_7series_0_ui_clk [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins mig_7series_0/ui_clk] [get_bd_pins rst_mig_7series_0_81M/slowest_sync_clk]
  connect_bd_net -net mig_7series_0_ui_clk_sync_rst [get_bd_pins mig_7series_0/ui_clk_sync_rst] [get_bd_pins rst_mig_7series_0_81M/ext_reset_in]
  connect_bd_net -net pmod_nic100_axi_stre_0_pmod_mosi [get_bd_ports jb_mosi] [get_bd_pins pmod_nic100_axi_stre_0/pmod_mosi]
  connect_bd_net -net pmod_nic100_axi_stre_0_pmod_sck [get_bd_ports jb_sclk] [get_bd_pins pmod_nic100_axi_stre_0/pmod_sck]
  connect_bd_net -net pmod_nic100_axi_stre_0_pmod_ss [get_bd_ports jb_cs] [get_bd_pins pmod_nic100_axi_stre_0/pmod_ss]
  connect_bd_net -net pmod_nic100_axi_stre_1_pmod_mosi [get_bd_ports ja_mosi] [get_bd_pins pmod_nic100_axi_stre_1/pmod_mosi]
  connect_bd_net -net pmod_nic100_axi_stre_1_pmod_sck [get_bd_ports ja_sclk] [get_bd_pins pmod_nic100_axi_stre_1/pmod_sck]
  connect_bd_net -net pmod_nic100_axi_stre_1_pmod_ss [get_bd_ports ja_cs] [get_bd_pins pmod_nic100_axi_stre_1/pmod_ss]
  connect_bd_net -net reset_1 [get_bd_ports reset] [get_bd_pins clk_wiz/resetn] [get_bd_pins mig_7series_0/sys_rst] [get_bd_pins mii_to_rmii_0/rst_n] [get_bd_pins rst_clk_wiz_100M/ext_reset_in] [get_bd_pins rst_clk_wiz_100M_1/ext_reset_in] [get_bd_pins rst_clk_wiz_200M/ext_reset_in]
  connect_bd_net -net rst_clk_wiz_100M_1_bus_struct_reset [get_bd_pins microblaze_0_local_memory/SYS_Rst] [get_bd_pins rst_clk_wiz_100M_1/bus_struct_reset] [get_bd_pins wifi_microblaze_local_memory/SYS_Rst]
  connect_bd_net -net rst_clk_wiz_100M_1_interconnect_aresetn [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_1/ARESETN] [get_bd_pins microblaze_0_axi_periph/ARESETN] [get_bd_pins rst_clk_wiz_100M_1/interconnect_aresetn] [get_bd_pins wifi_microblaze_axi_periph/ARESETN]
  connect_bd_net -net rst_clk_wiz_100M_1_mb_reset [get_bd_pins config_microblaze/Reset] [get_bd_pins microblaze_0_axi_intc/processor_rst] [get_bd_pins rst_clk_wiz_100M_1/mb_reset] [get_bd_pins wifi_microblaze/Reset] [get_bd_pins wifi_microblaze_axi_intc/processor_rst]
  connect_bd_net -net rst_clk_wiz_100M_1_peripheral_aresetn [get_bd_pins PmodESP32_0/s_axi_aresetn] [get_bd_pins axi_ethernetlite_0/s_axi_aresetn] [get_bd_pins axi_interconnect_1/M00_ARESETN] [get_bd_pins axi_interconnect_1/S00_ARESETN] [get_bd_pins axi_interconnect_1/S01_ARESETN] [get_bd_pins axi_timer_0/s_axi_aresetn] [get_bd_pins axi_uartlite_0/s_axi_aresetn] [get_bd_pins microblaze_0_axi_intc/s_axi_aresetn] [get_bd_pins microblaze_0_axi_periph/M00_ARESETN] [get_bd_pins microblaze_0_axi_periph/M01_ARESETN] [get_bd_pins microblaze_0_axi_periph/M04_ARESETN] [get_bd_pins microblaze_0_axi_periph/M05_ARESETN] [get_bd_pins microblaze_0_axi_periph/S00_ARESETN] [get_bd_pins microblaze_0_axi_periph/S01_ARESETN] [get_bd_pins rst_clk_wiz_100M_1/peripheral_aresetn] [get_bd_pins wifi_microblaze_axi_intc/s_axi_aresetn] [get_bd_pins wifi_microblaze_axi_periph/M00_ARESETN] [get_bd_pins wifi_microblaze_axi_periph/M03_ARESETN] [get_bd_pins wifi_microblaze_axi_periph/M04_ARESETN] [get_bd_pins wifi_microblaze_axi_periph/M05_ARESETN] [get_bd_pins wifi_microblaze_axi_periph/S00_ARESETN] [get_bd_pins wifi_microblaze_axi_periph/S01_ARESETN]
  connect_bd_net -net rst_clk_wiz_100M_peripheral_aresetn [get_bd_pins axi_fifo_mm_s_0/s_axi_aresetn] [get_bd_pins microblaze_0_axi_periph/M02_ARESETN] [get_bd_pins packet_switcher_ip_0/resetn] [get_bd_pins pmod_nic100_axi_stre_0/axis_resetn] [get_bd_pins pmod_nic100_axi_stre_1/axis_resetn] [get_bd_pins rst_clk_wiz_100M/peripheral_aresetn] [get_bd_pins wifi_microblaze_axi_periph/M02_ARESETN]
  connect_bd_net -net rst_clk_wiz_200M_peripheral_aresetn [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_interconnect_0/S01_ARESETN] [get_bd_pins microblaze_0_axi_periph/M03_ARESETN] [get_bd_pins rst_clk_wiz_200M/peripheral_aresetn] [get_bd_pins wifi_microblaze_axi_periph/M01_ARESETN]
  connect_bd_net -net rst_mig_7series_0_81M_peripheral_aresetn [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins mig_7series_0/aresetn] [get_bd_pins rst_mig_7series_0_81M/peripheral_aresetn]
  connect_bd_net -net sys_clock_1 [get_bd_ports sys_clock] [get_bd_pins clk_wiz/clk_in1]
  connect_bd_net -net wifi_microblaze_Clk [get_bd_pins PmodESP32_0/s_axi_aclk] [get_bd_pins axi_ethernetlite_0/s_axi_aclk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_1/ACLK] [get_bd_pins axi_interconnect_1/M00_ACLK] [get_bd_pins axi_interconnect_1/S00_ACLK] [get_bd_pins axi_interconnect_1/S01_ACLK] [get_bd_pins axi_timer_0/s_axi_aclk] [get_bd_pins axi_uartlite_0/s_axi_aclk] [get_bd_pins clk_wiz/clk_out1] [get_bd_pins config_microblaze/Clk] [get_bd_pins microblaze_0_axi_intc/processor_clk] [get_bd_pins microblaze_0_axi_intc/s_axi_aclk] [get_bd_pins microblaze_0_axi_periph/ACLK] [get_bd_pins microblaze_0_axi_periph/M00_ACLK] [get_bd_pins microblaze_0_axi_periph/M01_ACLK] [get_bd_pins microblaze_0_axi_periph/M04_ACLK] [get_bd_pins microblaze_0_axi_periph/M05_ACLK] [get_bd_pins microblaze_0_axi_periph/S00_ACLK] [get_bd_pins microblaze_0_axi_periph/S01_ACLK] [get_bd_pins microblaze_0_local_memory/LMB_Clk] [get_bd_pins rst_clk_wiz_100M_1/slowest_sync_clk] [get_bd_pins wifi_microblaze/Clk] [get_bd_pins wifi_microblaze_axi_intc/processor_clk] [get_bd_pins wifi_microblaze_axi_intc/s_axi_aclk] [get_bd_pins wifi_microblaze_axi_periph/ACLK] [get_bd_pins wifi_microblaze_axi_periph/M00_ACLK] [get_bd_pins wifi_microblaze_axi_periph/M03_ACLK] [get_bd_pins wifi_microblaze_axi_periph/M04_ACLK] [get_bd_pins wifi_microblaze_axi_periph/M05_ACLK] [get_bd_pins wifi_microblaze_axi_periph/S00_ACLK] [get_bd_pins wifi_microblaze_axi_periph/S01_ACLK] [get_bd_pins wifi_microblaze_local_memory/LMB_Clk]
  connect_bd_net -net wifi_microblaze_intr [get_bd_pins wifi_microblaze_axi_intc/intr] [get_bd_pins wifi_microblaze_xlconcat/dout]

  # Create address segments
  create_bd_addr_seg -range 0x00010000 -offset 0x40E00000 [get_bd_addr_spaces config_microblaze/Data] [get_bd_addr_segs axi_ethernetlite_0/S_AXI/Reg] SEG_axi_ethernetlite_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40E00000 [get_bd_addr_spaces config_microblaze/Instruction] [get_bd_addr_segs axi_ethernetlite_0/S_AXI/Reg] SEG_axi_ethernetlite_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41C00000 [get_bd_addr_spaces config_microblaze/Data] [get_bd_addr_segs axi_timer_0/S_AXI/Reg] SEG_axi_timer_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41C00000 [get_bd_addr_spaces config_microblaze/Instruction] [get_bd_addr_segs axi_timer_0/S_AXI/Reg] SEG_axi_timer_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40600000 [get_bd_addr_spaces config_microblaze/Data] [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] SEG_axi_uartlite_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40600000 [get_bd_addr_spaces config_microblaze/Instruction] [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] SEG_axi_uartlite_0_Reg
  create_bd_addr_seg -range 0x00008000 -offset 0x00000000 [get_bd_addr_spaces config_microblaze/Data] [get_bd_addr_segs microblaze_0_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] SEG_dlmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x00008000 -offset 0x00000000 [get_bd_addr_spaces config_microblaze/Instruction] [get_bd_addr_segs microblaze_0_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] SEG_ilmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x00010000 -offset 0x41200000 [get_bd_addr_spaces config_microblaze/Data] [get_bd_addr_segs microblaze_0_axi_intc/S_AXI/Reg] SEG_microblaze_0_axi_intc_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41200000 [get_bd_addr_spaces config_microblaze/Instruction] [get_bd_addr_segs microblaze_0_axi_intc/S_AXI/Reg] SEG_microblaze_0_axi_intc_Reg
  create_bd_addr_seg -range 0x04000000 -offset 0x80000000 [get_bd_addr_spaces config_microblaze/Data] [get_bd_addr_segs mig_7series_0/memmap/memaddr] SEG_mig_7series_0_memaddr
  create_bd_addr_seg -range 0x04000000 -offset 0x80000000 [get_bd_addr_spaces config_microblaze/Instruction] [get_bd_addr_segs mig_7series_0/memmap/memaddr] SEG_mig_7series_0_memaddr
  create_bd_addr_seg -range 0x00010000 -offset 0x44A00000 [get_bd_addr_spaces config_microblaze/Data] [get_bd_addr_segs packet_switcher_ip_0/config_axi_s/reg0] SEG_packet_switcher_ip_0_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x44A00000 [get_bd_addr_spaces config_microblaze/Instruction] [get_bd_addr_segs packet_switcher_ip_0/config_axi_s/reg0] SEG_packet_switcher_ip_0_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x44A20000 [get_bd_addr_spaces wifi_microblaze/Data] [get_bd_addr_segs PmodESP32_0/AXI_LITE_UART/Reg0] SEG_PmodESP32_0_Reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x44A20000 [get_bd_addr_spaces wifi_microblaze/Instruction] [get_bd_addr_segs PmodESP32_0/AXI_LITE_UART/Reg0] SEG_PmodESP32_0_Reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x44A30000 [get_bd_addr_spaces wifi_microblaze/Data] [get_bd_addr_segs PmodESP32_0/AXI_LITE_GPIO/Reg0] SEG_PmodESP32_0_Reg01
  create_bd_addr_seg -range 0x00010000 -offset 0x44A30000 [get_bd_addr_spaces wifi_microblaze/Instruction] [get_bd_addr_segs PmodESP32_0/AXI_LITE_GPIO/Reg0] SEG_PmodESP32_0_Reg03
  create_bd_addr_seg -range 0x00010000 -offset 0x44A10000 [get_bd_addr_spaces wifi_microblaze/Data] [get_bd_addr_segs axi_fifo_mm_s_0/S_AXI/Mem0] SEG_axi_fifo_mm_s_0_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x44A10000 [get_bd_addr_spaces wifi_microblaze/Instruction] [get_bd_addr_segs axi_fifo_mm_s_0/S_AXI/Mem0] SEG_axi_fifo_mm_s_0_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x40600000 [get_bd_addr_spaces wifi_microblaze/Data] [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] SEG_axi_uartlite_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40600000 [get_bd_addr_spaces wifi_microblaze/Instruction] [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] SEG_axi_uartlite_0_Reg
  create_bd_addr_seg -range 0x00008000 -offset 0x00000000 [get_bd_addr_spaces wifi_microblaze/Data] [get_bd_addr_segs wifi_microblaze_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] SEG_dlmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x00008000 -offset 0x00000000 [get_bd_addr_spaces wifi_microblaze/Instruction] [get_bd_addr_segs wifi_microblaze_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] SEG_ilmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x04000000 -offset 0x84000000 [get_bd_addr_spaces wifi_microblaze/Data] [get_bd_addr_segs mig_7series_0/memmap/memaddr] SEG_mig_7series_0_memaddr
  create_bd_addr_seg -range 0x04000000 -offset 0x84000000 [get_bd_addr_spaces wifi_microblaze/Instruction] [get_bd_addr_segs mig_7series_0/memmap/memaddr] SEG_mig_7series_0_memaddr
  create_bd_addr_seg -range 0x00010000 -offset 0x41210000 [get_bd_addr_spaces wifi_microblaze/Data] [get_bd_addr_segs wifi_microblaze_axi_intc/S_AXI/Reg] SEG_wifi_microblaze_axi_intc_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41210000 [get_bd_addr_spaces wifi_microblaze/Instruction] [get_bd_addr_segs wifi_microblaze_axi_intc/S_AXI/Reg] SEG_wifi_microblaze_axi_intc_Reg


  # Restore current instance
  current_bd_instance $oldCurInst

  regenerate_bd_layout

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""



