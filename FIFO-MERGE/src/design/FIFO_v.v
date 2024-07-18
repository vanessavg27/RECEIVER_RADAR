`timescale 1 ns / 1 ps

//COMPANY:  JICAMARCA RADIO OBSERVATORY
//ENGINEER: VANESSA VASQUEZ.

module FIFO_v #(parameter integer DWIDTH=4,
                parameter integer DEPTH=16,
                parameter integer AFULLOFFSET=1,
                parameter integer AEMPTYOFFSET=1,
                parameter integer ASYNC= 1)
  ( // Write side
    input wire wclk_i, wrst_i, wen_i,
    input wire [DWIDTH-1:0] data_i,
    output wire full_o,
    output wire afull_o, overflow_o,
    output reg [15:0] wcount_o,
    // Read side
    input wire rclk_i, rrst_i, ren_i,
    output wire [DWIDTH-1:0] data_o,
    output wire empty_o,
    output wire aempty_o, underflow_o,
    output wire valid_o,
    output reg [15:0] rcount_o
  );
  
function [5:0] clog2;
  input [31:0] arg;
  integer i;
  begin
    for (i = 0; i < 32; i = i + 1)
    begin
      if (arg <= (1 << i))
      begin
        clog2 = i;
      end
    end
    clog2 = 6'd32; // Assuming a 6-bit return type
  end
endfunction

  // Constants
  localparam integer EVEN_DEPTH = DEPTH + (DEPTH % 2);
  localparam integer AWIDTH = $clog2(EVEN_DEPTH);
  localparam integer DIFF_DEPTH = 2**AWIDTH - EVEN_DEPTH;
  
  // Signals
  wire rst;
  wire wen, ren;
  reg  full_r;
  wire full;
  
  reg empty_r;
  wire empty;
  
  wire [AWIDTH-1:0] wr_addr, rd_addr;
  reg valid_r;
  reg [AWIDTH:0] wcount, rcount;
  reg [AWIDTH:0] wr_ptr_r = {AWIDTH{1'b0}};
  reg [AWIDTH:0] wr_ptr  = {AWIDTH{1'b0}};
  reg [AWIDTH:0] rd_in_wr_ptr ={AWIDTH{1'b0}};
  
  reg [AWIDTH:0] rd_ptr_r = {AWIDTH{1'b0}};
  reg [AWIDTH:0] rd_ptr  = {AWIDTH{1'b0}};
  reg [AWIDTH:0] wr_in_rd_ptr={AWIDTH{1'b0}};
  
  reg [AWIDTH:0]  wr_bin;
  wire [AWIDTH:0] rd_in_wr_bin;

  
  reg [AWIDTH:0]  rd_bin;
  wire [AWIDTH:0] wr_in_rd_bin;
  
  task automatic next_function;
        input ena;
        input [AWIDTH:0] ptr;
        output [AWIDTH:0] next_ptr;
        begin
            if (ena == 1'b1 && ptr[AWIDTH-1:0] == EVEN_DEPTH-1)
                next_ptr = {~ptr[AWIDTH], {AWIDTH{1'b0}}};
            else if (ena == 1'b1)
                next_ptr = ptr + 1;
            else
                next_ptr = ptr ;       
        end
   endtask
   
   task automatic diff_function;
       input [AWIDTH:0] wr_ptr;
       input [AWIDTH:0] rd_ptr;
       output [AWIDTH:0] diff_ptr;
       reg [1:0] status;
       begin
           status = {wr_ptr[AWIDTH], rd_ptr[AWIDTH]};
           case (status)
               2'b00, 2'b11: diff_ptr = wr_ptr - rd_ptr;
               2'b10: diff_ptr = wr_ptr - DIFF_DEPTH - rd_ptr;
               2'b01: diff_ptr = {(~wr_ptr[AWIDTH]),wr_ptr[AWIDTH-1:0]}-DIFF_DEPTH-{(~rd_ptr[AWIDTH]),rd_ptr[AWIDTH-1:0]};
               default: diff_ptr = {AWIDTH{1'b0}};
           endcase
       end
   endtask
    
   assign rst =   wrst_i || rrst_i;
  
    tdpram_v #(
            .AWIDTH(AWIDTH),
            .DWIDTH(DWIDTH),
            .DEPTH(DEPTH))
     i_memory(
            .clk1_i(wclk_i),   .clk2_i(rclk_i),
            .wen1_i(wen),      .wen2_i(1'b0),
            .addr1_i(wr_addr), .addr2_i(rd_addr),
            .data1_i(data_i),  .data2_i({DWIDTH{1'b0}}),
            .data1_o(),        .data2_o(data_o)
        );
  
  // Async logic
generate
    if (!ASYNC) begin
        always@(*) begin
         rd_in_wr_ptr = rd_ptr_r;
         wr_in_rd_ptr = wr_ptr_r;
        end
    end
endgenerate

generate
    if (ASYNC) begin
      ///////////////////////////////////
      // From read to write side (CDC) //
      ///////////////////////////////////
        always @(rd_ptr_r) begin
            if (rd_ptr_r[AWIDTH] == 1'b0) begin
                rd_bin = rd_ptr_r + DIFF_DEPTH;
            end else begin
                rd_bin = rd_ptr_r;
            end
        end
        //graysync #(AWIDTH+1, 2)
        GraySync_v #(AWIDTH+1, 2)
        i_sync_rd2wr (
            .clk_i(wclk_i),
            .data_i(rd_bin),
            .data_o(rd_in_wr_bin)
            );
            
        always @(*) begin
            if (rd_in_wr_bin[AWIDTH] == 1'b0) begin
                rd_in_wr_ptr <= rd_in_wr_bin - DIFF_DEPTH;
            end else begin
                rd_in_wr_ptr <= rd_in_wr_bin;
            end
        end
      ///////////////////////////////////
      // From write to read side (CDC) //
      ///////////////////////////////////
        always @(*) begin
            if (wr_ptr_r[AWIDTH] == 1'b0) begin
                wr_bin = wr_ptr_r + DIFF_DEPTH;
            end else begin
                wr_bin = wr_ptr_r;
            end
        end
        
        //graysync #(AWIDTH+1, 2) 
        GraySync_v #(AWIDTH+1, 2)
        i_sync_wr2rd (
            .clk_i(rclk_i),
            .data_i(wr_bin),
            .data_o(wr_in_rd_bin)
            );
        
        always @(*) begin
            if (wr_in_rd_bin[AWIDTH] == 1'b0) begin
                wr_in_rd_ptr = wr_in_rd_bin - DIFF_DEPTH;
            end else begin
                wr_in_rd_ptr = wr_in_rd_bin;
            end
        end
    end    
endgenerate

//////////////////////////////////////////////////////////////////////
// WRITE SIDE
//////////////////////////////////////////////////////////////////////
assign  wr_addr = wr_ptr_r[AWIDTH-1 : 0];
assign wen = (wen_i && (full_r !== 1'b1)) ? 1'b1 : 1'b0;

always @(posedge wclk_i) begin
    full_r <= 1'b0;
    if (rst == 1'b0) begin
        wr_ptr_r <= 0;
        full_r <= 1'b0;
    end else begin
        wr_ptr_r <= wr_ptr;
        full_r <= full;
    end
end

always @(*) // whenever A or B changes in value
    begin
       next_function(wen, wr_ptr_r, wr_ptr);
    end
     
always @(*) // whenever A or B changes in value
    begin
       diff_function(wr_ptr, rd_in_wr_ptr, wcount);
    end

assign full       = (wcount == EVEN_DEPTH) ? 1'b1 : 1'b0;
assign full_o     = full;
assign afull_o    = (wcount >= EVEN_DEPTH-AFULLOFFSET) ? 1'b1 : 1'b0;
assign overflow_o = (wen_i && full_r) ? 1'b1 : 1'b0;

//////////////////////////////////////////////////////////////////////
// READ SIDE
//////////////////////////////////////////////////////////////////////
assign rd_addr = rd_ptr_r[AWIDTH-1:0];
assign ren = (ren_i && (empty_r != 1'b1)) ? 1'b1 : 1'b0;

always @(posedge rclk_i) begin
    empty_r <= 1'b1;
    valid_r <= ren;    
    if (rst == 1'b0) begin
        rd_ptr_r <= {AWIDTH{1'b0}};
        valid_r <= 1'b0;
    end
    else begin
        rd_ptr_r <= rd_ptr;
        empty_r  <= empty;
    end
end

always @(*) // whenever A or B changes in value
    begin
       next_function(ren, rd_ptr_r, rd_ptr);
    end

always @(*) // whenever A or B changes in value
    begin
       diff_function(wr_in_rd_ptr, rd_ptr, rcount);
    end
    
assign empty    = (rcount == 0) ? 1'b1 : 1'b0;
assign empty_o  = empty;
assign aempty_o = (rcount <= AEMPTYOFFSET) ? 1'b1 : 1'b0;
assign underflow_o = (ren_i && empty_r) ?  1'b1 : 1'b0;

assign valid_o = valid_r;

//////////////////////////////////////////////////////////////////////
// Export the internal diff between pointers
//////////////////////////////////////////////////////////////////////
always @(wcount, rcount) begin
    wcount_o = {AWIDTH{1'b0}};
    rcount_o = {AWIDTH{1'b0}};
    
    if (AWIDTH < 16) begin
        wcount_o[AWIDTH:0] <= wcount;
        rcount_o[AWIDTH:0] <= rcount;
    end
    else begin
            if (wcount < 16'hFFFF)
                wcount_o <= wcount[15:0];
            else
                wcount_o = {AWIDTH{1'b1}};
        
            if (rcount < 16'hFFFF)
                rcount_o = rcount[15:0];
            else
                rcount_o = {AWIDTH{1'b1}};
    end
end
 
endmodule