# eth pmods:
#
# pin 1: CS, pin2 : MOSI, pin3: MISO, pin4: SCLK, pin7: ~INT/SPISEL
#

# pin 1: CS
set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVCMOS33} [get_ports ja_cs]
set_property -dict {PACKAGE_PIN D14 IOSTANDARD LVCMOS33} [get_ports jb_cs]

# pin 2: MOSI
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports ja_mosi]
set_property -dict {PACKAGE_PIN F16 IOSTANDARD LVCMOS33} [get_ports jb_mosi]

# pin 3: MISO
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports ja_miso]
set_property -dict {PACKAGE_PIN G16 IOSTANDARD LVCMOS33} [get_ports jb_miso]

# pin 4: SCLK
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports ja_sclk]
set_property -dict {PACKAGE_PIN H14 IOSTANDARD LVCMOS33} [get_ports jb_sclk]

# Sch=eth_ref_clk
set_property -dict {PACKAGE_PIN D5 IOSTANDARD LVCMOS33} [get_ports {eth_ref_clk}];

set_property MARK_DEBUG true [get_nets design_1_i/packet_switcher_ip_0/inst/arbiter/FSM_sequential_port_a_schedule_state_reg__0]
set_property MARK_DEBUG true [get_nets design_1_i/packet_switcher_ip_0/inst/arbiter/FSM_sequential_port_b_schedule_state_reg__0]
set_property MARK_DEBUG true [get_nets design_1_i/packet_switcher_ip_0/inst/arbiter/port_b_controller/port_b_ready_transfer]
set_property MARK_DEBUG true [get_nets design_1_i/packet_switcher_ip_0/inst/arbiter/port_b_controller/FSM_sequential_pmod_port_state_reg__0]
create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 4096 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list design_1_i/clk_wiz/inst/clk_out2]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 1 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list design_1_i/packet_switcher_ip_0/inst/arbiter/port_b_controller/FSM_sequential_pmod_port_state_reg__0]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 1 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list design_1_i/packet_switcher_ip_0/inst/arbiter/FSM_sequential_port_a_schedule_state_reg__0]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 1 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list design_1_i/packet_switcher_ip_0/inst/arbiter/FSM_sequential_port_b_schedule_state_reg__0]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 1 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list design_1_i/packet_switcher_ip_0/inst/arbiter/port_b_controller/port_b_ready_transfer]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
