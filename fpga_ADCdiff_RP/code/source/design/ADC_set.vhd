----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;

entity ADC_set is
  Generic( Bits_in :  natural :=  7;
          adc_width: natural  := 12 
  );
  Port ( -- Red Pitaya periphery
            trig_i         : in std_logic;
            pll_ref_i      : in std_logic;
            pll_hi_o       : out std_logic;
            pll_lo_o       : out std_logic;
            --clk periphery
            adc_clk_p_i    : in std_logic;
            adc_clk_n_i    : in std_logic;
            -- PS signals 
            --clk_ps_125     : in std_logic; -- 0: 125 MHz,
            clk_ps_200     : in std_logic; -- 1: 200 MHz.
            reset_ps_0     : in std_logic; -- 0: rst 125 MHZ,
            reset_ps_1     : in std_logic; -- 1 : rst 200MHz.
            -- Ch0 periphery
            adc_dat_a_p_i  : in std_logic_vector(Bits_in-1 downto 0);
            adc_dat_a_n_i  : in std_logic_vector(Bits_in-1 downto 0);
            -- Ch1 periphery
            adc_dat_b_p_i  : in std_logic_vector(Bits_in-1 downto 0);
            adc_dat_b_n_i  : in std_logic_vector(Bits_in-1 downto 0);
            -- OUT 
            clock          : out std_logic;
            adc_signal_ch0 : out std_logic_vector(2*Bits_in-1 downto 0);
            adc_signal_ch1 : out std_logic_vector(2*Bits_in-1 downto 0)
  );
end ADC_set;

architecture Behavioral of ADC_set is

    -- PLL signals
    signal    adc_clk_in     : std_logic;
    signal    reset          : std_logic;
    signal    pll_adc_clk    : std_logic;
    signal    pll_adc_clk2d  : std_logic;
    signal    pll_adc_10mhz  : std_logic;
    signal    pll_ser_clk    : std_logic;
    signal    pll_pwm_clk    : std_logic;
    signal    pll_locked     : std_logic;
    
    -- ADC clock/reset
    signal    adc_clk        : std_logic;
    signal    adc_clk2d      : std_logic; 
    signal    adc_10mhz      : std_logic;
    signal    adc_rstn       : std_logic;
    
    -- ADC differential signals
    signal adc_dat_a_ibuf, adc_dat_b_ibuf   :   std_logic_vector(Bits_in - 1 downto 0);
    signal adc_dat_a_idly, adc_dat_b_idly   :   std_logic_vector(Bits_in - 1 downto 0);

    -- 
    signal idly_rdy          : std_logic;
    signal idlyctrl_rst      : std_logic;
    
    -- IDELAY signals
    type t_cnt is array(natural range <>) of std_logic_vector(4 downto 0);
    signal  idly_cnt         : t_cnt(2*Bits_in - 1 downto 0);
    signal  idly_ce          : std_logic_vector(2*Bits_in - 1 downto 0);
    signal  idly_inc         : std_logic_vector(2*Bits_in-1 downto 0);
    signal  idly_rst         : std_logic_vector(2*Bits_in-1 downto 0); 
    
    COMPONENT red_pitaya_pll 
        PORT( 
            clk       : in std_logic;
            rstn      : in std_logic;
            -- Output clocks
            clk_adc   : out std_logic;
            clk_adc2d : out std_logic;
            clk_10mhz : out std_logic
            );
    END COMPONENT;  
    
    COMPONENT red_pitaya_hk
        PORT(
            clk_i     : in  std_logic;
            rstn_i    : in  std_logic;
            pll_sys_i : in  std_logic;
            pll_ref_i : in  std_logic;
            pll_hi_o  : out std_logic;
            pll_lo_o  : out std_logic 
        );
    END COMPONENT;
    
    signal adc_a      : std_logic_vector(2*Bits_in - 1 downto 0);
    signal adc_b      : std_logic_vector(2*Bits_in - 1 downto 0);

begin

    -- Diferential clock input
    iCLOCK: IBUFDS port map(I => adc_clk_p_i, IB => adc_clk_n_i, O => adc_clk_in);
    
    PLL: red_pitaya_pll 
         PORT MAP( clk => adc_clk_in, rstn => reset_ps_0, clk_adc => pll_adc_clk,
                   clk_adc2d => pll_adc_clk2d, clk_10mhz => pll_adc_10mhz);            

    BUFF_adc_clk_250MHz: BUFG port map(I =>   pll_adc_clk, O =>   adc_clk);
    BUFF_adc_clk_125MHz: BUFG port map(I => pll_adc_clk2d, O => adc_clk2d);
    BUFF_adc_clk_10MHz:  BUFG port map(I => pll_adc_10mhz, O => adc_10mhz);
    
    process(adc_clk2d)
        begin
        adc_rstn <= reset_ps_0;
    end process;  
       
       HK_RP: red_pitaya_hk
         PORT MAP(  clk_i => adc_clk2d, rstn_i => adc_rstn, pll_sys_i => adc_10mhz,
                    pll_ref_i => pll_ref_i, pll_hi_o => pll_hi_o, pll_lo_o => pll_lo_o
                );

    ADC_Input_Buffer: for i in 0 to Bits_in - 1 generate
        IBUFDS_A_X: IBUFDS
            port map(I => adc_dat_a_p_i(i), IB => adc_dat_a_n_i(i), O => adc_dat_a_ibuf(i));
        
        IBUFDS_B_X: IBUFDS
            port map(I => adc_dat_b_p_i(i), IB => adc_dat_b_n_i(i), O => adc_dat_b_ibuf(i));
    end generate ADC_Input_Buffer;
    
    idlyctrl_rst <= not(reset_ps_1 );
    
    IDELAYCTRL_i: IDELAYCTRL
    port map(
        RDY     =>  idly_rdy,    -- 1-bit output: Ready output
        REFCLK  =>  clk_ps_200, -- 1-bit input: Reference clock input
        RST     =>  idlyctrl_rst -- 1-bit input: Active high reset input
    );

    idly_rst <= (others => '0');

    IDELAY_GEN: for GV in 0 to Bits_in - 1 generate
        IDELAY_A: IDELAYE2
            generic map(
                DELAY_SRC               =>  "IDATAIN",
                HIGH_PERFORMANCE_MODE   =>  "TRUE",
                IDELAY_TYPE             =>  "VARIABLE",
                IDELAY_VALUE            =>  0,
                PIPE_SEL                =>  "FALSE",
                REFCLK_FREQUENCY        =>  200.0,
                SIGNAL_PATTERN          =>  "DATA"
                )
            port map(
                CNTVALUEOUT =>  idly_cnt(GV),
                DATAOUT     =>  adc_dat_a_idly(GV),
                C           =>  adc_clk2d,
                CE          =>  idly_ce(GV),
                CINVCTRL    =>  '0',
                CNTVALUEIN  =>  "00000",
                DATAIN      =>  '0',
                IDATAIN     =>  adc_dat_a_ibuf(GV),
                INC         =>  idly_inc(GV),
                LD          =>  idly_rst(GV),
                LDPIPEEN    =>  '0',
                REGRST      =>  '0'
                );
    
        IDELAYB: IDELAYE2
            generic map(
                DELAY_SRC               =>  "IDATAIN",
                HIGH_PERFORMANCE_MODE   =>  "TRUE",
                IDELAY_TYPE             =>  "VARIABLE",
                IDELAY_VALUE            =>  0,
                PIPE_SEL                =>  "FALSE",
                REFCLK_FREQUENCY        =>  200.0,
                SIGNAL_PATTERN          =>  "DATA"
                )
            port map(
                CNTVALUEOUT =>  idly_cnt(GV+7),
                DATAOUT     =>  adc_dat_b_idly(GV),
                C           =>  adc_clk2d,
                CE          =>  idly_ce(GV+7),
                CINVCTRL    =>  '0',
                CNTVALUEIN  =>  "00000",
                DATAIN      =>  '0',
                IDATAIN     =>  adc_dat_b_ibuf(GV),
                INC         =>  idly_inc(GV+7),
                LD          =>  idly_rst(GV+7),
                LDPIPEEN    =>  '0',
                REGRST      =>  '0'
                );
    end generate IDELAY_GEN;

    IDDR_ADC: for GV in 0 to Bits_in - 1 generate
    
          IDDR_A: IDDR generic map(DDR_CLK_EDGE    =>  "SAME_EDGE_PIPELINED")
                        port map( Q1 => adc_a(2*GV), Q2 => adc_a(2*GV+1), C => adc_clk,
                                  CE => '1', D => adc_dat_a_idly(GV), R => '0', S => '0');
                                  
          IDDR_B: IDDR generic map(DDR_CLK_EDGE    =>  "SAME_EDGE_PIPELINED")
                        port map( Q1 => adc_b(2*GV), Q2 => adc_b(2*GV+1), C => adc_clk,
                                  CE => '1', D => adc_dat_b_idly(GV), R => '0', S => '0');
    end generate;
    
    
    
    clock <= adc_clk;
    
    process(adc_clk2d)
        begin
        adc_rstn <= reset_ps_0;
    end process;
    
    process(adc_clk)
        begin
            if rising_edge(adc_clk) then
                if adc_rstn = '0' then
                    adc_signal_ch0 <= (others => '0');
                    adc_signal_ch1 <= (others => '0');
                else
                    --adc_signal_ch0 <= adc_a((14-1) downto (2));
                    adc_signal_ch0 <= std_logic_vector(signed(adc_a));
                    --adc_signal_ch1 <= adc_b((14-1) downto (2));
                    adc_signal_ch1 <= std_logic_vector(signed(adc_b));
                end if;
            end if;
    end process;
            
end Behavioral;