----------------------------------------------------------------------------------
-- Company: 	EBS INK-JET SYSTEMS POLAND 
-- Engineer: 	TOMASZ GRONOWICZ
-- 
-- Create Date:		12:30:32 01/16/2007 
-- Design Name: 	Printer control logic
-- Module Name:	SHAFT - Behavioral 
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
-- Rev 0.05
-- 2015-06-10
-- Simplification of whole structure
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

entity SHAFT is
	 port ( 
			SH_ROWS_S		: out std_logic;		-- Start printing a row
			SH_DIR			: out std_logic;		-- Encoder direction
			
			--Encoder signals
			SH_CO_POL_TAKT	: in	std_logic; 		--PORT_STER(6)	
			SH_START_B		: in	std_logic; 		--Enable encoder - '1' - enabled - PORTDRUK(4)
			SH_CLR_FIRE		: in	std_logic;		--Clear fire signal
			SH_SHAFT_IN		: in	std_logic; 		--Encoder input
			SH_SHAFT_B		: in	std_logic;		-- Encoder input bis
			SH_STERSHAFT	: in	std_logic_vector (7 downto 0);		--STER_SHAFT
			SH_SHFT_NGEN 	: in	std_logic; 		-- 1 - encoder 0 - generator - PORTDRUK(0)
					
			--Generator signals
			SH_GEN			: in 	std_logic;		-- Internal generator printing
			SH_F_16MHZ		: in	std_logic;
			
			-- Frequency multiplier settings signal
			SH_FREQ_MUL		: in  std_logic_vector (7 downto 0);
			
			N_RESET			: in  std_logic
			);
end SHAFT;

architecture BEHAVIORAL of SHAFT is

signal CLKA						: std_logic;	-- SHAFT_IN or edges of SHAFT_IN (depends on SH_CO_POL_TAKT)
signal CLR						: std_logic;	-- reset structure
signal LOAD						: std_logic;	-- output from DIV_8
signal SHAFT_IN_PRE_BUF		: std_logic;	-- initial buffer of input signal
signal SHAFT_IN_MULT_FREQ	: std_logic;	-- initial buffer of input signal
signal SHAFT_IN_BUF			: std_logic;	-- buffer used to detecting edges
signal CLKA_BUF				: std_logic;	-- buffer used to make impuls of SHAFT_DIV
signal SHAFT_DIV				: std_logic;	-- output from shaft edges detecting
signal ROWS_S_CLK				: std_logic;	-- output SHAFT_DIV or SH_GEN (depends on SH_SHFT_NGEN)

-- signal STER_SHAFT_CNT : integer range 0 to 255 := 0;
-- freq CLK_OUT = freq CLK_IN / STER_SHAFT_CNT + 1 when SH_CO_POL_TAKT = 1
-- freq CLK_OUT = freq CLK_IN / STER_SHAFT_CNT - 1 when SH_CO_POL_TAKT = 0
										
component DIV_8
Port (
		PORT_IN	: in	STD_LOGIC_VECTOR (7 downto 0);
		CLK_IN	: in	STD_LOGIC;
		CLK_OUT : out	STD_LOGIC;
		CLR		: in	STD_LOGIC
		);
end component;

component SH_FREQ_MULTIPLIER is
    Port ( 
			  SH_IN			: in STD_LOGIC;	-- SHAFT ENCODER INPUT
			  SH_16MHz_CLK : in STD_LOGIC;	-- GLOBAL CLOCK
			  SH_FREQ_MUL 	: in STD_LOGIC_VECTOR(7 downto 0);	-- STATUS REGISTER
			  N_RESET			: in STD_LOGIC;	-- RESET
           FREQ_OUT 		: out STD_LOGIC	-- OUTPUT
			  );
end component;

begin

-- Shaft divider block
-- Signal SHAFT_DIV is used to generate the ROWS_S signal if SH_SHFT_NGEN = 0
DIV_8_MAP: DIV_8
port map (	 PORT_IN => SH_STERSHAFT,
				 CLK_IN	=> CLKA,
				 CLK_OUT => LOAD,
				 CLR	=> CLR
			);
			
SH_FREQ_MULT_MAP : SH_FREQ_MULTIPLIER
port map (	SH_IN => SHAFT_IN_PRE_BUF,
				SH_16MHz_CLK => SH_F_16MHZ,
				SH_FREQ_MUL => SH_FREQ_MUL,
				N_RESET => N_RESET,
				FREQ_OUT => SHAFT_IN_MULT_FREQ
			);

-- CLEAR all signals --> reset structure
CLR <= not SH_START_B;

-- buffers
buffers: process(SH_F_16MHZ, CLR)
begin
	if (CLR = '1') then
		SHAFT_IN_PRE_BUF <= '0';
		SHAFT_IN_BUF <= '0';
		CLKA_BUF <= '0';
	elsif (SH_F_16MHZ'event and SH_F_16MHZ='1') then
		SHAFT_IN_PRE_BUF <= SH_SHAFT_IN;
		SHAFT_IN_BUF <= SHAFT_IN_MULT_FREQ;
		CLKA_BUF <= CLKA;
	end if;
end process buffers;

-- operating mode (one edge, both edges)
CLKA <= SHAFT_IN_MULT_FREQ when SH_CO_POL_TAKT = '0' else (SHAFT_IN_BUF xor SHAFT_IN_MULT_FREQ);

-- generate impuls when CLKA = 1 and LOAD(out of DIV_8) = 1, only one clk --> CLKA_BUF buffers CLKA   	 
SHAFT_DIV <= (not CLKA_BUF) and LOAD and CLKA;

-- choose between generator and encoder
ROWS_S_CLK <= SHAFT_DIV when SH_SHFT_NGEN = '1' else SH_GEN;

-- Generate ROWS_S signal---------------------------------------------------------
ROWS_S_PROC: process(ROWS_S_CLK, SH_CLR_FIRE, SH_START_B)
begin
	if (SH_CLR_FIRE='1' or SH_START_B = '0') then
		SH_ROWS_S <= '0';
	elsif (ROWS_S_CLK'event and ROWS_S_CLK='1') then
		SH_ROWS_S <= '1';
	end if;
end process ROWS_S_PROC;

-- Include encoder direction
SHAFT_DIR_PROC: process (SH_SHAFT_IN, SH_SHAFT_B)
begin
	if (SH_SHAFT_B'event and SH_SHAFT_B = '1') then
		SH_DIR <= SH_SHAFT_IN;
	end if;
end process SHAFT_DIR_PROC;

end BEHAVIORAL;


