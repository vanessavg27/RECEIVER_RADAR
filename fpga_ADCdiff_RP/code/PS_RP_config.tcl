proc set_ps_config {bd_cell_name} {
 set_property -dict [list \
            CONFIG.PCW_PRESET_BANK1_VOLTAGE {LVCMOS 2.5V} \
            CONFIG.PCW_UART0_PERIPHERAL_ENABLE {1} \
            CONFIG.PCW_UART0_UART0_IO {MIO 14 .. 15} \
            CONFIG.PCW_UIPARAM_DDR_CL {11} \
            CONFIG.PCW_UIPARAM_DDR_CWL {8} \
            CONFIG.PCW_UIPARAM_DDR_DEVICE_CAPACITY {4096 MBits} \
            CONFIG.PCW_UIPARAM_DDR_MEMORY_TYPE {DDR 3 (Low Voltage)} \
            CONFIG.PCW_UIPARAM_DDR_PARTNO {Custom} \
            CONFIG.PCW_UIPARAM_DDR_SPEED_BIN {DDR3_1600K} \
            CONFIG.PCW_UIPARAM_DDR_T_FAW {40} \
            CONFIG.PCW_UIPARAM_DDR_T_RAS_MIN {35} \
            CONFIG.PCW_UIPARAM_DDR_T_RC {48.75} \
            CONFIG.PCW_UIPARAM_DDR_T_RCD {11} \
            CONFIG.PCW_UIPARAM_DDR_T_RP {11} \
            CONFIG.PCW_EN_RST1_PORT {1} \
            CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {200} \
    ] [get_bd_cells $bd_cell_name]
}

