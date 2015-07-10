----------------------------------------------------------------------------------
-- Company: EBS INK-JET SYSTEMS POLAND 
-- Engineer: 	TOMASZ GRONOWICZ
-- 
-- Create Date:    06:32:03 05/10/2007 
-- Design Name: 	Printer control logic
-- Module Name:    COR_ADDR_GEN - Behavioral 
-- Project Name: 	EBS7100	
-- Target Devices: XC3S200-4PQ208
-- Tool versions:  	ISE 8.2.03i	
-- Description:  Generation of the correction flash address. It incorporates the function
--						of 3 modules: ADDR11_18KOR, PRZESUWAJ_KROP, LICZ_KROPLE
--
-- Dependencies: 
--
-- Revision:
--
-- Rev. 2.01
-- 2011-12-15
-- NewCORRECTION corrected. The new *.bin file is requried for these option
-- Option NEW_CORECTION added
--
-- Rev 2.00
-- 2011-09-12
-- Added service of different length correction table. (option NewCORRECTION)
--
-- Rev 1.00
-- 2011-05-06
-- Added an 8 bit correction for EBS6500 (EBS6500 option)
--
-- Rev 0.06
-- Added generic variable "drop_kor_width" to set the number of corrected drops.
-- Now to choose 6 or 8 drops for correction it is enough to set drop_kor_width to 6 or 8
--
-- Revision 0.05
-- Correction for 6 drops
--
-- Revision 0.04
-- New conception of LICZ_KROPLE with switching between two counters
-- 
-- Revision 0.03
-- Correction for 7 drops - the whole adresses shifts, so number of
-- corection table decreased
-- 
-- Revision 0.01 - File Created
-- Additional Comments: 
-- This module is going to be used in DROGENERATION module.
-- See: ADDR18_11, ADDR10_5 and ADDR4_0 in this module 
--
-- Correction for 6 drops - max drops in row has been decreased
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity COR_ADDR_GEN is
	Generic (drop_kor_width : integer := 8;
				 EBS6500 : boolean := true;
				 NEW_CORRECTION : boolean := true);
	Port ( 
				COR_ADDR : out  STD_LOGIC_VECTOR (18 downto 0); --Output addres
				--COR_AD_1811 : out std_logic_vector(7 downto 0);		--Temporary address 18 to 11
				--COR_AD_1005	: out std_logic_vector(5 downto 0);		--Temporary address 10 to 5
				--COR_AD_0400	: out std_logic_vector(4 downto 0);		--Temporary address 4 to 0
				
				--For ADDR11_18KOR module - addreses (18 downto 11)
				CA_KOREKCJE : in STD_LOGIC_VECTOR(7 downto 0);	--KOREKCJE register
				CA_DOT 	: in  STD_LOGIC;
				CA_TAB_FAZOWANIA : in  STD_LOGIC;
				CA_A_EQU_B : in  STD_LOGIC;

				-- For LICZ_KROPLE module - addreses (10 downto 5)
				CA_KROPWRZ	: in STD_LOGIC_VECTOR(5 downto 0);	--KROPWRZ register
				CA_SELECT		: in STD_LOGIC;		-- Select register A or B (0- select A, 1- select B)
				CA_L_ILK		: in STD_LOGIC;		-- Load register
				
				CA_L_KROPWRZ	: out STD_LOGIC;
				CA_KONIECRZADKA	: out STD_LOGIC;

				-- For PRZESUWAJ_KROP module - addresses(4 downto 0)
				CA_KROPKI	: in STD_LOGIC_VECTOR(7 downto 0);	--KROPKI register
				CA_NLOAD		: in STD_LOGIC;		--Not shift -Load shifter - active '0' (N_LOAD_12SFT)
				
				CA_PRINT_DROP_CLK : in STD_LOGIC	-- Common input clock
			);
end COR_ADDR_GEN;

architecture Behavioral of COR_ADDR_GEN is

--ADDR11_18_KOR signals and constants ---------------------------------------------
--Zero table address
constant ZEROTAB_ADDR : std_logic_vector(7 downto 0) := X"1F";

signal ADDR18_11 		: std_logic_vector (7 downto 0);
signal ADDR18_11_TMP 	: std_logic_vector (7 downto 0) := X"00";

-- LICZ_KROPLE signals and constants -----------------------------------------------
signal ADDR10_5			: std_logic_vector(5 downto 0);
--signal ADDR10_5_TMP 	: std_logic_vector(5 downto 0) := "000000";
--signal ADDR10_5_CNT	: std_logic_vector(5 downto 0) := "000000";
signal ADDR10_5_CNTA	: std_logic_vector(5 downto 0) := "000000";
signal ADDR10_5_CNTB	: std_logic_vector(5 downto 0) := "000000";
signal L_KROPWRZ		: std_logic := '0';
signal KONIECRZ			: std_logic := '0';

-- PRZESUWAJ_KROP signals and constants -------------------------------------------
-- 5 drops
--signal ADDR4_0		: std_logic_vector(4 downto 0);
--signal ADDR4_0_TMP	: std_logic_vector(11 downto 0) := "000000000000";
-- 6 drops
--signal ADDR4_0		: std_logic_vector(5 downto 0);
--signal ADDR4_0_TMP	: std_logic_vector(12 downto 0) := "0000000000000";
-- 7 drops
--signal ADDR4_0		: std_logic_vector(6 downto 0);
--signal ADDR4_0_TMP	: std_logic_vector(13 downto 0) := "00000000000000";
-- 8 drops
--signal ADDR4_0		: std_logic_vector(7 downto 0);
--signal ADDR4_0_TMP	: std_logic_vector(14 downto 0) := "000000000000000";

signal ADDR4_0			: std_logic_vector(drop_kor_width-1 downto 0);
signal ADDR4_0_TMP		: std_logic_vector(drop_kor_width+6 downto 0) := (others => '0');

begin

--Generate adresses from 18 to 11 ---------------------------------------------------
-- KOREKCJE register is used to generate the correction table address
-- DOT = 0 - the addres indicates on ZERA correction table (0x1F)
-- TAB_FAZOWANIA or A_EQU_B = 0 the bit1 is always cleared
-- In other cases the KOREKCJE - addresses (18:11) in correction flash
GEN18_11_TMP_PROC: process (CA_KOREKCJE,CA_DOT)
begin

	if (CA_DOT='0') then
		ADDR18_11_TMP <= ZEROTAB_ADDR;
	else
		ADDR18_11_TMP <= '0' & CA_KOREKCJE(6 downto 0);
	end if;
end process GEN18_11_TMP_PROC;

GEN_18_11_PROC: process (ADDR18_11_TMP,CA_TAB_FAZOWANIA,CA_A_EQU_B)
begin
	if (CA_TAB_FAZOWANIA='0' and CA_A_EQU_B='0') then
		ADDR18_11<= ADDR18_11_TMP(7 downto 2) &  '0' & ADDR18_11_TMP(0);
	else
		ADDR18_11<= ADDR18_11_TMP;
	end if;
end process GEN_18_11_PROC;

-- Generate addresses from 10 to 5 --------------------------------------------------
-- KROPWRZ register is used to generate the address - it indicates the no of drops in row
-- The addres is continously changed from KROPWRZ to 0
-- When it reaches 0 the signal KONIECRZADKA and LOAD_KROPKIWRZ is generated
-- New conception is that address depends on the ends drops and it is generated
-- from A or B register depending on SELECT signal (0- select A, 1- select B)

--A down counter---------------------------------------------------------------
GEN10_5_A_PROC: process (CA_PRINT_DROP_CLK)
begin

	if (CA_PRINT_DROP_CLK'event and CA_PRINT_DROP_CLK='1') then
	
		if (KONIECRZ='1') then
			ADDR10_5_CNTA <= CA_KROPWRZ;
		else
			ADDR10_5_CNTA <= ADDR10_5_CNTA-1;
		end if;
	end if;
end process GEN10_5_A_PROC;

--B Down counter --------------------------------------------------------------
GEN10_5_B_PROC: process (CA_PRINT_DROP_CLK)
begin

	if (CA_PRINT_DROP_CLK'event and CA_PRINT_DROP_CLK='1') then
	
		if (L_KROPWRZ = '1') then
			ADDR10_5_CNTB<= CA_KROPWRZ;
		else
			ADDR10_5_CNTB <= ADDR10_5_CNTB-1;
		end if;
	end if;
	
end process GEN10_5_B_PROC;
KONIECRZ <= '1' when ADDR10_5_CNTB=X"00" else '0';
L_KROPWRZ <= KONIECRZ or CA_L_ILK;

--Set outputs
ADDR10_5 <= ADDR10_5_CNTA when CA_SELECT='0' else ADDR10_5_CNTB;
CA_L_KROPWRZ <= L_KROPWRZ;
CA_KONIECRZADKA <= KONIECRZ;

-- Generate addresses from 4 to 0 ---------------------------------------------------
-- KROPKI register is used to generate addresses - there are addesses for current printed drops
-- The addresses are generated by Paralel In, Paralel Out shifter. Input of the shifter is
-- the KROPKI register, output - the 7 bit long address. In this address the 3rd line is the current
-- printed drop.
GEN4_0_PROC: process (CA_PRINT_DROP_CLK)
begin

	if (CA_PRINT_DROP_CLK'event and CA_PRINT_DROP_CLK='1') then
		-- 5 drops
		--ADDR4_0_TMP <= ADDR4_0_TMP(10 downto 0) & '0';
		--6 drops
		--ADDR4_0_TMP <= ADDR4_0_TMP(11 downto 0) & '0';
		-- 7 drops
		--ADDR4_0_TMP <= ADDR4_0_TMP(12 downto 0) & '0';
		-- 8 drops
		--ADDR4_0_TMP <= ADDR4_0_TMP(13 downto 0) & '0';
		ADDR4_0_TMP <= ADDR4_0_TMP(drop_kor_width-1+6 downto 0) & '0';
		if (CA_NLOAD='0') then
			ADDR4_0_TMP(7 downto 0) <= CA_KROPKI;
		end if;
	end if;
	
end process GEN4_0_PROC;
--5 drops
--ADDR4_0 <= ADDR4_0_TMP(11 downto 7);
-- 6 drops
--ADDR4_0 <= ADDR4_0_TMP(12 downto 7);
--7 Drops
--ADDR4_0 <= ADDR4_0_TMP(13 downto 7);
--8 Drops
--ADDR4_0 <= ADDR4_0_TMP(14 downto 7);
ADDR4_0 <= ADDR4_0_TMP(drop_kor_width+6 downto 7);

-- Set Correction flash output-------------------------------------------------------
-- 5 drops
KOR_DROPS_5: if (drop_kor_width = 5) generate
	COR_ADDR <= ADDR18_11 & ADDR10_5 & ADDR4_0;
end generate;
--6 drops
KOR_DROPS_6: if (drop_kor_width = 6) generate
	COR_ADDR <= ADDR18_11 & ADDR10_5(4 downto 0) & ADDR4_0;
end generate;
--7 drops
KOR_DROPS_7: if (drop_kor_width = 7) generate
	COR_ADDR <= ADDR18_11(5 downto 0) & ADDR10_5 & ADDR4_0;
end generate;
--8 drops
KOR_DROPS_8: if (drop_kor_width = 8 and EBS6500 = false) generate
	COR_ADDR <= ADDR18_11(4 downto 0) & ADDR10_5 & ADDR4_0;
end generate;

-- 8 drops for EBS6500
KOR_DROPS_8_6500: if (drop_kor_width = 8 and EBS6500 = true) generate
	
KOR_NEW_CORRECTION:	if (NEW_CORRECTION = true) generate
	COR_ADDR <= (ADDR18_11(6 downto 0) & ADDR10_5(3 downto 0) & ADDR4_0)
					when (CA_KOREKCJE(7) = '0') else
						(ADDR18_11(6 downto 1) & ADDR10_5(4 downto 0) & ADDR4_0);
	end generate;
	
KOR_OLD_CORRECTION: if (NEW_CORRECTION = false) generate
	 	COR_ADDR <= (ADDR18_11(5 downto 0) & ADDR10_5(4 downto 0) & ADDR4_0);
	end generate;

end generate;

--COR_AD_1811 <= ADDR18_11;
--COR_AD_1005 <= ADDR10_5;
--COR_AD_0400 <= ADDR4_0;

end Behavioral;

