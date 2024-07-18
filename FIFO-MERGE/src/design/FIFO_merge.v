`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  IGP - Jicamarca Radio Observatory
// Engineer: Vanessa Vasquez
//////////////////////////////////////////////////////////////////////////////////
module FIFO_merge#(
    parameter integer n_bits = 4,
    parameter integer width  = 16,
    parameter integer afulloffset = 1,
    parameter integer aemptyoffset = 1,
    parameter integer async = 1
    )(
    // WRITE FPGA
    input   clock_wr,
    input   reset_wr,
    input   [n_bits-1:0]  Data_in,
    // READ PROCESADOR
    input   reset_rd,
    input   clock_rd,
    input   start,
    output  [n_bits-1:0] Data_output,
    output  done,
    output  [2:0] state_out
    );
    
    // SIGNAL for FIFO1
    wire [n_bits-1:0] fifo1Data;
    reg  fifo1WrEn;
    reg  fifo1RdEn;
    wire fifo1Full;
    wire almost_full_1;
    wire empty_1;
    wire almost_empty_1;
    wire [16-1:0] wr_counter_1;
    wire [16-1:0] rd_counter_1;
    wire overflow_1;
    wire underflow_1;
    wire valid_data_1;
    
    // SIGNAL for FIFO2
    wire [n_bits-1:0] fifo2Data;
    reg  fifo2WrEn;
    reg  fifo2RdEn;
    wire fifo2Full;
    wire almost_full_2;
    wire empty_2;
    wire almost_empty_2;
    wire [16-1:0] wr_counter_2;
    wire [16-1:0] rd_counter_2;
    wire overflow_2;
    wire underflow_2;
    wire valid_data_2;
    
    reg [2:0] state;
    reg done_reg;
    reg [n_bits-1:0] Data_join = {n_bits-1{1'b0}};
    
    localparam  IDLE  =         'd0,
                BEGIN =         'd1,
                WR_FF2_RD_FF1 = 'd2,
                WR_FF2        = 'd3,
                WR_FF1_RD_FF2 = 'd4,
                WR_FF1        = 'd5;
        //test FIFO_v, original is FIFO.        
        FIFO_v  #(n_bits,width,afulloffset,aemptyoffset,async) 
            FIFO_1    (   // WRITE SIDE
                            .wclk_i       (clock_wr),      .wrst_i       (reset_wr),
                            .wen_i        (fifo1WrEn),     .data_i       (Data_in),
                            .full_o       (fifo1Full),     .afull_o      (almost_full_1),
                            .overflow_o   (overflow_1),    .wcount_o     (wr_counter_1),
                            // READ SIDE,
                            .rclk_i       (clock_rd),      .rrst_i      (reset_rd),
                            .ren_i       (fifo1RdEn),      .empty_o     (empty_1),
                            .aempty_o    (almost_empty_1), .underflow_o (underflow_1),
                            .valid_o     (valid_data_1),               .rcount_o    (rd_counter_1),
                            .data_o      (fifo1Data)
                        );
        FIFO_v  #(n_bits,width,afulloffset,aemptyoffset,async)
            FIFO_2    (    // WRITE SIDE
                            .wclk_i       (clock_wr),     .wrst_i       (reset_wr),
                            .wen_i        (fifo2WrEn),    .data_i       (Data_in),
                            .full_o       (fifo2Full),    .afull_o      (almost_full_2),
                            .overflow_o   (overflow_2),             .wcount_o     (wr_counter_2),
                           // READ SIDE,
                            .rclk_i       (clock_rd),     .rrst_i      (reset_rd),
                            .ren_i       (fifo2RdEn),     .empty_o     (empty_2),
                            .aempty_o    (almost_empty_2),.underflow_o (underflow_2),
                            .valid_o     (valid_data_2),  .rcount_o    (rd_counter_2),
                            .data_o      (fifo2Data)
                        );

    always @(posedge clock_rd , posedge clock_wr)
    begin
        if (!reset_wr)
            begin
            state <= IDLE;
            fifo1WrEn = 1'b0;
            fifo2WrEn = 1'b0;
            end
        else if (!reset_rd)
            begin
            fifo1RdEn = 1'b0;
            fifo2RdEn = 1'b0;
            //Data_join = 0;
            end
        
            begin
                case(state)
                    IDLE: begin
                          fifo1WrEn = 1'b0;
                          fifo2WrEn = 1'b0;
                          fifo1RdEn = 1'b0;
                          fifo2RdEn = 1'b0;
                          if (start)
                            begin
                                state  = BEGIN;
                                fifo1WrEn = 1'b1;
                            end
                    end
                    BEGIN: begin
                        fifo1WrEn = 1'b1;
                        if ( !empty_1 & almost_full_1)
                            begin
                            state     = WR_FF2_RD_FF1;
                            end                            
                    end
                    WR_FF2_RD_FF1: begin
                         fifo1WrEn = 1'b0;                           
                         fifo1RdEn = 1'b1;
                         fifo2WrEn = 1'b1;
                         fifo2RdEn = 1'b0;
                         if (!almost_full_2 & empty_1)
                            begin
                            state = WR_FF2;
                            end
                         else if (almost_full_2 & empty_1) //NEW
                            begin
                            state = WR_FF1_RD_FF2;
                            end
                         else if (!almost_full_1 & !empty_1)
                            begin
                            state  = WR_FF2_RD_FF1;
                            end
                    end
                    WR_FF2: begin
                                               
                        if (almost_full_2 & !empty_2)
                            begin
                            state     = WR_FF1_RD_FF2;
                            end
                        else if (!almost_full_2 & !empty_2)
                            begin
                            if (!empty_1)
                                begin
                                fifo1WrEn = 1'b0;                           
                                fifo1RdEn = 1'b1;
                                fifo2WrEn = 1'b1;
                                fifo2RdEn = 1'b0;
                                state = WR_FF2_RD_FF1;
                                end
                            else begin
                                fifo1WrEn = 1'b0;
                                fifo1RdEn = 1'b0;
                                fifo2WrEn = 1'b1;
                                fifo2RdEn = 1'b0;
                                state = WR_FF2;
                                end
                            end


                    end
                    
                    WR_FF1_RD_FF2: begin
                        fifo1RdEn = 1'b0;
                        fifo1WrEn = 1'b1;
                        fifo2RdEn = 1'b1;
                        fifo2WrEn = 1'b0;
                        
                        if (!almost_full_1 & empty_2)
                            begin
                            state = WR_FF1;
                            end
                        else if (almost_full_1 & empty_2)
                            begin
                            state = WR_FF2_RD_FF1;
                            end
                        else if (!almost_full_1 & !empty_2)
                            begin
                            state = WR_FF1_RD_FF2;
                            end
                        end
                        
                    WR_FF1: begin
                        
                        if (almost_full_1 & !empty_1)
                            begin
                            state = WR_FF2_RD_FF1;
                            end
                        else if (!almost_full_1 & !empty_1)
                            begin
                            if (!empty_2) begin //  !empty_2
                                fifo1RdEn = 1'b0;
                                fifo1WrEn = 1'b1;
                                fifo2RdEn = 1'b1;
                                fifo2WrEn = 1'b0;
                                state = WR_FF1_RD_FF2;
                                end
                            else begin
                                fifo1WrEn = 1'b1;
                                fifo1RdEn = 1'b0;
                                fifo2WrEn = 1'b0;
                                fifo2RdEn = 1'b0;
                                
                                state = WR_FF1;
                                end
                            end
                            
                        
                        end        
                endcase    
          end
    end
    
     always@ (posedge clock_rd)
        begin
        if (!reset_rd)
            begin
            Data_join <= 'd0;
            end
        else
            begin    
            if (valid_data_1)
                begin
                Data_join <= fifo1Data;
//                done <= 1;
                done_reg <= 1;
                end
            else if (valid_data_2)
                begin
                Data_join <= fifo2Data;
//                done <= 1;
                done_reg <= 1;
                end
            else
                begin
//                done <= 0;
                done_reg <= 0;
                Data_join <= 'd0;
                end
 
            end
        end
assign done = valid_data_1 || done_reg || valid_data_2;
assign Data_output = Data_join;
assign state_out   = state;

endmodule