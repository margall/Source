----------------------------------------------------------------------------------
-- Company: 	EBS INK-JET SYSTEMS POLAND 
-- Engineer: 	TOMASZ GRONOWICZ
-- 
-- Create Date:		12:30:32 01/16/2007 
-- Design Name: 	Printer control logic
-- Module Name:		SHAFT - Behavioral 
-- Project Name:	EBS7100	
-- Target Devices: 	XC3S200-4PQ208
-- Tool versions:	ISE 8.2.03i 
-- Description: 	SHAFT control module
--					Vhdl code translation from original P332 file
--					Modified for better understanding
--					Added DIV_8 instead SUB_CNT's
--
--					Module includes the former SYNCHRO module also - part for choosing
--					between the SHAFT and GEN signals
--					It generates signals ROWS_S for printing
--
-- Dependencies: 
--
-- Revision:
--
-- Rev 0.04
-- 2014-06-04
-- Port SHAFT_B added for including conveyer direction
-- Output port SH_DIR - encoder direction for KROPWRZ[7]
--
-- Rev 0.03 - Some changes in DIV_8 procedure, because for SH_STERSHAFT = 0
-- 		the SHAFT_DIV was divided by 2. The process DIV_PROCESS is an example
--		how the DIV_8 has been repaired 
-- 
-- Rev. 0.02 - Bug with doubled fire signal when using enkoder solved
-- It has been done by using AND3B1 gate from library for SHAFT_DIV signal

-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------

library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use ieee.std_logic_1164.ALL;
--use ieee.numeric_std.ALL;
--library UNISIM;
--use UNISIM.Vcomponents.ALL;

entity SHAFT is
	 port ( 
			SH_ROWS_S		: out std_logic;	--Start printing a row
			SH_DIR			: out std_logic;	-- Encoder direction
			
			--Encoder signals
			SH_CO_POL_TAKT	: in	std_logic; --PORT_STER(6)
					
			SH_START_B		: in	std_logic; --Enable encoder - '1' - enabled - PORTDRUK(4)
			SH_CLR_FIRE		: in	std_logic;	--Clear fire signal
			SH_STERSHAFT	: in	std_logic_vector (7 downto 0);	--STER_SHAFT
			SH_SHAFT_IN		: in	std_logic; --Encoder input
			SH_SHAFT_B		: in	std_logic;	-- Encoder input bis
			
			SH_SHFT_NGEN 	: in	std_logic; 	-- 1 - encoder 0 - generator - PORTDRUK(0)
					
			--Generator signals
			SH_GEN			: in 	std_logic;	-- Internal generator printing

			SH_F_16MHZ		: in	std_logic
			);
end SHAFT;

architecture BEHAVIORAL of SHAFT is

signal CLKA						: std_logic;
signal CLR						: std_logic;
signal LOAD						: std_logic;
signal SHAFT_IN_BUF			: std_logic;
signal SH_IN_and_IN_BUF		: std_logic;
signal SH_BUF_FOR_TAKT		: std_logic;
signal SH_BUF_II				: std_logic;
signal XOR_IN_TAKT			: std_logic;
signal CLKA_BUF				: std_logic;
signal CLKA_BUF_II			: std_logic;
signal LOAD_BUF				: std_logic;

signal SHAFT_DIV	: std_logic;
signal ROWS_S_CLK: std_logic;

-- signal STER_SHAFT_CNT : integer range 0 to 255 := 0;
-- freq CLK_OUT = freq CLK_IN / STER_SHAFT_CNT + 1 when SH_CO_POL_TAKT = 1
-- freq CLK_OUT = freq CLK_IN / STER_SHAFT_CNT when SH_CO_POL_TAKT = 0
component DIV_8
Port (
		PORT_IN	: in	STD_LOGIC_VECTOR (7 downto 0);
		CLK_IN	: in	STD_LOGIC;
		CLK_OUT : out	STD_LOGIC;
		CLR		: in	STD_LOGIC
		);
end component;

--component AND3B1
--port (
--	O : out STD_ULOGIC;
--	I0 : in STD_ULOGIC;
--	I1 : in STD_ULOGIC;
--	I2 : in STD_ULOGIC
--	);
--end component;

begin

--CLEAR all signals --> reset structure
CLR <= not SH_START_B;

-- Generate ROWS_S signal---------------------------------------------------------
ROWS_S_PROC: process(ROWS_S_CLK, SH_CLR_FIRE, SH_START_B)
begin
	if (SH_CLR_FIRE='1' or SH_START_B = '0') then
		SH_ROWS_S <= '0';
	elsif(ROWS_S_CLK'event and ROWS_S_CLK='1') then
		SH_ROWS_S <= '1';
	end if;
end process ROWS_S_PROC;

----Choose between generator and encoder
ROWS_S_CLK <= SHAFT_DIV when SH_SHFT_NGEN='1' else SH_GEN;

-- Shaft divider block
-- Signal SHAFT_DIV is used to generate the ROWS_S signal if SH_SHFT_NGEN = 0
DIV_8_MAP: DIV_8
port map (	 PORT_IN => SH_STERSHAFT,
				 CLK_IN	=> CLKA,
				 CLK_OUT => LOAD,
				 CLR	=> CLR
			);

--DIV_PROCESS: process (CLKA,CLR)
--begin
--	if (CLR='1') then
--		LOAD <= '0';
--	elsif (CLKA'event and CLKA='1') then
--		if (STER_SHAFT_CNT=0) then
--			LOAD<= '1';
--			STER_SHAFT_CNT<= CONV_INTEGER(SH_STERSHAFT);
--		else
--			LOAD <= '0';
--			STER_SHAFT_CNT<= STER_SHAFT_CNT-1;
--		end if;
--	end if;
--end process DIV_PROCESS;		
		 
-- SHIFT_RC_2B - first--------------------------------------------------------------
-- 2 buffor signal after xor
SFT_RC_2B_I_PROC: process(SH_F_16MHZ, CLR)
begin
	if (CLR = '1') then
		CLKA_BUF <= '0';
		CLKA_BUF_II <= '0';
	elsif (SH_F_16MHZ'event and SH_F_16MHZ='1') then
		CLKA_BUF <= CLKA;
		CLKA_BUF_II <= CLKA_BUF;
	end if;
end process SFT_RC_2B_I_PROC;

-- SHIFT_RC_2B - second-----------------------------------------------------------
-- 2 bufor of input_signal_bufor 
SFT_RC_2B_II_PROC: process(SH_F_16MHZ, CLR)
begin
	if (CLR = '1') then
		SH_BUF_II <= '0';
		SH_BUF_FOR_TAKT <= '0';
	elsif (SH_F_16MHZ'event and SH_F_16MHZ='1') then
		SH_BUF_II <= SH_IN_and_IN_BUF;
		SH_BUF_FOR_TAKT <= SH_BUF_II;
	end if;
end process SFT_RC_2B_II_PROC;

-- buffer
FDC_I_PROC: process(SH_F_16MHZ,CLR)
begin
	if (CLR='1') then
		SHAFT_IN_BUF <= '0';
	elsif (SH_F_16MHZ'event and SH_F_16MHZ='1') then
		SHAFT_IN_BUF <= SH_SHAFT_IN;
	end if;
end process FDC_I_PROC;

-- buffer output from DIV_8
FDC_II_PROC: process(SH_F_16MHZ,CLR)
begin
	if (CLR='1') then
		LOAD_BUF <= '0';
	elsif (SH_F_16MHZ'event and SH_F_16MHZ='1') then
		LOAD_BUF<= LOAD;
	end if;
end process FDC_II_PROC;

-- input and buffer_input --> reduction impuls (first clk)								
SH_IN_and_IN_BUF <= SH_SHAFT_IN and SHAFT_IN_BUF;

-- decide on operating mode
XOR_IN_TAKT <= SH_CO_POL_TAKT and SH_BUF_FOR_TAKT;

-- generate impuls to DIV_8
CLKA <= XOR_IN_TAKT xor SH_BUF_II;
	 
SHAFT_DIV <= not CLKA_BUF_II and LOAD_BUF and CLKA_BUF;
-- Solution for SHAFT_DIV below is better
-- It not blows rows twice during work with encoder
--AND3B1_MAP : AND3B1
--port map 
--	(
--		O => SHAFT_DIV,
--		I0 => CLKA_BUF_II,
--		I1 => LOAD_BUF,
--		I2 => CLKA_BUF
--	);

-- Include encoder direction
SHAFT_DIR_PROC: process (SH_SHAFT_IN, SH_SHAFT_B)
begin
	if (SH_SHAFT_B'event and SH_SHAFT_B = '1') then
		SH_DIR <= SH_SHAFT_IN;
	end if;
end process SHAFT_DIR_PROC;

end BEHAVIORAL;


