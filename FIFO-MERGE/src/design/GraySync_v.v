`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
//////////////////////////////////////////////////////////////////////////////////


module GraySync_v#(
    parameter WIDTH = 8,
    parameter DEPTH = 2
) (
    input wire clk_i,
    input wire [WIDTH-1:0] data_i,
    output reg [WIDTH-1:0] data_o
);

    reg [WIDTH-1:0] grayi;
    reg [WIDTH-1:0] grayo;
    reg [WIDTH-1:0] data_r[0:DEPTH-1];
    integer count;
    // Convert Binary to Gray code
    function [WIDTH-1:0] bin2gray;
        input [WIDTH-1:0] arg;
        begin
            bin2gray = (arg >> 1) ^ arg;
        end
    endfunction

    // Convert Gray code to Binary
    function [WIDTH-1:0] gray2bin;
        input [WIDTH-1:0] arg;
        integer i;
        reg [WIDTH-1:0] bin;
        begin
            bin[WIDTH-1] = arg[WIDTH-1]; // Most significant bit remains the same
            for (i = WIDTH-2; i >= 0; i = i - 1) begin
                bin[i] = bin[i+1] ^ arg[i]; // XOR with the bit to the left
            end
            gray2bin = bin;
        end
    endfunction

    always @(posedge clk_i) begin
        grayi <= bin2gray(data_i);
        
        for (count = 0; count < DEPTH; count = count + 1) begin
            if (count == 0) begin
                data_r[0] <= grayi;
            end else begin
                data_r[count] <= data_r[count-1];
            end
        end
        grayo <= data_r[DEPTH-1];
        data_o <= gray2bin(grayo);
    end
endmodule