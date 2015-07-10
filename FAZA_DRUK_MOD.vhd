-------------------------------------------------------------------------------
-- Company: EBS INK-JET SYSTEMS POLAND 
-- Engineer: TOMASZ GRONOWICZ
-- 
-- Create Date: 	07:59:57 01/13/2014 
-- Design Name: Printer control logic
-- Module Name: FAZA_DRUK_MOD - Behavioral 
-- Project Name: EBS6500
-- Target Devices: XC3S200-4PQ208
-- Tool versions: ISE 14.2
-- Description: 
-- Module generates FAZA_DRUK signal, which switches between printing and phasing.
-- Used for program with phasing during printing functionallity
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FAZA_DRUK_MOD is
	Port ( 
		FDM_FAZA_DRUK 		: out STD_LOGIC;
		FDM_FAZA_DLY_CLK 	: in STD_LOGIC;
		FDM_DRUK 			: in STD_LOGIC;
		FRM_START_PRINTING	: in STD_LOGIC; -- RZADEK_N_WOLNY z ROWS_FIRE
		FDM_PERMIT 			: in STD_LOGIC;	--TYLKO_TEXT (FAZATST_X(7))
		FDM_KONIEC_RZADKA 	: in STD_LOGIC;
		FDM_ILPO 			: in STD_LOGIC_VECTOR(2 downto 0);	--BlokadaPO
		FDM_DANE_DO_CPU		: in STD_LOGIC;
		FDM_PRINT_DROP_CLK	: in STD_LOGIC;
		FDM_TEST_1			: out STD_LOGIC
		);
end FAZA_DRUK_MOD;

architecture Behavioral of FAZA_DRUK_MOD is

signal sFAZA_DRUK : std_logic;
signal sFAZA_DRUK_IN : std_logic;	-- Delayed KONIEC_RZADKA signal. Input for FAZA_DRUK_PROC

signal sSTART_DELAY : std_logic;	-- Start delay
signal sILPO_CNT : std_logic_vector(2 downto 0) := "111";
--signal sSTART_PR : std_logic;
signal sSTART_i	: std_logic;

begin
--FDM_TEST <= sSTART_DELAY;
--sSTART_PR <= FRM_START_PRINTING;
-------------------------------------------------------------------------------
-- Generate FAZA_DRUK signal
-- 1 - Printing
-- 0 - FAZATST_X(7) or KONIEC_RZADKA + DELAY (ILPo)
FAZA_DRUK_PROC: process(FDM_FAZA_DLY_CLK,FDM_PERMIT)
begin
	if (FDM_PERMIT = '0') then
		sFAZA_DRUK <= '0';
	elsif (FDM_FAZA_DLY_CLK'event and FDM_FAZA_DLY_CLK = '1') then
		sFAZA_DRUK <= FDM_DRUK or sFAZA_DRUK_IN;
	end if;
end process FAZA_DRUK_PROC;
FDM_FAZA_DRUK <= sFAZA_DRUK or FDM_DANE_DO_CPU;

-------------------------------------------------------------------------------
-- Start
-- On rising edge for DROP_CLK and when KONIEC_RZADKA and RZADEK_N_WOLNY
-- generates trigger for counting delay
START_I_PROC: process(FDM_PRINT_DROP_CLK, FRM_START_PRINTING,FDM_KONIEC_RZADKA)
begin
	if (FDM_PRINT_DROP_CLK'event and FDM_PRINT_DROP_CLK = '1') then
		if (FRM_START_PRINTING = '1' and FDM_KONIEC_RZADKA = '1') then
			sSTART_i <= '1';
		else
			sSTART_i <= '0';
		end if;
	end if;
end process;

-------------------------------------------------------------------------------
-- Start counting delay
-- Signal sSTART_i'event
START_DELAY_PROC: process(sSTART_i, sFAZA_DRUK_IN) --sFAZA_DRUK)
begin
--	if (sFAZA_DRUK = '0') then
	if (sFAZA_DRUK_IN = '0') then
		sSTART_DELAY <= '0';
	elsif (sSTART_i'event and sSTART_i = '1') then
		sSTART_DELAY <= '1';
	end if;
		
end process START_DElAY_PROC;

-------------------------------------------------------------------------------
-- Down counter for BLOKADAPO register
DOWNCOUNTER_PROC: process (FDM_PRINT_DROP_CLK, sSTART_DELAY, FDM_PERMIT,
								FDM_DRUK)
begin
	if (FDM_PERMIT = '0') then
		sILPO_CNT <= FDM_ILPO;
		sFAZA_DRUK_IN <= '0';
	elsif (FDM_PRINT_DROP_CLK'event and FDM_PRINT_DROP_CLK='1') then
		if (sSTART_DELAY = '0') then
			sILPO_CNT <= FDM_ILPO;
			sFAZA_DRUK_IN <= FDM_DRUK;
		elsif (sILPO_CNT = "000") then
			sFAZA_DRUK_IN <= '0';
		else
			sILPO_CNT <= sILPO_CNT - 1;
			sFAZA_DRUK_IN <= '1';
		end if;
	end if;
end process DOWNCOUNTER_PROC;
FDM_TEST_1 <= sSTART_DELAY;
end Behavioral;

