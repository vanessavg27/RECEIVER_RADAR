#ifndef GPIO_HW_H		/* prevent circular inclusions */
#define GPIO_HW_H		/**< by using protection macros */


// OFFSET BASEADDRESS
#define GPIO_DATA_LSW_OFFSET   0x00000000U
#define GPIO_DATA_MSW_OFFSET   0x00000004U
#define GPIO_DATA_OFFSET       0x00000040U
#define GPIO_DATA_RO_OFFSET    0x00000060U
#define GPIO_DIRM_OFFSET       0x00000204U
#define GPIO_OUTEN_OFFSET      0x00000208U
#define GPIO_INTMASK_OFFSET    0x0000020CU
#define GPIO_INTEN_OFFSET      0x00000210U
#define GPIO_INTDIS_OFFSET     0x00000214U
#define GPIO_INTSTS_OFFSET     0x00000218U
#define GPIO_INTTYPE_OFFSET    0x0000021CU
#define GPIO_INTPOL_OFFSET     0x00000220U
#define GPIO_INTANY_OFFSET     0x00000224U


//MASK
#define GPIO_DATA_bank_OFFSET   0x00000008U  /**< Data/Mask Registers offset */
#define GPIO_DATA_RD_OFFSET     0x00000004U
#define GPIO_MASK_BANKs_OFFSET        0x40U  /**< Registers offset */
















#endif
