`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
//////////////////////////////////////////////////////////////////////////////////
module tdpram_v#(
parameter AWIDTH = 8,  // Address width
    parameter DWIDTH = 8,  // Data width
    parameter DEPTH = 0    // Memory depth
)(
    input clk1_i,
    input clk2_i,
    input wen1_i,
    input wen2_i,
    input [AWIDTH-1:0] addr1_i,
    input [AWIDTH-1:0] addr2_i,
    input [DWIDTH-1:0] data1_i,
    input [DWIDTH-1:0] data2_i,
    output reg [DWIDTH-1:0] data1_o,
    output reg [DWIDTH-1:0] data2_o
);

    // Determine the memory size based on depth and address width
    function integer getMemorySize;
        input integer depth;
        input integer awidth;
        begin
            if (depth == 0)
                getMemorySize = 1 << awidth;
            else
                getMemorySize = depth;
        end
    endfunction

    localparam SIZE = getMemorySize(DEPTH, AWIDTH);
    
    // Define the RAM as a 2D array
    reg [DWIDTH-1:0] ram [0:SIZE-1];
    
    // Write process for clk1_i
    always @(posedge clk1_i) begin
        if (wen1_i) begin
            ram[addr1_i] <= data1_i;
            data1_o <= data1_i;
        end else begin
            data1_o <= ram[addr1_i];
        end
    end

    // Write process for clk2_i
    always @(posedge clk2_i) begin
        if (wen2_i) begin
            ram[addr2_i] <= data2_i;
            data2_o <= data2_i;
        end else begin
            data2_o <= ram[addr2_i];
        end
    end

endmodule