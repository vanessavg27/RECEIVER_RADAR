

#ifndef I2C_H_
#define I2C_H_

#ifdef __cplusplus
extern "C++" {
#endif


//#include "Entypes.h"
//#include "Parameters.h"
#include "i2c_hw.h"
#include <stdbool.h>
#include "xstatus.h"
#include "sleep.h"


#define I2C_DEV_0   0
#define I2C_DEV_1   1


///  I2C communication speed.
typedef enum
{
I2C_100Khz = 0,    ///  I2C to 100KHz.
I2C_400Khz = 1     ///  I2C to 400KHz.
} I2C_speed;

///  Mode to set I2C controller
typedef enum
{
I2C_slave,
I2C_master
} I2C_mode;

    ///  Direction of I2C transmission (used in master mode only)
typedef enum
{
I2C_transmit,
I2C_receive,
} I2C_direction;

    ///  Address type used for transmission (used in master mode only)
typedef enum
{
I2C_extended,
I2C_normal,
} I2C_address;

    ///  Slave monitoring for I2C controller (used in master mode only)
typedef enum
{
I2C_mon_active,
I2C_mon_inactive,
} I2C_slave_mon;

typedef enum {
	STATE_IDLE,
	STATE_SEND,
	STATE_RECV,
}I2c_status;

typedef struct
{
u32 base_address;
u32 base_CPU_freq;
}Config_Base;

typedef struct{
int div_A;
int div_B;
}dividers;

typedef struct{
int Command;
u32 send_count;
u32 recv_count;
u8* buff_send;
u8* buff_recv;
}Data_conf;

typedef struct {
    Config_Base    Base_conf;
    I2C_mode       mode;
    I2C_direction  dir;
    I2C_speed      speed;
    dividers       divs;
    u32            transfer_addr;
    I2c_status     status;
    int            fifo_depth;
    u32            transfer_size;
    int            flag_isr;
}I2C;

// NEW FUNCTIONS

void reset_I2C_controller(u32 I2c_dev);

void  reset_i2c(I2C* I2C_Ptr);

int Init_I2C(I2C* I2C_Ptr, I2C_mode mode, I2C_direction direction,  I2C_speed speed);

void enable_I2C_clock();

int  enable_i2c_mode(I2C* I2C_Ptr);

int set_master_tx(I2C* I2C_Ptr, Data_conf* data_conf, u32 addr_slv);

int BusIsBusy(I2C* I2C_Ptr);

int set_master_rx(I2C* I2C_Ptr, Data_conf* data_conf, u32 addr_slv);





void disable(I2C* I2C_Ptr);

void init_master(I2C_mode md, u32 base_addr,I2C_slave_mon m_slave, I2C_address addr_mode, I2C_direction dir, I2C_speed speed);

void init_slave(I2C_mode md, u32 base_addr, I2C_speed speed);

    ///  Send and receive data bytes
void start_write(I2C* I2C_Ptr, u32 addr, u32 block_size, u8* data);          /// Write bytes from 'data'

int start_read(I2C* I2C_Ptr, u32 addr, u32 block_size, u8* data);           				 /// Read bytes into 'data'

u32 get_speed(I2C* I2C_Ptr);

    u8 set_speed(I2C* I2C_Ptr, u32 frec_CLK);

    bool is_busy(I2C* I2C_Ptr);                         /// I2C bus is busy
    void slave_monitor();                   /// Only avaliable for master controller

    void master_send(I2C* I2C_Ptr, u8* send_data, u32 byte_count, u32 slave_addr);

    void master_receive(I2C* I2C_Ptr, u8* recv_data, u32 byte_count, u32 slave_addr);

    void master_read( u32 base_addr, u8* recv_data, u32 byte_count);




    // Declare Functions
    void reset(I2C* I2C_Ptr);

    void set_transfer_addr(I2C* I2C_Ptr, u32 addr);

    void abort_end(I2C* I2C_Ptr);

    void idr_disable(I2C* I2C_Ptr);

    void clear_isr_status(I2C* I2C_Ptr);

    void slave_send(I2C* I2C_Ptr, u8* send_data, u32 byte_count, u32 master_addr);

    void slave_receive(I2C* I2C_Ptr, u8* recv_data, u32 byte_count, u32 master_addr);

    u8 setup_master(I2C* I2C_Ptr, I2C_direction direction);

    void tr_FIFO_fill(I2C* I2C_Ptr, u8* data, u32 byte_count);

#ifdef __cplusplus
}
#endif


#endif     ///  I2C_H_
