/* INCLUDE FILES */
#include "gpio.h"
#include "xil_printf.h"


/********************* DECLARE PRIVATE FUNCTIONS *********************/

// DECLARE FUNCTIONS

u32  gpio_ReadReg(u32 register_addr);

void gpio_WriteReg(u32 register_addr, u32 register_value);

int get_addr_reg_offset(int bank, int pin);

// DEFINE FUNCTIONS

u32  gpio_ReadReg(u32 register_addr){

    return Xil_In32(register_addr);
}

void gpio_WriteReg(u32 register_addr, u32 register_value){

    Xil_Out32(register_addr, register_value);
}
/*********************************************************************/

// DEFINE PUBLIC FUNCTIONS

void reset_GPIO_controller(){

    u32 rst_addr_reg;
	rst_addr_reg = gpio_ReadReg((u32) SLCR_BASEADDR + GPIO_RST_CTRL);
    rst_addr_reg |= GPIO_CPU1X_RST;

	gpio_WriteReg((u32) SLCR_BASEADDR + GPIO_RST_CTRL, rst_addr_reg);
}

// mio_emio_enable: 0  -- MIO Activate
// mio_emio_enable: 1  -- EMIO Activate

int Init_GPIO(GPIO *Instance_Pointer, bool mio_emio_enable, PLATFORM type_platform){

    int Status;
    Instance_Pointer->base_addr = GPIO_BASEADDR;

    if (mio_emio_enable == 0){
        Instance_Pointer->mio      = 1;
        Status = XST_SUCCESS;
    }
    else if (mio_emio_enable == 1){
        Instance_Pointer->emio      = 1;
        Status = XST_SUCCESS;
    }
    else{
        xil_printf("Verificar Correcta configuracion.");
        Status = XST_FAILURE;
    }

    if(type_platform == ZYNQ7000) {
    Instance_Pointer->platform_type =  ZYNQ7000;
    }

    switch(Instance_Pointer->platform_type){

        case ZYNQ7000:
            Instance_Pointer->GPIO_IO_config.PinNum  =  118;
            Instance_Pointer->GPIO_IO_config.BankNum =  4;
            Instance_Pointer->GPIO_IO_config.MIOpins =  54;
            Instance_Pointer->GPIO_IO_config.EMIOpins=  64;
            break;

        case ZYNQ_ULTRA_MP:
            Instance_Pointer->GPIO_IO_config.PinNum  =  174;
            Instance_Pointer->GPIO_IO_config.BankNum =    6;
            Instance_Pointer->GPIO_IO_config.MIOpins =   54;
            Instance_Pointer->GPIO_IO_config.EMIOpins=   64;
            break;
    }

    Status = XST_SUCCESS;


    disable_interrupts_banks(Instance_Pointer);

    return Status;
}

void disable_interrupts_banks(GPIO *Instance_Pointer){

    for(int i= 0; i< Instance_Pointer->GPIO_IO_config.BankNum; i++){

        gpio_WriteReg((u32) Instance_Pointer->base_addr + GPIO_INTDIS_OFFSET +
                      i*GPIO_MASK_BANKs_OFFSET, 0xFFFFFFFF);
    }
}

void get_bank_pin(GPIO *Instance_Pointer, PLATFORM type_platform){

    int banks = Instance_Pointer->GPIO_IO_config.BankNum;
    int pins=0;
    if (type_platform == ZYNQ_ULTRA_MP){

        for (int i=0; i<banks; i++){
            if (i == 0){
            pins = pins+25-1;
            }
            if ((i == 1) || (i == 2) ){
            pins = pins+26;
            }
            else{
            pins = pins+(26);
            }
            *(Instance_Pointer->banks_pins+i*0x4)=  pins;
        }
    }
    else if (type_platform == ZYNQ7000){

        for (int i=0; i<banks; i++){
            if(i == 0){
                pins = (pins)+(32-1);
            }
            else if (i == 1){
            pins = (pins)+(22);
            }
            else{
            pins = (pins)+(32);
            }
            *(Instance_Pointer->banks_pins+i*0x4)=  pins;
        }
    }
}

int set_pininBank(DIGITAL_IO *IO_pointer){

    int pin;
    int Status;

    if(((IO_pointer->gpio_port)->platform_type == ZYNQ7000) & ((IO_pointer->gpio_port)->emio)){
        pin = IO_pointer->gpio_pin_emio;

        if ((pin >= 32) & (pin <64)){
            IO_pointer->pininBank = pin-32;
            IO_pointer->Bank      = 3;
            Status = XST_SUCCESS;
        }
        else if (pin < 32){
            IO_pointer->pininBank = pin;
            IO_pointer->Bank      = 2;
            Status = XST_SUCCESS;
        }
        else{
            xil_printf("Error. Select correct Pin.");
            Status = XST_FAILURE;
        }
    }
    else if(((IO_pointer->gpio_port)->platform_type == ZYNQ7000) & ((IO_pointer->gpio_port)->mio)){
        pin = IO_pointer->gpio_pin_mio;

        if ((pin >=32) & (pin <64)){
            IO_pointer->pininBank = pin-32;
            IO_pointer->Bank      = 1;
            Status = XST_SUCCESS;
        }
        else if (pin < 32){
            IO_pointer->pininBank = pin;
            IO_pointer->Bank      = 0;
            Status = XST_SUCCESS;
        }
        else{
            xil_printf("Error. Select correct Pin.");
            Status = XST_FAILURE;
        }
    };

    return Status;
}

void set_direction_pin(DIGITAL_IO *IO_pointer) {

    u32 DirMode_reg;
    u32 OutEn_reg;
    u32 base_addr;
    u32 offset;
    base_addr       = (IO_pointer->gpio_port)->base_addr;
    offset          = (u32) (IO_pointer->Bank)*GPIO_MASK_BANKs_OFFSET;

    DirMode_reg     =  gpio_ReadReg((u32) base_addr+offset+GPIO_DIRM_OFFSET);

    if(IO_pointer->mode == write_mode){
        // DIRECTION WRITE
        DirMode_reg     |= ((u32)1 << (u32) IO_pointer->pininBank);
        gpio_WriteReg((u32) base_addr+offset+GPIO_DIRM_OFFSET, DirMode_reg);

        // ENABLE
        OutEn_reg       =  gpio_ReadReg((u32) base_addr+offset+GPIO_OUTEN_OFFSET);
        OutEn_reg      |= ((u32)1 << (u32) IO_pointer->pininBank);
        gpio_WriteReg((u32) base_addr+offset+GPIO_OUTEN_OFFSET, OutEn_reg);

    }
    else if(IO_pointer->mode == read_mode){
        // DIRECTION READ
        DirMode_reg     &= ~((u32) 1 << (u32) (IO_pointer->pininBank));
        gpio_WriteReg((u32) base_addr+offset+GPIO_DIRM_OFFSET, DirMode_reg);
    }

}

void WR_pin(DIGITAL_IO *IO_pointer, int value){

    u32 base_addr;
    u32 offset;
    u32 pin;
    u32 Valor;
    u32 wr_reg_addr;

    base_addr       = (IO_pointer->gpio_port)->base_addr;
    pin             = IO_pointer->pininBank;
    value          &= (u32) 0x01;
    // WRITE
    if(IO_pointer->pininBank < 16){
    offset = (u32) (IO_pointer->Bank)*GPIO_DATA_bank_OFFSET + GPIO_DATA_LSW_OFFSET;
    }
    else {
    offset = (u32) (IO_pointer->Bank)*GPIO_DATA_bank_OFFSET + GPIO_DATA_MSW_OFFSET;
    }

    Valor = ~((u32)1 << (pin + 16U)) & ((value << pin) | 0xFFFF0000U);
    wr_reg_addr = gpio_ReadReg((u32) base_addr+offset);
    gpio_WriteReg((u32) base_addr+offset, Valor);
}

int RD_pin(DIGITAL_IO *IO_pointer){

    u32 base_addr;
    u32 offset;
    u32 pin;
    u32 value;

    base_addr       = (u32) (IO_pointer->gpio_port)->base_addr;
    offset          = (u32) (IO_pointer->Bank)*GPIO_DATA_RD_OFFSET;
    pin             = (u32) IO_pointer->pininBank;

    value = (gpio_ReadReg((u32) base_addr+offset+GPIO_DATA_RO_OFFSET) >> pin);
    value =  value & 0x1;
    return value;
}
