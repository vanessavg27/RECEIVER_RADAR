
module red_pitaya_pll (
  // inputs
  input  logic clk       ,  // clock
  input  logic rstn      ,  // reset - active low
  // output clocks
  output logic clk_adc   ,  // ADC clock
  output logic clk_adc2d ,  // ADC clock divided
  output logic clk_10mhz   // ADC divided to 10MHz
  //output logic clk_ser   ,  // fast serial clock
  //output logic clk_pdm   ,  // PDM clock
  //// status outputs
  //output logic pll_locked
);

logic clk_fb;

PLLE2_ADV #(
   .BANDWIDTH            ("OPTIMIZED"),
   .COMPENSATION         ("ZHOLD"    ),
   .DIVCLK_DIVIDE        ( 1         ),
   .CLKFBOUT_MULT        ( 4         ),
   .CLKFBOUT_PHASE       ( 0.000     ),
   .CLKOUT0_DIVIDE       ( 4         ),
   .CLKOUT0_PHASE        ( 0.000     ),
   .CLKOUT0_DUTY_CYCLE   ( 0.5       ),
   .CLKOUT1_DIVIDE       ( 8         ),
   .CLKOUT1_PHASE        ( 0.000     ),
   .CLKOUT1_DUTY_CYCLE   ( 0.5       ),
   .CLKOUT2_DIVIDE       ( 100       ),
   .CLKOUT2_PHASE        ( 0.000     ),
   .CLKOUT2_DUTY_CYCLE   ( 0.5       ),
   .CLKOUT3_DIVIDE       ( 4         ),
   .CLKOUT3_PHASE        (-45.000    ),
   .CLKOUT3_DUTY_CYCLE   ( 0.5       ),
   .CLKOUT4_DIVIDE       ( 4         ),  // 4->250MHz, 2->500MHz
   .CLKOUT4_PHASE        ( 0.000     ),
   .CLKOUT4_DUTY_CYCLE   ( 0.5       ),
   .CLKOUT5_DIVIDE       ( 4         ),
   .CLKOUT5_PHASE        ( 0.000     ),
   .CLKOUT5_DUTY_CYCLE   ( 0.5       ),
   .CLKIN1_PERIOD        ( 4.000     ),
   .REF_JITTER1          ( 0.010     )
) pll (
   // Output clocks
   .CLKFBOUT     (clk_fb    ),
   .CLKOUT0      (clk_adc   ),
   .CLKOUT1      (clk_adc2d ),
   .CLKOUT2      (clk_10mhz ),
   .CLKOUT3      (          ),
   .CLKOUT4      (clk_ser   ),
   .CLKOUT5      (clk_pdm   ),
   // Input clock control
   .CLKFBIN      (clk_fb    ),
   .CLKIN1       (clk       ),
   .CLKIN2       (1'b0      ),
   // Tied to always select the primary input clock
   .CLKINSEL     (1'b1 ),
   // Ports for dynamic reconfiguration
   .DADDR        (7'h0 ),
   .DCLK         (1'b0 ),
   .DEN          (1'b0 ),
   .DI           (16'h0),
   .DO           (     ),
   .DRDY         (     ),
   .DWE          (1'b0 ),
   // Other control and status signals
   .LOCKED       (pll_locked),
   .PWRDWN       (1'b0      ),
   .RST          (!rstn     )
);

endmodule: red_pitaya_pll