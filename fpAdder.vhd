LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY fpAdder IS
	PORT ( GClock, GReset           : IN    STD_LOGIC;
	       SignA, SignB 		: IN 	STD_LOGIC;
	       MantissaA, MantissaB     : IN    STD_LOGIC_VECTOR(7 downto 0);
	       ExponentA, ExponentB     : IN    STD_LOGIC_VECTOR(6 downto 0);
	       SignOut                  : OUT   STD_LOGIC;
	       MantissaOut              : OUT   STD_LOGIC_VECTOR(7 downto 0);
	       ExponentOut		: OUT	STD_LOGIC_VECTOR(6 downto 0);
	       Overflow			: OUT 	STD_LOGIC);
END fpAdder;

ARCHITECTURE rtl OF fpAdder IS

COMPONENT sevenBitRegister
	PORT (  i_GReset	: IN	STD_LOGIC;
		i_clock 	: IN	STD_LOGIC;
		i_E		: IN	STD_LOGIC_VECTOR(6 downto 0);
		i_load 		: IN	STD_LOGIC;
		o_E		: OUT	STD_LOGIC_VECTOR(6 downto 0));
END COMPONENT;

COMPONENT sevenBitComplementer
	PORT (	i_A		: IN	STD_LOGIC_VECTOR(6 downto 0);
		i_enable	: IN	STD_LOGIC;
		o_q		: OUT	STD_LOGIC_VECTOR(7 downto 0));
END COMPONENT;

COMPONENT eightBitAdder
	PORT ( 		i_x		: IN STD_LOGIC_VECTOR(7 downto 0);
			i_y		: IN STD_LOGIC_VECTOR(7 downto 0);
			i_cin		: IN STD_LOGIC;
			o_sign		: OUT STD_LOGIC;
			o_s		: OUT STD_LOGIC_VECTOR(6 downto 0));
END COMPONENT;

COMPONENT sevenBitDownCounter
	PORT(
		i_resetBar, i_load, i_countD	: IN	STD_LOGIC;
		i_A				: IN 	STD_LOGIC_VECTOR(6 downto 0);
		i_clock				: IN	STD_LOGIC;
		o_zero				: OUT	STD_LOGIC;
		o_q				: OUT	STD_LOGIC_VECTOR(6 downto 0));
END COMPONENT;

COMPONENT sevenBitComparator
	PORT(
		i_Ai, i_Bi			: IN	STD_LOGIC_VECTOR(6 downto 0);
		o_GT, o_LT, o_EQ		: OUT	STD_LOGIC);
END COMPONENT;

COMPONENT sevenBit2x1MUX
	PORT (
		i_sel		: IN	STD_LOGIC;
		i_A		: IN	STD_LOGIC_VECTOR(6 downto 0);
		i_B		: IN	STD_LOGIC_VECTOR(6 downto 0);
		o_q		: OUT	STD_LOGIC_VECTOR(6 downto 0));
END COMPONENT;

COMPONENT srlatch
	PORT(
		i_set, i_reset		: IN	STD_LOGIC;
		o_q, o_qBar		: OUT	STD_LOGIC);
END COMPONENT;

COMPONENT sevenBitUpCounter
	PORT(
		i_resetBar, i_load, i_countU	: IN	STD_LOGIC;
		i_A				: IN 	STD_LOGIC_VECTOR(6 downto 0);
		i_clock				: IN	STD_LOGIC;
		o_q				: OUT	STD_LOGIC_VECTOR(6 downto 0));
END COMPONENT;

COMPONENT nineBitShiftRegister
	PORT ( 
		i_resetBar, i_clock 			: IN 	STD_LOGIC;	 
		i_load, i_clear, i_shift		: IN	STD_LOGIC;
		i_msb					: IN	STD_LOGIC;
		i_A					: IN	STD_LOGIC_VECTOR(7 downto 0);
		o_q					: OUT	STD_LOGIC_VECTOR(8 downto 0));
END COMPONENT;

COMPONENT nineBitAdder
	PORT ( 		
		i_x		: IN STD_LOGIC_VECTOR(8 downto 0);
		i_y		: IN STD_LOGIC_VECTOR(8 downto 0);
		i_cin		: IN STD_LOGIC;
		o_cout		: OUT STD_LOGIC;
		o_s		: OUT STD_LOGIC_VECTOR(8 downto 0));
END COMPONENT;

COMPONENT fpAdderControl
	PORT ( 
		i_GReset, i_GClock			: IN	STD_LOGIC;
		i_sign, i_notLess9, i_zero, i_coutFz	: IN	STD_LOGIC;
		o_load1, o_load2, o_load3, o_load4	: OUT	STD_LOGIC;
		o_load5, o_load7, o_load6, o_cin	: OUT 	STD_LOGIC;
		o_on22, o_on21, o_flag0, o_flag1	: OUT	STD_LOGIC;
		o_clear4, o_clear3, o_shiftR4, o_shiftR3: OUT	STD_LOGIC;
		o_countD6, o_countU7, o_shiftR5, o_done	: OUT	STD_LOGIC);
END COMPONENT;

SIGNAL 		int_sign, int_notLess9, int_zero, int_coutFz		: 	STD_LOGIC;
SIGNAL		int_load1, int_load2, int_load3, int_load4		: 	STD_LOGIC;
SIGNAL		int_load5, int_load7, int_load6, int_cin		:  	STD_LOGIC;
SIGNAL		int_on22, int_on21, int_flag0, int_flag1, int_clear5	: 	STD_LOGIC;
SIGNAL 		int_clear4, int_clear3, int_shiftR4, int_shiftR3	: 	STD_LOGIC;
SIGNAL 		int_countD6, int_countU7, int_shiftR5, int_done		: 	STD_LOGIC;

SIGNAL int_Ex, int_Ey			 :	STD_LOGIC_VECTOR(6 downto 0);
SIGNAL int_xComplement, int_yComplement  :	STD_LOGIC_VECTOR(7 downto 0);
SIGNAL int_Ediff			 :	STD_LOGIC_VECTOR(6 downto 0);
SIGNAL int_EtoComparator		 :	STD_LOGIC_VECTOR(6 downto 0);
SIGNAL int_GT, int_LT, int_EQ		 :	STD_LOGIC;
SIGNAL int_FLAG				 :	STD_LOGIC;
SIGNAL int_Ez				 :	STD_LOGIC_VECTOR(6 downto 0);
SIGNAL int_FxShifted, int_FyShifted	 :	STD_LOGIC_VECTOR(8 downto 0);
SIGNAL int_mantissaSum			 : 	STD_LOGIC_VECTOR(8 downto 0);
SIGNAL int_RFz				 : 	STD_LOGIC_VECTOR(8 downto 0);

BEGIN

controller: fpAdderControl
	PORT MAP (	i_GReset => GReset,
			i_GClock => GClock,
			i_sign => int_sign,
			i_notLess9 => int_notLess9,
			i_zero => int_zero,
			i_coutFz => int_coutFz,
			o_load1 => int_load1,
			o_load2 => int_load2,
			o_load3 => int_load3,
			o_load4 => int_load4,
			o_load5 => int_load5,
			o_load6 => int_load6,
			o_load7 => int_load7,
			o_cin => int_cin,
			o_on22 => int_on22,
			o_on21 => int_on21,
			o_flag0 => int_flag0,
			o_flag1 => int_flag1,
			o_clear3 => int_clear3,
			o_clear4 => int_clear4,
			o_shiftR4 => int_shiftR4,
			o_shiftR3 => int_shiftR3,
			o_countD6 => int_countD6,
			o_countU7 => int_countU7,
			o_shiftR5 => int_shiftR5,
			o_done => int_done);
Ex: sevenBitRegister
	PORT MAP (	i_GReset => GReset,
			i_clock => GClock,
			i_E => ExponentA,
			i_load => int_load1,
			o_E => int_Ex);

Ey: sevenBitRegister
	PORT MAP (	i_GReset => GReset,
			i_clock => GClock,
			i_E => ExponentB,
			i_load => int_load2,
			o_E => int_Ey);

complementerX: sevenBitComplementer
	PORT MAP (	i_A => int_Ex,
			i_enable => int_on21,
			o_q => int_xComplement);

complementerY: sevenBitComplementer
	PORT MAP (	i_A => int_Ey,
			i_enable => int_on22,
			o_q => int_yComplement);

exponentAdder: eightBitAdder
	PORT MAP (	i_x => int_xComplement,
			i_y => int_yComplement,
			i_cin => int_cin,
			o_sign => int_sign,
			o_s => int_Ediff);

exponentCounter: sevenBitDownCounter
	PORT MAP (	i_resetBar => GReset,
			i_load => int_load6,
			i_countD => int_countD6,
			i_A => int_Ediff,
			i_clock => GClock,
			o_zero => int_zero,
			o_q => int_EtoComparator);

exponentComparator: sevenBitComparator
	PORT MAP (	i_Ai => int_EtoComparator,
			i_Bi => "0001000",
			o_GT => int_GT,
			o_LT => int_LT,
			o_EQ => int_EQ);

exponentSRLatch: srlatch
	PORT MAP (	i_set => int_flag1,
			i_reset => int_flag0,
			o_q => int_FLAG);

exponentSelect: sevenBit2x1MUX
	PORT MAP (	i_sel => int_FLAG,
			i_A => int_Ex,
			i_B => int_Ey,
			o_q => int_Ez);

Fx: nineBitShiftRegister
	PORT MAP (	i_resetBar => GReset,
			i_clock => GClock,
			i_load => int_load3,
			i_shift => int_shiftR3,
			i_clear => int_clear3,
			i_msb => '1',
			i_A => MantissaA,
			o_q => int_FxShifted);

Fy: nineBitShiftRegister
	PORT MAP (	i_resetBar => GReset,
			i_clock => GClock,
			i_load => int_load4,
			i_shift => int_shiftR4,
			i_clear => int_clear4,
			i_msb => '1',
			i_A => MantissaB,
			o_q => int_FyShifted);

mantissaAdder: nineBitAdder
	PORT MAP (	i_x => int_FxShifted,
			i_y => int_FyShifted,
			i_cin => '0',
			o_cout => int_coutFz,
			o_s => int_mantissaSum);

normalizeRegister: nineBitShiftRegister
	PORT MAP (	i_resetBar => GReset,
			i_clock => GClock,
			i_load => int_load5,
			i_shift => int_shiftR5,
			i_clear => int_clear5,
			i_msb => int_mantissaSum(8),
			i_A => int_mantissaSum(7 downto 0),
			o_q => int_RFz);

	--Output Drivers
	SignOut <= '0';
	MantissaOut <= int_RFz(7 downto 0);
	ExponentOut <= int_Ez;
	
			
END rtl;
