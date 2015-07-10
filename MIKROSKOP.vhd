----------------------------------------------------------------------------------
-- Company:			EBS INK-JET SYSTEMS POLAND
-- Engineer: 		TOMASZ GRONOWICZ
--
-- Create Date:	11:29:20 09/07/2007
-- Design Name: 		Printer control logic
-- Module Name:	MIKROSKOP - Behavioral
-- Project Name: 	 EBS7100	
-- Target Devices: XC3S200-4PQ208
-- Tool versions:	ISE 8.2.03i
-- Description:	Module created from MIKROSKOP schematic
--						Parts for 2-heads printer has been reduced
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use IEEE.std_logic_arith.all;
--library UNISIM;
--use UNISIM.Vcomponents.ALL;

entity MIKROSKOP is
	 Port (
	 			MI_DROP_FREQ			: in std_logic;
				MI_FAZA_OK				: in std_logic;
				MI_F_2MHZ			 		: in std_logic;
				MI_F_16MHZ				: in std_logic;
				MI_LD_KROPKIWRZ 	: in std_logic;
				
				MI_ROWS						: in std_logic; --ROWS not DROPS - PORTSTER(5)
				
				MI_DELAY					: in std_logic;  --Delay rows - TIMERCTRL(4)
				MI_IN_DELAY				: in std_logic;	--Increase delay - TIMERCTRL(3)
				MI_STRBSKP_OUT		: out	 std_logic
			);
end MIKROSKOP;

architecture BEHAVIORAL of MIKROSKOP is

signal N_STROBOSKOP		: std_logic;

signal QBW				: std_logic_vector (7 downto 0);	--Mux input
signal MUX_8_OUT	: std_logic;		--Mux output
signal MUX_8_SEL 	: std_logic_vector(2 downto 0) := "000";		--Mux selector
signal MUX_8_Int	: integer range 0 to 7 := 0;


signal XLXN_38					: std_logic;
signal XLXN_40					: std_logic;
signal XLXN_43					: std_logic;

signal XLXN_54					: std_logic;
signal XLXN_69					: std_logic;
signal XLXN_74					: std_logic;
signal XLXN_76					: std_logic;
signal XLXN_78					: std_logic;

signal SFT_R3B_i				: std_logic;
signal SFT_R3B_ii				: std_logic;
signal SFT_R3B_iii			: std_logic;
signal STRBSKP_OUT_DUMMY 	: std_logic;

begin

MI_STRBSKP_OUT <= STRBSKP_OUT_DUMMY;

--Choose between DROPS and ROWS------------------------------------------------
N_STROBOSKOP <= MI_LD_KROPKIWRZ when MI_ROWS='1' else MI_DROP_FREQ;

--Choose between own rows and STROB_DELAY
XLXN_38 <= MUX_8_OUT when MI_DELAY = '1' else N_STROBOSKOP;

--------------------------------------------------
SFT_R_3B_I_PROC: process(MI_F_2MHZ)
begin
	if (MI_F_2MHZ'event and MI_F_2MHZ='1') then
		SFT_R3B_i <= XLXN_38;
		XLXN_43 <= SFT_R3B_i;
		XLXN_40 <= XLXN_43;
	end if;

end process;

--Stroboscop output--------------------------------------------------------------
STRBSKP_OUT_DUMMY <= not XLXN_40 and  XLXN_43 and MI_F_2MHZ;

--STROB_DELAY mulitiplexer--------------------------------------------------------	
--MUX_8_SEL <= XLXN_74 & XLXN_76 & XLXN_78;
MUX_ST_DEL_PROC: process(MUX_8_SEL,QBW)
begin
	case (MUX_8_SEL) is
		when "000" => MUX_8_OUT <= QBW(0);
		when "001" => MUX_8_OUT <= QBW(1);
		when "010" => MUX_8_OUT <= QBW(2);
		when "011" => MUX_8_OUT <= QBW(3);
		when "100" => MUX_8_OUT <= QBW(4);
		when "101" => MUX_8_OUT <= QBW(5);
		when "110" => MUX_8_OUT <= QBW(6);
		when "111" => MUX_8_OUT <= QBW(7);
		when others => MUX_8_OUT <= QBW(0);
	end case;

end process;

----------------------------------------
SFT_R_8B_PROC: process(XLXN_54)
begin
	if (XLXN_54'event and XLXN_54='1') then
		QBW(0) <= N_STROBOSKOP;
		QBW(1) <= QBW(0);
		QBW(2) <= QBW(1);
		QBW(3) <= QBW(2);
		QBW(4) <= QBW(3);
		QBW(5) <= QBW(4);
		QBW(6) <= QBW(5);
		QBW(7) <= QBW(6);
	end if;

end process;

--------------------------------------------------
SFT_R_3B_II_PROC: process(MI_F_16MHZ)
begin
	if (MI_F_16MHZ'event and MI_F_16MHZ='1') then
		SFT_R3B_ii <= XLXN_69 xor MI_FAZA_OK;
		SFT_R3B_iii <= SFT_R3B_ii;
		XLXN_54 <= SFT_R3B_iii;
	end if;

end process;

--------------------------------------------------
FD_1_I_PROC: process(MI_IN_DELAY)
begin
	if (MI_IN_DELAY'event and MI_IN_DELAY='0') then
		XLXN_69 <= not XLXN_69;
	end if;

end process;

--MUX_8_SEL - mux selector (counts from 0 to 7)
MUX_8_SEL_PROC: process(XLXN_69)
begin
	if (XLXN_69'event and XLXN_69='0') then
		MUX_8_Int <= MUX_8_Int + 1;
	end if;
end process MUX_8_SEL_PROC;
MUX_8_SEL <= CONV_STD_LOGIC_VECTOR(MUX_8_Int, 3);

end BEHAVIORAL;

