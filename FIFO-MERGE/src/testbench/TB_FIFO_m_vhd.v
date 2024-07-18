`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.07.2024 21:22:49
// Design Name: 
// Module Name: TB_FIFO_m_vhd
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module TB_FIFO_m_vhd(
    );
 // Parámetros de prueba
    parameter n_bits = 4;
    parameter width = 16;
    parameter afulloffset = 1;
    parameter aemptyoffset = 1;
    parameter async = 1;

    // Señales de prueba
    reg clock_wr;
    reg reset_wr;
    reg [n_bits-1:0] Data_in;
    reg clock_rd;
    reg reset_rd;
    reg start;
    wire [n_bits-1:0] Data_output;
    wire done;
    wire [2:0] state_out;

    // Instancia del módulo FIFO_merge
    FIFO_merge #(
        .n_bits(n_bits),
        .width(width),
        .afulloffset(afulloffset),
        .aemptyoffset(aemptyoffset),
        .async(async)
    ) uut (
        .clock_wr(clock_wr),
        .reset_wr(reset_wr),
        .Data_in(Data_in),
        .clock_rd(clock_rd),
        .reset_rd(reset_rd),
        .start(start),
        .Data_output(Data_output),
        .done(done),
        .state_out(state_out)
    );

    // Generación de reloj de escritura
    initial begin
        clock_wr = 0;
        forever #7 clock_wr = ~clock_wr; // Reloj con periodo de 10 ns
    end

    // Generación de reloj de lectura
    initial begin
        clock_rd = 0;
        forever #5 clock_rd = ~clock_rd; // Reloj con periodo de 14 ns
    end
    
    always @(posedge clock_wr)
        begin
        if (!reset_wr) begin
            Data_in = 0;
            end
        else begin
            Data_in = Data_in + 1;
            end
        end
    
    // Generación de señales de reset y patrones de prueba
    initial begin
        // Inicialización de señales
        reset_wr = 0;
        reset_rd = 0;
        start = 0;
        // Desactivar reset después de 20 ns
        #20 reset_wr = 1;
        reset_rd = 1;
        // Esperar algunos ciclos de reloj
        

        // Iniciar contador de 4 bits para Data_in
        #29;
        start = 1;

        #4000;
        
    end
   
    
endmodule
