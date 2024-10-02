module red_pitaya_hk #(
  parameter DWL = 8, // data width for LED
  parameter DWE = 8, // data width for extension
  parameter [57-1:0] DNA = 57'h0823456789ABCDE
)(
  // system signals
  input                clk_i      ,  // clock
  input                rstn_i     ,  // reset - active low
  // LED
  //output reg [DWL-1:0] led_o      ,  // LED output
//  // idelay control
//  output reg [2*7-1:0] idly_rst_o,
//  output reg [2*7-1:0] idly_ce_o ,
//  output reg [2*7-1:0] idly_inc_o,
//  input      [2*5-1:0] idly_cnt_i,
  // global configuration
  input                pll_sys_i,    // system clock
  input                pll_ref_i,    // reference clock
  output               pll_hi_o,     // PLL high
  output               pll_lo_o     // PLL low
);

//---------------------------------------------------------------------------------
//
//  Read device DNA
wire           dna_dout ;
reg            dna_clk  ;
reg            dna_read ;
reg            dna_shift;
reg  [ 9-1: 0] dna_cnt  ;
reg  [57-1: 0] dna_value;
reg            dna_done ;

always @(posedge clk_i)
if (rstn_i == 1'b0) begin
  dna_clk   <=  1'b0;
  dna_read  <=  1'b0;
  dna_shift <=  1'b0;
  dna_cnt   <=  9'd0;
  dna_value <= 57'd0;
  dna_done  <=  1'b0;
end else begin
  if (!dna_done)
    dna_cnt <= dna_cnt + 1'd1;

  dna_clk <= dna_cnt[2] ;
  dna_read  <= (dna_cnt < 9'd10);
  dna_shift <= (dna_cnt > 9'd18);

  if ((dna_cnt[2:0]==3'h0) && !dna_done)
    dna_value <= {dna_value[57-2:0], dna_dout};

  if (dna_cnt > 9'd465)
    dna_done <= 1'b1;
end

// parameter specifies a sample 57-bit DNA value for simulation
DNA_PORT #(.SIM_DNA_VALUE (DNA)) i_DNA (
  .DOUT  ( dna_dout   ), // 1-bit output: DNA output data.
  .CLK   ( dna_clk    ), // 1-bit input: Clock input.
  .DIN   ( 1'b0       ), // 1-bit input: User data input pin.
  .READ  ( dna_read   ), // 1-bit input: Active high load DNA, active low read input.
  .SHIFT ( dna_shift  )  // 1-bit input: Active high shift enable input.
);

//---------------------------------------------------------------------------------
//
//  Design identification
wire [32-1: 0] id_value;

assign id_value[31: 4] = 28'h0; // reserved
assign id_value[ 3: 0] =  4'h2; // board type  2 - 250MHz
                                //             1 - release 1

//---------------------------------------------------------------------------------
//
//  Simple FF PLL 

// detect RF clock
reg  [16-1:0] pll_ref_cnt = 16'h0;
reg  [ 3-1:0] pll_sys_syc  ;
reg  [21-1:0] pll_sys_cnt  ;
reg           pll_sys_val  ;
reg           pll_cfg_en   ;
wire [32-1:0] pll_cfg_rd   ;

always @(posedge pll_ref_i) begin
  pll_ref_cnt <= pll_ref_cnt + 16'h1;
end

always @(posedge clk_i) 
if (rstn_i == 1'b0) begin
  pll_sys_syc <=  3'h0 ;
  pll_sys_cnt <= 21'h100000;
  pll_sys_val <=  1'b0 ;
end else begin
  pll_sys_syc <= {pll_sys_syc[3-2:0], pll_ref_cnt[14-1]} ;

  if (pll_sys_syc[3-1] ^ pll_sys_syc[3-2])
    pll_sys_cnt <= 21'h1;
  else if (!pll_sys_cnt[21-1])
    pll_sys_cnt <= pll_sys_cnt + 21'h1;

  // pll_sys_clk must be around 102400 (125000000/(10000000/2^13))
  if (pll_sys_syc[3-1] ^ pll_sys_syc[3-2])
    pll_sys_val <= (pll_sys_cnt > 102385) && (pll_sys_cnt < 102415) ;
  else if (pll_sys_cnt[21-1])
    pll_sys_val <= 1'b0 ;
end


reg  pll_ff_sys ;
reg  pll_ff_ref ;
wire pll_ff_rst ;
wire pll_ff_lck ;

// FF PLL functionality
always @(posedge pll_sys_i or negedge pll_ff_rst) begin
  if (!pll_ff_rst)  pll_ff_sys <= 1'b0 ;
  else              pll_ff_sys <= 1'b1 ;
end
always @(posedge pll_ref_i or negedge pll_ff_rst) begin
  if (!pll_ff_rst)  pll_ff_ref <= 1'b0 ;
  else              pll_ff_ref <= 1'b1 ;
end
assign pll_ff_rst = !(pll_ff_sys && pll_ff_ref) ;
assign pll_ff_lck = (!pll_ff_sys && !pll_ff_ref);

assign pll_lo_o = !pll_ff_sys && ( pll_sys_val &&  pll_cfg_en);
assign pll_hi_o =  pll_ff_ref || (!pll_sys_val || !pll_cfg_en);


// filter out PLL lock status
reg  [21-1:0] pll_lck_lcnt  ;
reg  [21-1:0] pll_lck_hcnt  ;
reg  [ 4-1:0] pll_lck_sts  ;

always @(posedge clk_i) 
if (rstn_i == 1'b0) begin
  pll_lck_lcnt <= 21'h0 ;
  pll_lck_hcnt <= 21'h0 ;
  pll_lck_sts <=   2'b0 ;
end else begin

  if (pll_sys_syc[3-1] ^ pll_sys_syc[3-2])
    pll_lck_lcnt <= 21'h1;
  else if (pll_lo_o)
    pll_lck_lcnt <= pll_lck_lcnt + 21'h1;

  if (pll_sys_syc[3-1] ^ pll_sys_syc[3-2])
    pll_lck_hcnt <= 21'h1;
  else if (!pll_hi_o)
    pll_lck_hcnt <= pll_lck_hcnt + 21'h1;


  // pll_lck_cnt threshold 70% of whole period
  if (pll_sys_syc[3-1] ^ pll_sys_syc[3-2])
    pll_lck_sts[0] <= (pll_lck_lcnt > 21'd80000) && (pll_lck_hcnt > 21'd80000);

  pll_lck_sts[1] <= pll_lck_sts[0] && pll_sys_val;

  if (pll_sys_syc[3-1] ^ pll_sys_syc[3-2])
    pll_lck_sts[3:2] <= {(pll_lck_lcnt > 21'd80000), (pll_lck_hcnt > 21'd80000)};
end

assign pll_cfg_rd = {{32-14{1'h0}}, pll_lck_sts[3:2], 3'h0,pll_lck_sts[1], 3'h0,pll_sys_val, 3'h0,pll_cfg_en};

endmodule
