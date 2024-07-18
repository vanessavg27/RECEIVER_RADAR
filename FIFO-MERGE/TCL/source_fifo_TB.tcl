#////////////////////////////////////////////////////////////////////////////////
#  project：FIFOs                                                              //
#                                                                              //
#  Author: Vanessa Vasquez                                                     //
#                                                                              //
#                                                                              //
#////////////////////////////////////////////////////////////////////////////////
# TESTBENCH de FIFOs.
# Nombre del proyecto FIFO
set projname "FIFO-MERGE"
#Ruta de carpeta TCL
#set tclpath [pwd] 
cd ..
#Ruta donde se creará el nuevo proyecto.
set projpath [pwd]
#set projpath "D:/Desktop/VANESSA DESK/WORK/IGP/THESIS-WORK/FPGA/Prueba_tcl"
cd ..

set Topname "FIFOs"
#///////////////////////////////////////////////////////////////////////////////

create_project -force $projname $projpath/$projname -part xc7z020clg400-1
# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

file mkdir $projpath/$projname/$projname.srcs/sources_1/ip
file mkdir $projpath/$projname/$projname.srcs/sources_1/new
file mkdir $projpath/$projname/$projname.srcs/sources_1/bd
# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

file mkdir $projpath/$projname/$projname.srcs/sim_1/new

#************************************************************************************************************
add_files -fileset sources_1  -copy_to $projpath/$projname/$projname.srcs/sources_1/new -force -quiet [glob -nocomplain $tclpath/src/design/*.v]
add_files -fileset sim_1  -copy_to $projpath/$projname/$projname.srcs/sim_1/new -force -quiet [glob -nocomplain $tclpath/src/testbench/*.v]

set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse [glob $tclpath/*.wcfg]

update_compile_order -fileset sources_1
update_compile_order -fileset sources_1
set_property top_file "/$projpath/$projname/$projname.srcs/sources_1/new/$Topname.v" [current_fileset]

launch_simulation