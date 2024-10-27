#include "i2c.h"
#include "../SLCR/SLCR_hw.h"

/* -------------------- DECLARE PRIVATE FUNCTIONS	-------------------- */
u16 i2c_ReadReg(u32 register_addr);

void i2c_WriteReg(u32 register_addr,u32 register_value);

int get_optimal_dividers(u32 base_freq, u32 freq_scl, u32* div_a, u32* div_b);

int  set_I2C_clock(I2C* I2C_Ptr);

/* --------------------------------------------------------------------- */

// -------------------- DEFINE PRIVATE FUNCTIONS  --------------------

u16 i2c_ReadReg(u32 register_addr){

	return Xil_In32(register_addr);
}

void i2c_WriteReg(u32 register_addr,u32 register_value){

	Xil_Out32(register_addr, register_value);
}

int set_I2C_clock(I2C* I2C_Ptr){

	int Status;
	u32 base_addr;
	//u32 base_freq;
	u32 Freq_scl;
	u32 cr_reg;

    base_addr = (u32) I2C_Ptr->Base_conf.base_address;
	//base_freq = (u32) I2C_Ptr->Base_conf.base_CPU_freq;

	if (I2C_Ptr->speed == I2C_100Khz){
		Freq_scl=100000;
		// Get A and B dividers
		//Status = get_optimal_dividers(base_freq, Freq_scl,&Div_A, &Div_B);
		I2C_Ptr->divs.div_A = 2;
		I2C_Ptr->divs.div_B = 16;
		Status =  XST_SUCCESS;
		}
	else if (I2C_Ptr->speed == I2C_400Khz){
		Freq_scl = 400000;
		//Status = get_optimal_dividers(base_freq, Freq_scl,&Div_A, &Div_B);
		I2C_Ptr->divs.div_A = 0;
		I2C_Ptr->divs.div_B = 12;
		Status =  XST_SUCCESS;
	}
	else{	Status =  XST_FAILURE;	}

	cr_reg =  i2c_ReadReg((u32) base_addr+I2C_CR_OFFS);
    cr_reg   &= 	~((u32) CR_DIV_A_MASK | (u32)CR_DIV_B_MASK);
	cr_reg   |= 	(((u32) I2C_Ptr->divs.div_A << (u32) CR_DIV_A_SHIFT) |
					((u32) I2C_Ptr->divs.div_B << (u32) CR_DIV_B_SHIFT));

	i2c_WriteReg((u32) base_addr+I2C_CR_OFFS, (u32) cr_reg);

	Status +=  XST_SUCCESS;
	return Status;
}

/* --------------------------------------------------------------------- */
/* --------------------------------------------------------------------- */

/* -------------------- DEFINE PUBLIC FUNCTIONS -------------------- */

void reset_I2C_controller(u32 I2c_dev){

	u32 rst_addr_reg;
	rst_addr_reg = i2c_ReadReg((u32) SLCR_BASEADDR + I2C_RST_CTRL);

	if (I2c_dev == I2C_DEV_0){
		rst_addr_reg |= (u32) I2C0_CPU1X_RST;
	}
	else if(I2c_dev == I2C_DEV_1){
		rst_addr_reg |= (u32) I2C1_CPU1X_RST;
	}
	else{
		xil_printf("Init Base Addres I2C struct.");
	}

	i2c_WriteReg((u32) SLCR_BASEADDR + I2C_RST_CTRL, rst_addr_reg);
}

void reset_i2c(I2C* I2C_Ptr){

	u32 base_addr;

	base_addr = (u32) I2C_Ptr->Base_conf.base_address;

	// Disable all interrupts
	i2c_WriteReg((u32) base_addr+I2C_IDR_DS_OFFS, (u32) IDR_ALL_INTERRUPT_MASK );

	// Clear FIFO and transfer
    i2c_WriteReg((u32) base_addr+I2C_CR_OFFS, (u32) CR_CLR_FIFO_MASK);
}

void disable_interrupts(I2C* I2C_Ptr){

	u32 base_addr;
	base_addr = (u32) I2C_Ptr->Base_conf.base_address;
	// Disable all interrupts
	i2c_WriteReg((u32) base_addr+I2C_IDR_DS_OFFS, (u32) IDR_ALL_INTERRUPT_MASK );
}

void disable_interrupts_sts(I2C* I2C_Ptr){

	u32 base_addr;
	base_addr = (u32) I2C_Ptr->Base_conf.base_address;
	// Disable all interrupts
	i2c_WriteReg((u32) base_addr+I2C_ISR_OFFS, (u32) IDR_ALL_INTERRUPT_MASK);
}

int Init_I2C(I2C* I2C_Ptr, I2C_mode mode, I2C_direction direction, I2C_speed speed){

	int Status;

	I2C_Ptr->Base_conf.base_address    = I2C0_baseaddr;
	I2C_Ptr->Base_conf.base_CPU_freq   = CPU_1X_I2C_clock;
	I2C_Ptr->fifo_depth                = I2C_FIFO_DEPTH_DEFAULT;

	I2C_Ptr->mode                   = mode;
    I2C_Ptr->dir                    = direction;
	I2C_Ptr->speed                  = speed;

	reset_i2c(I2C_Ptr);
	enable_I2C_clock(); // Probar


	Status = set_I2C_clock(I2C_Ptr);
	xil_printf("Div_A: %d \n\r",I2C_Ptr->divs.div_A);
	xil_printf("Div_B: %d \n\r",I2C_Ptr->divs.div_B);
	return Status;
}

void enable_I2C_clock(){

	u32 ctr_addr_reg;
	ctr_addr_reg = i2c_ReadReg((u32) SLCR_BASEADDR + APER_CLK_CTRL);
	ctr_addr_reg |= I2C0_CPU_1XCLKACT;

	i2c_WriteReg((u32) SLCR_BASEADDR  + APER_CLK_CTRL,ctr_addr_reg);
}

int BusIsBusy(I2C* I2C_Ptr){

	u32 StatusReg;
	s32 Status;
	u32 base_addr;

	base_addr = (u32) I2C_Ptr->Base_conf.base_address;

	StatusReg = i2c_ReadReg(base_addr + I2C_SR_OFFS);

	if ((StatusReg & SR_BA_MASK) != 0x0U) {	Status = XST_SUCCESS;}
	else {	Status = XST_FAILURE;}

	return Status;
}

int get_optimal_dividers(u32 base_freq, u32 freq_scl, u32* div_a, u32* div_b){

	int Status;
	int Temp;
	int Temp_Lim;
	u32 Div_a;
	u32 Div_b;
	u32 LastError;
	u32 BestError;
	u32 CurrentError;
	u32 CalcDivA;
	u32 CalcDivB;
    u32 ActualFscl;

	Temp = base_freq / ((u32)  22 * freq_scl);

	if (Temp <= 0){
		return (u32) XST_FAILURE;
	}
	else{
		Status = XST_SUCCESS;
	}

	if(freq_scl > (u32)384600U) {
		freq_scl = (u32)384600U;
	}
	else if((freq_scl <= (u32)100000U) && (freq_scl > (u32)90000U)) {
		freq_scl = (u32)90000U;
	}

	Temp_Lim = ((base_freq % ((u32)22 * freq_scl)) != (u32)0x0U) ? (Temp + (u32)1U) : Temp;
    BestError = freq_scl;

	for(int i=Temp; i<=Temp_Lim; i++){

		LastError =  freq_scl;
		CalcDivA = 0;
	    CalcDivB = 0;

		for(Div_b=0; Div_b<64;Div_b++){

			Div_a = Temp / (Div_b + 1U);

			if (Div_a != 0U){ Div_a = Div_a - (u32)1U;}
			if (Div_a > 3U){ continue;}

			ActualFscl = (base_freq) /(22U * (Div_a + 1U) * (Div_b + 1U));

			if (ActualFscl > freq_scl){  CurrentError = (ActualFscl - freq_scl);}
			else{	CurrentError = (freq_scl - ActualFscl);}

			if (LastError > CurrentError) {
				CalcDivA = Div_a;
				CalcDivB = Div_b;
				LastError = CurrentError;
			}
		}

		if(LastError < BestError){
			BestError = LastError;
			*div_a = CalcDivA;
			*div_b = CalcDivB;
		}

		Status +=  XST_SUCCESS;
	}

	Status +=  XST_SUCCESS;

	return Status;
}


int enable_i2c_mode(I2C* I2C_Ptr){

	u32 Command;
	u32 base_addr;
	u32 cr_reg;
	u32 Status;

	base_addr = (u32) I2C_Ptr->Base_conf.base_address;
	cr_reg  = i2c_ReadReg((u32) I2C_Ptr->Base_conf.base_address+I2C_CR_OFFS);
	Command = (u32) CR_NEA_MASK | CR_ACKEN_MASK | CR_MAST_SLV_MOD_MASK;

	if(I2C_Ptr->mode == I2C_master){

		if(I2C_Ptr->dir == I2C_receive){
			i2c_detect_transfer_size(I2C_Ptr);
		}

		cr_reg  |=  Command;
		i2c_WriteReg((u32) base_addr+I2C_CR_OFFS, (u32) cr_reg);

		// Update Status.
		I2C_Ptr->status= STATE_IDLE;


		Status =  XST_SUCCESS;
	    sleep(5);
	}
	else if(I2C_Ptr->mode == I2C_slave){
		cr_reg &=  ~Command;
		i2c_WriteReg((u32) base_addr+I2C_CR_OFFS, (u32) cr_reg);

		// Update Status.
		I2C_Ptr->status= STATE_IDLE;

		Status =  XST_SUCCESS;
		sleep(2);
	}
	else{Status =  XST_FAILURE;}

	return Status;
}


int set_master_tx(I2C* I2C_Ptr,Data_conf* data_conf, u32 addr_slv){

	int Status;
	u32 base_addr;
	u32 ctr_addr_reg;
	u32 isr_addr_reg;
	u32 avail_bytes;
	u32 bytes_to_send;

	// Check I2C Master Transmit
	if(I2C_Ptr->dir == I2C_transmit){
			Status =  XST_SUCCESS;}
	else{
		Status =  XST_FAILURE;
		return 0;}

	base_addr = (u32) I2C_Ptr->Base_conf.base_address;
	// Enable I2C Master
	ctr_addr_reg 	= i2c_ReadReg((u32) base_addr + I2C_CR_OFFS);
	ctr_addr_reg 	&=  ~CR_RD_WR_MASTER_MASK;
	ctr_addr_reg 	|=   CR_CLR_FIFO_MASK;

	// Check FIFO.
    if( data_conf->send_count > I2C_Ptr->fifo_depth){
		ctr_addr_reg |= CR_HOLD_MASK;
	}
	i2c_WriteReg((u32) base_addr+I2C_CR_OFFS, (u32) ctr_addr_reg);

	// Clear interrupts and Status Registers.
	isr_addr_reg    = i2c_ReadReg((u32) base_addr + I2C_ISR_OFFS);
	i2c_WriteReg((u32) base_addr + I2C_ISR_OFFS, isr_addr_reg);
    i2c_WriteReg((u32) base_addr + I2C_IDR_DS_OFFS, IDR_ALL_INTERRUPT_MASK);

	// Calculate available space  - Transmit FIFO
	avail_bytes = (u32) I2C_Ptr->fifo_depth - i2c_ReadReg((u32) base_addr + I2C_TSIZE_OFFS);

	if ((u32) (data_conf->send_count) > avail_bytes){
		bytes_to_send = avail_bytes;
	}
	else{
		bytes_to_send = data_conf->send_count;
	}

	// Fill FIFO.
	while (bytes_to_send--) {
		i2c_WriteReg((u32) base_addr+I2C_DATA_OFFS, (*(data_conf->buff_send)++));
		data_conf->send_count--;
	}
	// Check Status.
	disable_interrupts_sts(I2C_Ptr);
	// Set Slave Address
	I2C_Ptr->transfer_addr = addr_slv;
	i2c_WriteReg((u32) base_addr + I2C_ADDR_OFFS, (u32) I2C_Ptr->transfer_addr);
// ----------------------------------------------------------------------------------------
	// Ordeno la data

	//if( && bytes_to_send == 0)
	// Clear the Flag FIFO EMPTY wheter the Fifo is empty

	return Status;
}

int set_master_rx(I2C* I2C_Ptr,Data_conf* data_conf, u32 addr_slv){

	int Status;
	u32 base_addr;
	u32 ctr_addr_reg;
	u32 isr_addr_reg;
	u32 fifo_depth;
	u32 avail_bytes;
	u32 bytes_to_send;

	// Check I2C Master Receive
	if(I2C_Ptr->dir == I2C_receive){
		Status =  XST_SUCCESS;}
	else{
		Status =  XST_FAILURE;
		return 0;
	}

	base_addr = (u32) I2C_Ptr->Base_conf.base_address;
	// Enable I2C Master - READ
	ctr_addr_reg 	= i2c_ReadReg((u32) base_addr + I2C_CR_OFFS);
	ctr_addr_reg   |= CR_RD_WR_MASTER_MASK;
	ctr_addr_reg   |= CR_CLR_FIFO_MASK;

	if( (data_conf->recv_count) > (I2C_Ptr->fifo_depth)){
			ctr_addr_reg |= CR_HOLD_MASK;
	}

	i2c_WriteReg((u32) base_addr+I2C_CR_OFFS, (u32) ctr_addr_reg);

	// Clear interrupts and Status Registers.
	isr_addr_reg    = i2c_ReadReg((u32) base_addr + I2C_ISR_OFFS);
	i2c_WriteReg((u32) base_addr + I2C_ISR_OFFS, isr_addr_reg);



}

void i2c_detect_transfer_size(I2C* I2C_Ptr){

	u32 val;
	/* Write MASTER AND READ in Control register to write in the Transfer size register */
	i2c_WriteReg((u32) I2C_Ptr->Base_conf.base_address+I2C_CR_OFFS,CR_MAST_SLV_MOD_MASK|CR_RD_WR_MASTER_MASK);

	/* Writing 0xff and then reading the value back will report the
	 * maximum supported transfer size  */
	i2c_WriteReg((u32) I2C_Ptr->Base_conf.base_address+I2C_TSIZE_OFFS,I2C_MAX_TRANSFER_SIZE);
	val = i2c_ReadReg((u32) I2C_Ptr->Base_conf.base_address+I2C_TSIZE_OFFS);

	I2C_Ptr->transfer_size  =  I2C_TRANSFER_SIZE(val);

	i2c_WriteReg((u32) I2C_Ptr->Base_conf.base_address+I2C_TSIZE_OFFS, 0);
	i2c_WriteReg((u32) I2C_Ptr->Base_conf.base_address+I2C_CR_OFFS, 0);
}
//int TransmitFifoFill(I2C* I2C_Ptr){
//
//}

/*
int set_master_rx(I2C* I2C_Ptr,Data_conf* data_id){

	int Status;
	u32 base_addr;
	u32 ctr_addr_reg;
	u32 fifo_depth;
	int avail_bytes;

	// Check I2C Master Transmit
	if(I2C_Ptr->dir == I2C_receive){
		Status =  XST_SUCCESS;
	}
	else{
		Status =  XST_FAILURE;
		return 0;
	}

	base_addr = (u32) I2C_Ptr->Base_conf.base_address;
	// Enable I2C Master
	ctr_addr_reg 	= i2c_ReadReg(base_addr + I2C_CR_OFFS);
	ctr_addr_reg 	&=  ~CR_RD_WR_MASTER_MASK;
	ctr_addr_reg 	|=   CR_CLR_FIFO_MASK;

	// Check Data
    I2C_Ptr->data_id->send_count  = length_byte;
    avail_bytes   =

}
*/


/*
int set_master_rx(I2C* I2C_Ptr){

	u32 ctr_addr_reg;
	ctr_addr_reg = i2c_ReadReg((u32) I2C_Ptr->Base_conf.base_address + I2C_CR_OFFS);
	ctr_addr_reg |=  ;


}
*/
