library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.ALL;    

entity button is

  generic (
	msbi_g 		: integer := 15
  );
  port (

  	clk 		: in std_logic;
  	button 		: in std_logic;

  	state 		: buffer std_logic;
  	down 		: buffer std_logic;
  	up 			: buffer std_logic;
  	switch 		: buffer std_logic := '0'
  );

end button;

architecture rtl of button is

-- two flip-flops to sync button signal with the clk clock domain
signal sync0, sync1 : std_logic;

-- 16-bit counter
signal cnt : std_logic_vector(msbi_g downto 0);
signal max : std_logic_vector(msbi_g downto 0);

signal idle : std_logic;
signal cnt_max : std_logic;

begin

-- When the push-button is pushed or released, we increment the counter
-- The counter has to be maxed out before we decide that the push-button state has changed

process (clk)
begin
	if (rising_edge(clk)) then
	 	sync0 <= not button;
 	end if;
end process;

process (clk)
begin
	if (rising_edge(clk)) then
	 	sync1 <= sync0;
	end if;
end process;

idle <= '1' when state=sync1 else '0';
max <= (others => '1');
cnt_max <= '1' when cnt=max else '0';

process (clk, idle, cnt_max)
begin
	if (rising_edge(clk)) then
		if (idle='1') then
			cnt <= (others=>'0');
		else 
			cnt <= cnt + '1';
			if (cnt_max = '1') then
				state <= not state;
			end if;
		end if;

	end if;
end process;

down <= '1' when idle='0' and cnt_max='1' and state='0' else '0';
up <= '1' when idle='0' and cnt_max='1' and state='1' else '0'; 

process (clk, down)
begin
	if (rising_edge(clk)) then
		if (down='1') then
			switch <= not switch;
		end if;
	end if;
end process;
 
end rtl;


