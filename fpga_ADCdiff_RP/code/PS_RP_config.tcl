proc set_ps_config{bd_cell_name} {
 set_property -dict [list \
            CONFIG.PCW_PRESET_BANK1_VOLTAGE {LVCMOS 1.8V} \
 	        CONFIG.PCW_UIPARAM_DDR_FREQ_MHZ {525} \
    ] [get_bd_cells $bd_cell_name]
}

