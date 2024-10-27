#include "xparameters.h"
#include "xiicps.h"
#include "xil_printf.h"
#include "PS_Drivers/I2C_PS/i2c.h"


#define XIICPS_BASEADDRESS	XPAR_XIICPS_0_BASEADDR
#define XIICPS_DEVICE_ID	XPAR_XIICPS_0_DEVICE_ID
/*
 * The slave address to send to and receive from.
 */
#define IIC_SLAVE_ADDR		0x6C
#define IIC_SCLK_RATE		100000
#define n_bytes				10

I2C Object_i2c;




int main(){

u32 mode			  = I2C_master;
u32 speed		      = I2C_100Khz;
u32 dir			      = I2C_transmit;
u32 slave_addr        = IIC_SLAVE_ADDR;



int Status;

u8 data_buffer[n_bytes];

for(u8 i=0; i < n_bytes; i++){
	data_buffer[n_bytes] = i;
}

Data_conf data_sent;
data_sent.send_count = n_bytes;
//data_sent.recv_count = 2;
data_sent.buff_recv  = &data_buffer;


reset_I2C_controller(I2C_DEV_0);

Status =  Init_I2C(&Object_i2c, mode, dir, speed);

Status += enable_i2c_mode(&Object_i2c);

Status += set_master_tx(&Object_i2c, &data_sent, slave_addr);




}
