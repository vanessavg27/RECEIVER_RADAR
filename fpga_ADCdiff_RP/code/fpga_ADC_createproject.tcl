# Set the reference directory for source file relative paths (by default the value is script dire>
set origin_dir [pwd]

# Use origin directory path location variable, if specified in the tcl shell
if { [info exists ::origin_dir_loc] } {
  set origin_dir $::origin_dir_loc
}

# Set the project name
set _xil_proj_name_ "fpga_ADCdiff"

# Set the Design name
set bdname "design_1"

# Use project name variable, if specified in the tcl shell
if { [info exists ::user_project_name] } {
  set _xil_proj_name_ $::user_project_name
}

# Set the BOARD name
set board "xc7z020clg400-3"
#**********************************************************************************
create_project -force $_xil_proj_name_ $origin_dir/project -part $board

if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1}

file mkdir $origin_dir/project/$_xil_proj_name_.srcs/sources_1/ip
file mkdir $origin_dir/project/$_xil_proj_name_.srcs/sources_1/new
file mkdir $origin_dir/project/$_xil_proj_name_.srcs/sources_1/bd
file mkdir $origin_dir/project/$_xil_proj_name_.srcs/constrs_1/new

add_files -fileset constrs_1 $origin_dir/source/constrs/io.xdc

set systemverilog_files [glob -nocomplain $origin_dir/source/design/*.sv]
set vhdl_files [glob -nocomplain $origin_dir/source/design/*.vhd]

foreach file $systemverilog_files { add_files -fileset sources_1 $file }
foreach file $vhdl_files { add_files -fileset sources_1 $file }

#**********************************************************************************
create_bd_design $bdname
update_compile_order -fileset sources_1
open_bd_design $origin_dir/project/$_xil_proj_name_.srcs/sources_1/bd/$bdname/$bdname.bd
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0

source $origin_dir/PS_RP_config.tcl
set_ps_config processing_system7_0

create_bd_cell -type module -reference ADC_set ADC_set_0

create_bd_port -dir I trig_i
create_bd_port -dir I pll_ref_i
create_bd_port -dir I adc_clk_p_i
create_bd_port -dir I adc_clk_n_i
create_bd_port -dir I -from 6 -to 0 adc_dat_a_p_i
create_bd_port -dir I -from 6 -to 0 adc_dat_a_n_i
create_bd_port -dir I -from 6 -to 0 adc_dat_b_p_i
create_bd_port -dir I -from 6 -to 0 adc_dat_b_n_i

create_bd_port -dir O pll_hi_o
create_bd_port -dir O pll_lo_o
create_bd_port -dir O -from 13 -to 0 dac_dat_a
create_bd_port -dir O -from 13 -to 0 dac_dat_b

# Connect
connect_bd_net [get_bd_ports trig_i] [get_bd_pins ADC_set_0/trig_i]
connect_bd_net [get_bd_ports pll_ref_i] [get_bd_pins ADC_set_0/pll_ref_i]
connect_bd_net [get_bd_ports adc_clk_p_i] [get_bd_pins ADC_set_0/adc_clk_p_i]
connect_bd_net [get_bd_ports adc_clk_n_i] [get_bd_pins ADC_set_0/adc_clk_n_i]

connect_bd_net [get_bd_ports adc_dat_b_p_i] [get_bd_pins ADC_set_0/adc_dat_b_p_i]
connect_bd_net [get_bd_ports adc_dat_b_n_i] [get_bd_pins ADC_set_0/adc_dat_b_n_i]
connect_bd_net [get_bd_ports adc_dat_a_n_i] [get_bd_pins ADC_set_0/adc_dat_a_n_i]
connect_bd_net [get_bd_ports adc_dat_a_p_i] [get_bd_pins ADC_set_0/adc_dat_a_p_i]

connect_bd_net [get_bd_ports pll_hi_o] [get_bd_pins ADC_set_0/pll_hi_o]
connect_bd_net [get_bd_ports pll_lo_o] [get_bd_pins ADC_set_0/pll_lo_o]
connect_bd_net [get_bd_ports dac_dat_a] [get_bd_pins ADC_set_0/adc_signal_ch0]
connect_bd_net [get_bd_ports dac_dat_b] [get_bd_pins ADC_set_0/adc_signal_ch1]

connect_bd_net [get_bd_pins ADC_set_0/clk_ps_200] [get_bd_pins processing_system7_0/FCLK_CLK0]
connect_bd_net [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] [get_bd_pins processing_system7_0/FCLK_CLK0]
connect_bd_net [get_bd_pins ADC_set_0/reset_ps_0] [get_bd_pins processing_system7_0/FCLK_RESET0_N]
connect_bd_net [get_bd_pins ADC_set_0/reset_ps_1] [get_bd_pins processing_system7_0/FCLK_RESET1_N]

#RUN AUTOMATION
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]

#Save
save_bd_design

#WRAPPER
make_wrapper -files [get_files $origin_dir/project/$_xil_proj_name_.srcs/sources_1/bd/$bdname/$bdname.bd] -top
add_files -norecurse $origin_dir/project/$_xil_proj_name_.gen/sources_1/bd/$bdname/hdl/design_1_wrapper.v
set_property top design_1_wrapper [current_fileset]

#





