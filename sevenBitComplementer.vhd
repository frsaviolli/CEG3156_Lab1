LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY sevenBitComplementer IS
	PORT (	i_A		: IN	STD_LOGIC_VECTOR(6 downto 0);
		i_enable	: IN	STD_LOGIC;
		o_q		: OUT	STD_LOGIC_VECTOR(7 downto 0));
END sevenBitComplementer;

ARCHITECTURE rtl OF sevenBitComplementer IS

COMPONENT eightBit2x1MUX 
	PORT (
		i_sel		: IN	STD_LOGIC;
		i_A		: IN	STD_LOGIC_VECTOR(7 downto 0);
		i_B		: IN	STD_LOGIC_VECTOR(7 downto 0);
		o_q		: OUT	STD_LOGIC_VECTOR(7 downto 0));
END COMPONENT;

SIGNAL int_complement, int_noComplement, int_q : STD_LOGIC_VECTOR(7 downto 0);

BEGIN

int_complement <= '1' & NOT(i_A(6)) & NOT(i_A(5)) & NOT(i_A(4)) & NOT(i_A(3)) & NOT(i_A(2)) & NOT(i_A(1)) & NOT(i_A(0));
int_noComplement <= '0' & i_A(6) & i_A(5) & i_A(4) & i_A(3) & i_A(2) & i_A(1) & i_A(0);

mux: eightBit2x1MUX
	PORT MAP ( i_sel => i_enable,
		   i_A => int_noComplement,
		   i_B => int_complement,
		   o_q => int_q);

	--Output drivers
	o_q <= int_q;

END rtl;