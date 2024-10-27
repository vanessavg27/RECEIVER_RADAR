
#ifdef __cplusplus
extern "C" {
#endif

/* ---- I2C base address ----  */
///  I2C base addresses
#define I2C0_baseaddr        0xE0004000
#define I2C0_baseaddr_high   0xE0004FFF

#define I2C1_baseaddr        0xE0005000
#define I2C1_baseaddr_high   0xE0005FFF

#define CPU_1X_I2C_clock      111111115
///  I2C registers offsets
#define I2C_CR_OFFS  		0x00000000U
#define I2C_SR_OFFS  		0x00000004U
#define I2C_ADDR_OFFS  		0x00000008U
#define I2C_DATA_OFFS  		0x0000000CU
#define I2C_ISR_OFFS  		0x00000010U
#define I2C_TSIZE_OFFS      0x00000014U
#define I2C_SLV_PAUSE_OFFS  0x00000018U
#define I2C_IMR_OFFS  		0x0000001CU
#define I2C_IER_en_OFFS   	0x00000024U
#define I2C_IDR_DS_OFFS   	0x00000028U

///  I2C MASK CONTROL REGISTER
#define CR_RD_WR_MASTER_MASK        0x1
#define CR_MAST_SLV_MOD_MASK        0x2
#define CR_NEA_MASK                 0x4
#define CR_ACKEN_MASK               0x8
#define CR_HOLD_MASK               0x10
#define CR_SLVMON_MASK             0x20
#define CR_CLR_FIFO_MASK           0x40
#define CR_DIV_B_MASK            0x3F00
#define CR_DIV_B_SHIFT                8
#define CR_DIV_A_MASK            0xC000
#define CR_DIV_A_SHIFT               14


///  I2C MASK STATUS REGISTER
#define SR_BA_MASK		0x00000100U
#define SR_RXOVF_MASK	0x00000080U
#define SR_TXDV_MASK	0x00000040U
#define SR_RXDV_MASK	0x00000020U
#define SR_RXRW_MASK	0x00000008U


/// I2C MASK INTERRUPT REGISTER (IDR_DS_OFFS)
#define IDR_COMP_MASK               0x1
#define IDR_DATA_MASK               0x2
#define IDR_NACK_MASK               0x4
#define IDR_TOut_MASK               0x8
#define IDR_SLV_RDY_MASK           0x10
#define IDR_RX_OVR_MASK            0x20
#define IDR_TX_OVR_MASK            0x40
#define IDR_RX_UNF_MASK            0x80
#define IDR_ARB_LOST_MASK         0x200

#define IDR_ALL_INTERRUPT_MASK    (IDR_ARB_LOST_MASK | IDR_RX_UNF_MASK | \
                                   IDR_TX_OVR_MASK   | IDR_RX_OVR_MASK | \
                                  IDR_SLV_RDY_MASK   | IDR_TOut_MASK   | \
                                    IDR_NACK_MASK    |  IDR_DATA_MASK  | \
                                    IDR_COMP_MASK   )

#define I2C_FIFO_DEPTH_DEFAULT	16
#define I2C_MAX_TRANSFER_SIZE	255
/* Transfer size in multiples of data interrupt depth */
#define I2C_TRANSFER_SIZE(max)	((max) - 3)


// ---------------------------------------
///  I2C register values
#define I2C_isr_dis   		0x000002FFU
#define I2C_rst_conf 		0x00000040U
#define I2C_tout_rst  		0x000000FFU
#define I2C_bus_pin  		         8U
#define I2C_ctrl_hold  		         4U
#define I2C_hold_bit  		0x00000010U
#define I2C_nea_bit  		0x00000004U
#define I2C_set_master  	0x0000005EU
#define I2C_rw_master  		0x00000001U
#define I2C_slv_m_en  		0x00000066U
#define I2C_slv_m_dis  		0x00000020U
#define I2C_slv_m_idr  		0x00000010U
#define I2C_slv_m_init  	0x0000000FU
#define I2C_mst_sd_idr  	0x00000205U
#define I2C_slv_sd_idr  	0x0000004FU
#define I2C_slv_rcv_idr   	0x000000AFU
#define I2C_sr_RXDV  		0x00000020U
#define I2C_sr_TXDV  		0x00000040U
#define I2C_sr_RXOVF  		0x00000080U
#define I2C_slv_clr  		0x0000002CU
#define I2C_div_A_shift   			14U
#define I2C_div_B_shift   			 8U
#define I2C_CLK_divisor   			22U
#define I2C_div_B_limit   			64U
#define I2C_div_A_limit   			 3U
#define I2C_FIFO_size   			16U
#define I2C_CLK_max_400   		384600U
#define I2C_CLK_max_100   		100000U
#define I2C_CLK_min_100   		 90000U
#define I2C_max_tr_size    		  0xFCU
#define I2C_timeout_val   		  1000U  /// Timeout in us

///  32bit register masks
#define bits16_mask  		0xFFFF0000U
#define bits10_mask  		0xFFFFFC00U
#define bits8_mask  		0xFFFFFF00U
#define inv_bits8_mask  	0x000000FFU
#define inv_bits10_mask  	0x000003FFU


#ifdef __cplusplus
}
#endif
