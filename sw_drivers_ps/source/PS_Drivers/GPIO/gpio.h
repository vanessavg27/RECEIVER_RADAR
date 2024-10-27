#ifndef GPIO_H		/* prevent circular inclusions */
#define GPIO_H		/**< by using protection macros */

/* ------------   INCLUDE FILES   ------------  */
#include <stdbool.h>
#include "xil_types.h"
#include "xstatus.h"
#include "../SLCR/SLCR_hw.h"
#include "gpio_hw.h"
#include "xil_io.h"


/* ---- GENERAL PURPOSE I/O (GPIO)   ----  */
//  GPIO  base address  ZYNQ7000
#define GPIO_BASEADDR            0xE000A000
#define GPIO_BASEADDR_HIGHADDR   0xE000AFFF


typedef enum{
    ZYNQ_ULTRA_MP = 1,
    ZYNQ7000      = 2
} PLATFORM;

typedef struct{
    int PinNum;
    int BankNum;
    int MIOpins;
    int EMIOpins;
} Config_IO;

typedef enum{
    write_mode,
    read_mode,
} mode_op;

typedef struct{
   u32 base_addr;
   PLATFORM platform_type;
   bool mio;
   bool emio;
   Config_IO  GPIO_IO_config;
   int* banks_pins;
} GPIO;

typedef struct{
GPIO*    gpio_port;
int      gpio_pin_emio;
int      gpio_pin_mio;
int      Bank;
int      pininBank;
mode_op  mode;
}DIGITAL_IO;


void reset_GPIO_controller();

int Init_GPIO(GPIO *Instance_Pointer, bool mio_emio_enable, PLATFORM type_platform);

void disable_interrupts_banks(GPIO *Instance_Pointer);

// 54 GPIO signals for MIO module

// 64 GPIO signals for EMIO module
void get_bank_pin(GPIO *Instance_Pointer, PLATFORM type_platform);

void set_direction_pin(DIGITAL_IO *IO_pointer);

int set_pininBank(DIGITAL_IO *IO_pointer);

void WR_pin(DIGITAL_IO *IO_pointer, int value);

int  RD_pin(DIGITAL_IO *IO_pointer);





#endif
