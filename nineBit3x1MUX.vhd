LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY nineBit3x1MUX IS
	PORT (
		i_sel		: IN	STD_LOGIC_VECTOR(2 downto 0);
		i_A		: IN	STD_LOGIC_VECTOR(8 downto 0);
		i_B		: IN	STD_LOGIC_VECTOR(8 downto 0);
		i_C		: IN	STD_LOGIC_VECTOR(8 downto 0);
		o_q		: OUT	STD_LOGIC_VECTOR(8 downto 0));
END nineBit3x1MUX;

ARCHITECTURE struct OF nineBit3x1MUX IS
	
BEGIN

WITH i_sel SELECT
	o_q <= i_A when "100",
	       i_B when "010",
	       i_C when "001",
	       "000000000" when others;
END struct; 
