----------------------------------------------------------------------------------
-- Company: 	EBS INK-JET SYSTEMS POLAND 
-- Engineer: 	TOMASZ GRONOWICZ
-- 
-- Create Date:    09:03:19 01/29/2007 
-- Design Name: 	 Printer control logic
-- Module Name:    Synt1MHz - Behavioral 
-- Project Name: 	 EBS7100	
-- Target Devices: XC3S200-4PQ208
-- Tool versions:  ISE 8.2.03i 
-- Description: 	Generate 1MHz clock signal
--						and phase duration times: 32u, 64u, 128u,512u,... (CZAS_FAZOWANIA)
--						The phase duration time is used for TAB_FAZOWANIA and DOT generation -
--						it replaces old CZAS_FAZOWANIA module. It uses KOREKCJE register
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
--
-- Additional Comments: 
-- The most important think is 1us time period even if the clock signal is not symetrical
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Synt1MHz is
    Port ( 
    			--Inputs for generation 1MHz clock
				S1M_F_16MHz : in  STD_LOGIC; 		-- 16Mhz or 25 Mhz input clock
				S1M_CLR 	: in   STD_LOGIC;	-- Clear phase counter - TIMERCTRL(12)
				S1M_CTRL	: in   STD_LOGIC;	-- Switch between 16MHz(0) and 25MHz(1) clock - TIMERCTRL(8)
				
				S1M_F_1MHz 	: out  STD_LOGIC;	-- Output 1MHz clock
				S1M_F_2MHz 	: out  STD_LOGIC;	-- Output 2MHz clock - for stroboscope
				--FAZA_TIME for test purposes only
				--FAZA_TIME	: out  STD_LOGIC_VECTOR (7 downto 0);	-- Phase duration time: 
																											-- b0-32us, b1-64us, b2-128us, b3-256us b4 - 512us,...

				--Inputs for DOT and TAB_FAZOWANIA
				S1M_KOREKCJE	: in STD_LOGIC_VECTOR(7 downto 0);
				S1M_A_EQU_B		: in STD_LOGIC;

				S1M_FAZA_OK_CLK		: in STD_LOGIC;
				S1M_NEG_PHASE		: in STD_LOGIC;		-- STERDRUK(5)
				
				S1M_FAZA_NO		: in STD_LOGIC_VECTOR(1 downto 0); --Phase time choose for phasing (TIMERCTRL(1:0))
				S1M_FAZA_START	: in STD_LOGIC; --Begin of phase time (TIMERCTRL(12) - active low

				S1M_TAB_FAZOWANIA	: out STD_LOGIC;
				S1M_DOT				: out STD_LOGIC
																											
					);
end Synt1MHz;

architecture Behavioral of Synt1MHz is

--Signals and constans for generation 1MHz wave---------------------------------------
signal S1M_F_1MHz_TMP : std_logic := '0';
signal S1M_F_2MHz_TMP : std_logic := '0';
signal CLK_DIV : std_logic_vector(4 downto 0) := "00000";

--Signals and constants for generation phase duration time-------------------------------
signal GEN_CNT : integer range 0 to 25 :=0;
signal FAZA	: std_logic_vector(7 downto 0) :="00000000";

--Signals and constants for generation S1M_DOT and S1M_TAB_FAZOWANIA-------------------------
signal FAZA_ST	: std_logic := '0';	-- Phase start/stop signal
signal CUR_PH	: std_logic;	--Current phase - choosen from FAZA signal by S1M_FAZA_NO
signal FAZA_S	: std_logic;
signal FAZA_ST_END : std_logic;	--Final phase start/stop signal
signal TAB_FAZ_TMP : std_logic;
begin

-- Generate 1MHz wave------------------------------------------------------------
GEN_1MHZ: process (S1M_F_16MHz,S1M_CTRL)
begin
	if (S1M_F_16MHz'event and S1M_F_16MHz='1') then
	 CLK_DIV <= CLK_DIV+1;
	 
		if (S1M_CTRL='1') then -- and CLK_DIV=12) then
			--25MHz clock
			S1M_F_1MHz_TMP <= CLK_DIV(4);-- and CLK_DIV(3); --not S1M_F_1MHz_TMP;
			S1M_F_2MHz_TMP <= CLK_DIV(3);
			if (CLK_DIV(4)='1' and CLK_DIV(3)='1') then
				CLK_DIV<= (others => '0');
			end if;
		elsif (S1M_CTRL='0') then -- and CLK_DIV =7) then
			--16MHz clock
			S1M_F_1MHz_TMP <= CLK_DIV(3); --not S1M_F_1MHz_TMP;
			S1M_F_2MHz_TMP <= CLK_DIV(2); -- for stroboscope
			--CLK_DIV <= 0;
		end if;
	
	end if;
end process GEN_1MHZ;
S1M_F_1MHz <= S1M_F_1MHz_TMP;
--S1M_F_2MHz <= S1M_F_2MHz_TMP;
S1M_F_2MHz <= S1M_F_1MHz_TMP;
-- Generate the phase duration time-------------------------------------------------
GEN_PH_DUR: process(S1M_F_1MHz_TMP, S1M_CLR)
begin
	
	if (S1M_F_1MHz_TMP'event and S1M_F_1MHz_TMP='1') then
	
		if (S1M_CLR='1') then
			FAZA <= (others =>'0');
			GEN_CNT <= 0;
		
		elsif (GEN_CNT=15) then
				FAZA <= FAZA+1;
				GEN_CNT <= 0;
		else
			GEN_CNT <= GEN_CNT+1;
		end if;
		
	end if;

end process GEN_PH_DUR;
--FAZA_TIME <= FAZA;

-- Generate start and stop of phase time ----------------------------------------------
--Choose required end of phase time
-- Only bits 1,2,3,5 from FAZA are used
MUX_PROC: process(FAZA,S1M_FAZA_NO)
begin

	case (S1M_FAZA_NO) is
		when "00" => CUR_PH <= FAZA(1);
		when "01" => CUR_PH <= FAZA(2);
		when "10" => CUR_PH <= FAZA(3);
		when "11" => CUR_PH <= FAZA(5);
		when others => CUR_PH<='1';
	end case;

end process MUX_PROC;

--Generate start/stop signal
-- Start is initiated by low clock of S1M_FAZA_START
-- Stop is initiated by high level of CUR_PH
GEN_ST_PROC: process(S1M_FAZA_START, CUR_PH)
begin
	if (CUR_PH='1') then
		FAZA_ST <= '0';
	elsif (S1M_FAZA_START'event and S1M_FAZA_START='0') then
		FAZA_ST<= '1';
	end if;

end process GEN_ST_PROC;

--Synchronize FAZA_ST with FAZA clock
SYN_PH_PROC: process(S1M_FAZA_OK_CLK)
begin
	if (S1M_FAZA_OK_CLK'event and S1M_FAZA_OK_CLK='1') then
		FAZA_S<= FAZA_ST;
	end if;
end process SYN_PH_PROC;

--Choose phase start/stop signal polarity
--Generate final phase start/stop signal
MUX_PH_PROC: process (FAZA_S, S1M_FAZA_OK_CLK,S1M_NEG_PHASE)
begin
	if (S1M_NEG_PHASE='1') then
		FAZA_ST_END <=  not( FAZA_S and not S1M_FAZA_OK_CLK);
	else
		FAZA_ST_END <= FAZA_S and not S1M_FAZA_OK_CLK;
	end if;

end process MUX_PH_PROC;

TAB_FAZ_TMP <= 	not S1M_KOREKCJE(0) and S1M_KOREKCJE(1)
									and S1M_KOREKCJE(2) and S1M_KOREKCJE(3)
									and S1M_KOREKCJE(4) and not S1M_KOREKCJE(5)
									and not S1M_KOREKCJE(6) and not S1M_KOREKCJE(7);


--Set outputs
S1M_DOT <= (not TAB_FAZ_TMP and S1M_A_EQU_B) or (TAB_FAZ_TMP and FAZA_ST_END);
S1M_TAB_FAZOWANIA <= TAB_FAZ_TMP;

end Behavioral;

