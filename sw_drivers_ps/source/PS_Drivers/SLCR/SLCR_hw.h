#ifndef SLCR_HW_H		/* prevent circular inclusions */
#define SLCR_HW_H		/**< by using protection macros */


/* ---- System Level Control Registers (slcr)  ----  */
//  SLCR  base address
#define     SLCR_BASEADDR		    0xF8000000

// OFFSET
#define APER_CLK_CTRL           0x0000012C
#define I2C_RST_CTRL		    0x00000224
#define GPIO_RST_CTRL           0x0000022C
#define MIO_PIN50		        0x000007C8
#define MIO_PIN51		        0x000007CC








//MASK

#define I2C0_CPU_1XCLKACT          0x40000
#define I2C0_CPU1X_RST		           0x1
#define I2C1_CPU1X_RST		           0x2
#define GPIO_CPU1X_RST                 0x1



#endif
