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
add_files -fileset sources_1 $origin_dir/source/design/*.vhd
add_files -fileset sources_1 $origin_dir/source/design/*.sv
add_files -fileset sources_1 $origin_dir/source/design/*.v

create_bd_design $bdname
update_compile_order -fileset sources_1
open_bd_design $origin_dir/project/$_xil_proj_name_.srcs/sources_1/bd/$bdname/$bdname.bd
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0

source $origin_dir/PS_RP_config.tcl
set_ps_config processing_system7_0
