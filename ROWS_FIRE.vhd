----------------------------------------------------------------------------------
-- Company:			EBS INK-JET SYSTEMS POLAND 
-- Engineer: 		TOMASZ GRONOWICZ
-- 
-- Create Date:	11:29:20 05/07/2007 
-- Design Name: 		Printer control logic
-- Module Name:	Rows_fire - Behavioral 
-- Project Name: 	 EBS7100	
-- Target Devices: XC3S200-4PQ208
-- Tool versions:	ISE 8.2.03i
-- Description:	Module created from ROWS_FIRE schematic
--
-- Dependencies: 
--
-- Revision:
--
-- Revision 1.00
-- 2014-01-10
-- DRUK signal added - for phasing during printing
-- 
-- Revision 0.02
-- Changes for printing with fast speeds.
-- Changes to fit conception with 2 counters in LICZ_KROPLE
-- 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
--library UNISIM;
--use UNISIM.Vcomponents.ALL;

entity ROWS_FIRE is
	Port ( 
				RF_BLOK_RZAD		: in std_logic; 	-- STERDRUK(3)
				RF_EN_OVR			: in std_logic; 	-- CZAS_KROPLI_STER(10)
				RF_KONIEC_BAJTU		: in std_logic; 	-- from LICZ_W_BAJT
				RF_KONIEC_RZADKA	: in std_logic; 	-- from LICZ_KROPLE
				RF_LAD_KROPKI		: in std_logic; 	-- MC_ADDR(KROPKI(b1)) and NOT_MC_CS and NOT_RNW
				RF_MAX_GAZ			: in std_logic; 	-- PORTDRUK(5)
				RF_OVR_CLR			: in std_logic; 	-- CZAS_KROPLI_STER(9)
				RF_PRINT_DROP_CLK 	: in std_logic; 	-- form CO_N_KROPLI
				RF_ROWS_S			: in std_logic; 	-- ENCODER or GENERATOR signal (from SHAFT)
				RF_START_B			: in std_logic; 	-- PORT_DRUK(4)
				
				RF_IRQ_R			: out std_logic; 	-- IRQ6 (together with FOTO signal)
				RF_LAD_L_ILK		: out std_logic; 	-- to LICZ_KROPLE (COR_ADDR_GEN)
				RF_OSTATNI_BIT		: out std_logic;	-- to LICZ_KROPLE (COR_ADDR_GEN)
				RF_N_LOAD_12SFT		: out std_logic; 	-- to PRZESUWAJ KROPLE (COR_ADDR_GEN)
				RF_OVERUN			: out std_logic;	-- TIMERSTATUS(11)
				RF_START1			: out std_logic;	-- ready for Photo - to FOTOC
				RF_DRUK				: out std_logic;	-- printing in progress
				RF_RZADEK_N_WOLNY	: out std_logic		-- for phasing during printing 
			);
end ROWS_FIRE;

architecture Behavioral of ROWS_FIRE is

signal DELAYED_FIRE	: std_logic;
signal IMP_START	: std_logic;
signal OVER	: std_logic;
signal POCZ_LAD_12SFT	: std_logic;
signal RZADEK_BEZ_KONCOWKI : std_logic;
signal RZADEK_N_WOLNY	: std_logic;
signal WOLNY_BEFORE	: std_logic;

signal XLXN_10	: std_logic;
signal XLXN_11	: std_logic;
signal XLXN_14	: std_logic;
signal XLXN_31	: std_logic;
signal XLXN_43	: std_logic;
signal XLXN_48	: std_logic;

signal XLXN_136	: std_logic;
signal XLXN_146	: std_logic;
signal XLXN_148	: std_logic;
signal XLXN_165	: std_logic;
signal IRQ_R_DUMMY	: std_logic;
signal START1_DUMMY	: std_logic;
signal OVERUN_DUMMY	: std_logic;
signal N_LOAD_12SFT_DUMMY	: std_logic;
signal LAD_L_ILK_DUMMY		: std_logic;
signal OSTATNI_BIT_DUMMY 	: std_logic;
signal DRUK	: std_logic;

--Signals and constants for SHIFT_RC_2B---------------------------------------------
signal SFT_IN0	: std_logic;
signal SFT_Q0	: std_logic;
signal SFT_Q1	: std_logic;

begin

-- DRUK
RF_DRUK <= RF_MAX_GAZ or IMP_START or RF_ROWS_S or RZADEK_N_WOLNY;
RF_RZADEK_N_WOLNY <= RZADEK_N_WOLNY;

--SHIFT_RC_2B------------------------------------------------------------------
SFT_RC_2B: process(RF_START_B, RF_PRINT_DROP_CLK)
begin

	if (RF_START_B='0') then
		SFT_Q0 <= '0';
		SFT_Q1 <= '0';
		
	elsif (RF_PRINT_DROP_CLK'event and RF_PRINT_DROP_CLK='1') then
		SFT_Q0 <= SFT_IN0;
		SFT_Q1 <= SFT_Q0;
		
	end if;

end process SFT_RC_2B;

SFT_IN0 <= RF_START_B and RF_ROWS_S;
START1_DUMMY <= SFT_Q0;

RF_IRQ_R <= IRQ_R_DUMMY;
RF_LAD_L_ILK <= LAD_L_ILK_DUMMY;
RF_N_LOAD_12SFT <= N_LOAD_12SFT_DUMMY;
RF_OVERUN <= OVERUN_DUMMY;
RF_START1 <= START1_DUMMY;
RF_OSTATNI_BIT <= OSTATNI_BIT_DUMMY;

XLXN_10 <= not SFT_Q1 and START1_DUMMY;

XLXN_11 <= not RF_MAX_GAZ and XLXN_10;

XLXN_14 <= RF_KONIEC_RZADKA and XLXN_136;

IMP_START <= XLXN_11 or XLXN_14;

OVER <= RZADEK_BEZ_KONCOWKI and IMP_START and RF_EN_OVR;

OVERUN_DUMMY <= XLXN_165 or DELAYED_FIRE;

FDC_I_PROC: process(RF_PRINT_DROP_CLK,RF_OVR_CLR)
begin
	if (RF_OVR_CLR='1') then
		XLXN_165 <= '0';
	elsif (RF_PRINT_DROP_CLK'event and RF_PRINT_DROP_CLK='1') then
		XLXN_165 <= OVERUN_DUMMY;
	end if;
end process FDC_I_PROC;

RZADEK_BEZ_KONCOWKI <= not RF_KONIEC_RZADKA and RZADEK_N_WOLNY;

WOLNY_BEFORE <= RZADEK_BEZ_KONCOWKI nor IMP_START;

FD_I_PROC: process(RF_PRINT_DROP_CLK)
begin
	if (RF_PRINT_DROP_CLK'event and RF_PRINT_DROP_CLK='1') then
		RZADEK_N_WOLNY <= not WOLNY_BEFORE;
	end if;
end process FD_I_PROC;

XLXN_31 <= RF_KONIEC_BAJTU and RZADEK_BEZ_KONCOWKI;

N_LOAD_12SFT_DUMMY <= XLXN_31 nor POCZ_LAD_12SFT;

OSTATNI_BIT_DUMMY <= RF_KONIEC_RZADKA and RZADEK_N_WOLNY;

FDC_II_PROC: process(RF_PRINT_DROP_CLK,XLXN_48)
begin
	if (XLXN_48='1') then
		IRQ_R_DUMMY <= '0';
	elsif (RF_PRINT_DROP_CLK'event and RF_PRINT_DROP_CLK='1') then
		IRQ_R_DUMMY <= XLXN_43;
	end if;
end process FDC_II_PROC;

XLXN_43 <= not N_LOAD_12SFT_DUMMY or IRQ_R_DUMMY;
XLXN_48 <= RF_LAD_KROPKI or RF_BLOK_RZAD;

--LAD_L_ILK_DUMMY <= XLXN_129 and POCZ_LAD_12SFT;
LAD_L_ILK_DUMMY <= POCZ_LAD_12SFT;

POCZ_LAD_12SFT <= not RZADEK_BEZ_KONCOWKI and IMP_START;

XLXN_136 <= DELAYED_FIRE or RF_MAX_GAZ;

XLXN_148 <= XLXN_146 or OVER;
XLXN_146 <= not POCZ_LAD_12SFT and DELAYED_FIRE;

FD_III_PROC: process(RF_PRINT_DROP_CLK)
begin
	if (RF_PRINT_DROP_CLK'event and RF_PRINT_DROP_CLK='1') then
		DELAYED_FIRE <= XLXN_148;
	end if;
end process FD_III_PROC;

end Behavioral;