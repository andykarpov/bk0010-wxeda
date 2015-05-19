library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.ALL;    

entity bk0010_wxeda is                   
	port(

		-- Clock (48MHz)
		CLK				: in std_logic;

		-- SDRAM (32MB 16x16bit)
		SDRAM_DQ		: inout std_logic_vector(15 downto 0);
		SDRAM_A			: out std_logic_vector(12 downto 0);
		SDRAM_BA		: out std_logic_vector(1 downto 0);
		SDRAM_CLK		: out std_logic;
		SDRAM_DQML		: out std_logic;
		SDRAM_DQMH		: out std_logic;
		SDRAM_WE_N		: out std_logic;
		SDRAM_CAS_N		: out std_logic;
		SDRAM_RAS_N		: out std_logic;
		SDRAM_CKE      	: out std_logic := '1';
		SDRAM_CS_N     	: out std_logic := '0';

		-- SPI FLASH (W25Q32)
		--FLASH_SO		: in std_logic;
		--FLASH_CLK		: out std_logic;
		--FLASH_SI		: out std_logic;
		--FLASH_CS_N		: out std_logic;

		-- EPCS4
		--EPCS_SO			: in std_logic;
		--EPCS_CLK		: out std_logic;
		--EPCS_SI			: out std_logic;
		--EPCS_CS_N		: out std_logic;

		-- VGA 5:6:5
		VGA_R			: out std_logic_vector(4 downto 0);
		VGA_G			: out std_logic_vector(5 downto 0);
		VGA_B			: out std_logic_vector(4 downto 0);
		VGA_HS			: out std_logic;
		VGA_VS			: out std_logic;

		-- SD/MMC Memory Card
		SD_SO			: in std_logic;
		SD_SI			: out std_logic;
		SD_CLK			: out std_logic;
		SD_CS_N			: out std_logic;

		-- External I/O
		DAC_OUT_L		: out std_logic; 
		DAC_OUT_R		: out std_logic; 
		KEYS			: in std_logic_vector(3 downto 0);
		BUZZER			: out std_logic;

		-- ADC
		ADC_CLK			: out std_logic;
		ADC_DAT			: in std_logic;
		ADC_CS_N		: out std_logic;

		-- UART
		UART_TXD		: inout std_logic;
		UART_RXD		: inout std_logic;

		-- PS/2 Keyboard
		PS2_CLK			: inout std_logic;
		PS2_DAT 		: inout std_logic

	);
end bk0010_wxeda;  

architecture bk0010_wxeda_arch of bk0010_wxeda is

-- SDRAM_Controller.v
component SDRAM_Controller 
port (
	clk 			: in std_logic;
	reset 			: in std_logic;
	
	DRAM_DQ 		: inout std_logic_vector(15 downto 0);
	DRAM_ADDR 		: out std_logic_vector(11 downto 0);
	DRAM_LDQM 		: out std_logic;
	DRAM_UDQM 		: out std_logic;
	DRAM_WE_N 		: out std_logic;
	DRAM_CAS_N 		: out std_logic;
	DRAM_RAS_N 		: out std_logic;
	DRAM_CS_N 		: out std_logic;
	DRAM_BA_0 		: out std_logic;
	DRAM_BA_1 		: out std_logic;

	iaddr 			: in std_logic_vector(21 downto 0) := (others => '0');
	dataw 			: in std_logic_vector(15 downto 0);
	datar 			: out std_logic_vector(15 downto 0);
	rd 				: in std_logic;
	we_n 			: in std_logic;
	ilb_n 			: in std_logic;
	iub_n 			: in std_logic;
	membusy 		: out std_logic
);
end component;

-- vram.v
component vram
port (
	byteena_a		: in std_logic_vector(1 downto 0);
	clock 			: in std_logic;
	data 			: in std_logic_vector(15 downto 0);
	rdaddress 		: in std_logic_vector(12 downto 0);
	wraddress 		: in std_logic_vector(12 downto 0);
	wren 			: in std_logic;
	q 				: out std_logic_vector(15 downto 0)
);
end component;

-- bk0010.v
component bk0010 
port (
	clk50 			: in std_logic;
	clk25 			: in std_logic;
	reset_in 		: in std_logic;
	hypercharge_i 	: in std_logic;
	PS2_Clk 		: in std_logic;
	PS2_Data 		: in std_logic;
	button0 		: in std_logic := '0';

	SD_DAT 			: in std_logic;
	SD_DAT3 		: out std_logic;
	SD_CMD 			: out std_logic;
	SD_CLK 			: out std_logic;

	greenleds 		: out std_logic_vector(7 downto 0);
	switch 			: in std_logic_vector(7 downto 0) := "00000000";
	ram_addr 		: out std_logic_vector(17 downto 0);
	ram_a_datar 	: in std_logic_vector(15 downto 0);
	ram_a_dataw 	: out std_logic_vector(15 downto 0);
	ram_a_ce 		: out std_logic;
	ram_a_lb 		: out std_logic;
	ram_a_ub 		: out std_logic;
	ram_we_n 		: out std_logic;
	ram_oe_n 		: out std_logic;
	vga_addr 		: out std_logic_vector(12 downto 0);
	vdata 			: in std_logic_vector(15 downto 0);
	membusy 		: in std_logic;

	VGA_RED 		: out std_logic;
	VGA_GREEN 		: out std_logic;
	VGA_BLUE 		: out std_logic;
	VGA_HS 			: out std_logic;
	VGA_VS 			: out std_logic;

	tape_out 		: out std_logic;
	tape_in 		: in std_logic;

	cpu_rd 			: out std_logic;
	cpu_wt 			: out std_logic;
	cpu_oe_n 		: out std_logic;
	ifetch 			: out std_logic;
	cpu_adr 		: out std_logic_vector(17 downto 0);
	redleds 		: out std_logic_vector(7 downto 0);
	cpu_opcode 		: out std_logic_vector(15 downto 0);
	cpu_sp 			: out std_logic_vector(15 downto 0);
	ram_out_data 	: out std_logic_vector(15 downto 0)            
);
end component;

-- SIGNALS 

-- reset and clk
signal reset 		: std_logic;
signal start 		: std_logic;
signal locked 		: std_logic;
signal hypercharge 	: std_logic;
signal clk_75, clk_50, clk_25 : std_logic;

-- ram
signal ram_a_bus	: std_logic_vector(21 downto 0);
signal ram_di_bus 	: std_logic_vector(15 downto 0);
signal ram_do_bus 	: std_logic_vector(15 downto 0);
signal ram_we_n 	: std_logic;
signal ram_oe_n 	: std_logic;
signal ram_lb_n 	: std_logic;
signal ram_ub_n 	: std_logic;
signal ram_busy 	: std_logic;

-- video
signal vga_a_bus 	: std_logic_vector(12 downto 0);
signal vga_do_bus 	: std_logic_vector(15 downto 0);
signal vga_wren 	: std_logic;

-- sound
signal tape_in 		: std_logic;
signal tape_out 	: std_logic;

begin

-- PLL
U0: entity work.altpll1
port map (
	inclk0		=> CLK,		--  48.0 MHz
	locked		=> locked,
	c0 			=> clk_75, 	-- 75 MHz
	c1			=> clk_50, 	-- 50 MHz
	c2			=> clk_25 	-- 25 MHz
);

-- SDRAM Controller
U1: SDRAM_Controller 
port map (
	clk 		=> clk_75,		-- clock 75 Mhz
	reset 		=> reset, 		-- system reset

	DRAM_DQ 	=> SDRAM_DQ, 	-- SDRAM data bus
	DRAM_ADDR 	=> SDRAM_A(11 downto 0), 	-- SDRAM address bus
	DRAM_LDQM 	=> SDRAM_DQML, 	-- SDRAM low-byte data mask
	DRAM_UDQM 	=> SDRAM_DQMH, 	-- SDRAM high-byte data mask
	DRAM_WE_N 	=> SDRAM_WE_N, 	-- SDRAM write enable
	DRAM_CAS_N 	=> SDRAM_CAS_N, -- SDRAM column address strobe
	DRAM_RAS_N  => SDRAM_RAS_N, -- SDRAM row address strobe
	DRAM_CS_N   => SDRAM_CS_N, 	-- SDRAM chip select
	DRAM_BA_0	=> SDRAM_BA(0), -- SDRAM bank address
	DRAM_BA_1 	=> SDRAM_BA(1), -- SDRAM bank address

	iaddr 		=> ram_a_bus,
	dataw 		=> ram_di_bus,
	datar 		=> ram_do_bus,
	rd 			=> not ram_oe_n,
	we_n 		=> ram_we_n,
	ilb_n 		=> ram_lb_n,
	iub_n 		=> ram_ub_n,
	membusy 	=> ram_busy
);

U2: vram
port map(
	byteena_a 	=> (not ram_ub_n) & (not ram_lb_n),
	clock 		=> clk_75,
	data 		=> ram_di_bus,
	rdaddress 	=> vga_a_bus,
	wraddress 	=> ram_a_bus(12 downto 0),
	wren 		=> vga_wren,
	q 			=> vga_do_bus
);

vga_wren <= '1' when ram_we_n = '0' and ram_a_bus(17 downto 13) = "00001" else '0';

U3: bk0010 
port map (
	clk50 		=> clk_50,
	clk25 		=> clk_25,
	reset_in 	=> reset,
	hypercharge_i => hypercharge,

	PS2_Clk 	=> PS2_CLK,
	PS2_Data	=> PS2_DAT,

	SD_DAT 		=> SD_SO,
	SD_DAT3 	=> SD_CS_N,
	SD_CLK 		=> SD_CLK,
	SD_CMD 		=> SD_SI,

	VGA_RED 	=> VGA_R(4),
	VGA_GREEN	=> VGA_G(5),
	VGA_BLUE 	=> VGA_B(4),
	VGA_HS 		=> VGA_HS,
	VGA_VS 		=> VGA_VS,

	ram_addr	=> ram_a_bus(17 downto 0),
	ram_a_datar => ram_do_bus,
	ram_a_dataw => ram_di_bus,
	ram_a_ce 	=> open,
	ram_a_lb 	=> ram_lb_n,
	ram_a_ub 	=> ram_ub_n,
	ram_we_n 	=> ram_we_n,
	ram_oe_n 	=> ram_oe_n,
	ram_out_data=> open,

	vga_addr 	=> vga_a_bus,
	vdata 		=> vga_do_bus,
	membusy 	=> ram_busy,

	tape_in 	=> tape_in,
	tape_out 	=> tape_out,

	cpu_rd 		=> open,
	cpu_wt		=> open,
	cpu_oe_n 	=> open,

	ifetch 		=> open,
	cpu_adr 		=> open,
	cpu_opcode  => open,
	cpu_sp 		=> open,

	redleds 		=> open,
	greenleds 	=> open,
	button0 	=> not(KEYS(2)),
	switch 		=> "10000000" --(7 - cpu_pause_n=1, 6 - enable_bpts=0, 5,3,4,2,1 = 0, 0 - color=0)
        
);

--U4: entity work.soundcodec 
--port map (
--	reset 		=> reset,
--	clk 		=> clk_75,
--	tapein 		=> tapein,
--	tapeout 	=> tapeout,

--	out_l 		=> DAC_OUT_L,
--	out_r 		=> DAC_OUT_R
--);

-- logic

reset <= not(KEYS(3)) or not locked;
hypercharge <= '0';

--process (clk_25, reset) 
--variable debctr : integer range 0 to 65535 := 0;
--variable debsamp : std_logic := '0';
--begin
--	if reset = '1' then 
--		debsamp := '0';
--        debctr := 0;
--    elsif rising_edge(clk_25) then

--    	if KEYS(3) = '0' then
--    		debctr := 65535;
--    	elsif debctr > 0 then
--    		debctr := debctr - 1;
--    	end if;

--		if (debctr > 0) then 
--			debsamp := '1';
--		else 
--			debsamp := '0';
--		end if;
        
--        if (debsamp = '0' and debctr > 0) then 
--        	hypercharge <= not(hypercharge);
--    	end if;

--	end if;
--end process;

-- Global SDRAM signals
SDRAM_CKE <= '1'; -- pullup
-- SDRAM_CS_N <= '0'; -- pulldown
SDRAM_CLK <= clk_75;
BUZZER <= '1';

end bk0010_wxeda_arch;