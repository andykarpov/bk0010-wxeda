library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;

entity sound is
  port (
    clk         : in  std_logic;
    reset       : in  std_logic;

    ADC_CLK     : out std_logic;
    ADC_DAT     : in std_logic;
    ADC_CS_N    : out std_logic;

    tape_in     : out std_logic;
    tape_out    : in std_logic;
    beeper      : in std_logic;

    out_l       : out std_logic;
    out_r       : out std_logic
);
end sound;

architecture rtl of sound is

signal audio_l          : std_logic_vector(11 downto 0);
signal audio_r          : std_logic_vector(11 downto 0);
signal linein           : std_logic_vector(7 downto 0);
signal tapein           : std_logic;

begin

-- Delta-Sigma L
UDACL: entity work.dac
port map (
    CLK         => clk,
    RESET       => reset,
    DAC_DATA    => audio_l,
    DAC_OUT     => out_l);

-- Delta-Sigma R
UDACR: entity work.dac
port map (                                               
    CLK         => clk,
    RESET       => reset,                       
    DAC_DATA    => audio_r,
    DAC_OUT     => out_r);

-- ADC
UADC : entity work.tlc549
generic map (
    frequency   => 100,  -- 100 MHz
    samplerate  => 40000 -- 40 kHz                    
)
port map (
    clk         => clk,
    reset       => reset,                                      
    adc_data    => ADC_DAT,
    adc_clk     => ADC_CLK,
    adc_cs_n    => ADC_CS_N,
    data_out    => linein,
    clk_out     => open
);

-- 12bit Delta-Sigma DAC
audio_l <=        
                  ("0000" & tape_out & "0000000");

audio_l <=        
                  ("0000" & tape_out & "0000000");

-- assign "tape in" output with value from ADC
tape_in <= tapein;

-- ADC to tapein conversion
process (clk, tapein, linein)
variable HYST: integer := 4;
variable LEVEL: integer := 128;
begin
        if rising_edge(clk) then
        if (tapein = '1' and linein < LEVEL - HYST) then
            tapein <= '0';
        elsif (tapein = '0' and linein > LEVEL + HYST) then
            tapein <= '1';
        end if;
        end if;
end process;

end rtl;
