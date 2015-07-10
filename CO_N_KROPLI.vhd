----------------------------------------------------------------------------------
-- Company: 		EBS INK-JET SYSTEMS POLAND 
-- Engineer: 		TOMASZ GRONOWICZ
-- 
-- Create Date:    07:30:05 05/05/2007 
-- Design Name: 	Printer control logic
-- Module Name:   CO_N_KROPLI - Behavioral 
-- Project Name: 	EBS7100	
-- Target Devices: XC3S200-4PQ208
-- Tool versions:   ISE 8.2.03i	
-- Description: 		In Correction flash (bits 15:12) there is the information how often the
--							drop is printed. Module generates signal A_EQU_B = 1 when the drop
--							must be printed and clock signal with printed drops frequency
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CO_N_KROPLI is
    Port ( 
    			CNK_COR_DATA_12_15 	: in  STD_LOGIC_VECTOR (3 downto 0);
           	CNK_FAZA_OK_CLK 		: in  STD_LOGIC;

           	CNK_PRINT_DROP_CLK 	: out STD_LOGIC;
           	CNK_A_EQU_B 					: out STD_LOGIC
          );
end CO_N_KROPLI;

architecture Behavioral of CO_N_KROPLI is

signal DATA_CNT 		: std_logic_vector(3 downto 0) := "0000"; --Data rewriten from KOR_DATA_12_15 on PRINT_DROP_CLK
signal DATA_CNT_TMP	:	std_logic_vector(3 downto 0) := "0000"; --Counter

signal PRINT_CLK			: std_logic := '0';	--internal print_drop_clk signal
signal A_EQU_B_INT	: std_logic := '1';	--internal A_EQU_B signal

begin

--Rewrite correction data into counter------------------------------------------------
WR_KOR_DATA: process (PRINT_CLK)
begin

	if (PRINT_CLK'event and PRINT_CLK='1') then
		DATA_CNT <= CNK_COR_DATA_12_15; 

	end if;

end process WR_KOR_DATA;

--Count data form 0 until counter will not be reset--------------------------------------
CNT_DATA: process (CNK_FAZA_OK_CLK)
begin
	
	if (CNK_FAZA_OK_CLK'event and CNK_FAZA_OK_CLK='1') then
		if (A_EQU_B_INT='1') then
			DATA_CNT_TMP <= (others => '0');
		--A_EQU_B_INT <= '0';
		else
			DATA_CNT_TMP <= DATA_CNT_TMP+1;
		end if;

--		if (DATA_CNT_TMP = DATA_CNT) then
--			A_EQU_B_INT <= '1';
--			DATA_CNT_TMP <= "0000";
--		end if;
		
	end if;
end process CNT_DATA;

--Generate A_EQU_B signal---------------------------------------------------------
A_EQU_B_INT <= '1' when (DATA_CNT=DATA_CNT_TMP) else '0';
--A_EQU_B_INT<= ( DATA_CNT(0)xnor DATA_CNT_TMP(0)) and
--							( DATA_CNT(1)xnor DATA_CNT_TMP(1)) and
--							( DATA_CNT(2)xnor DATA_CNT_TMP(2)) and
--							( DATA_CNT(3)xnor DATA_CNT_TMP(3));	

-- Set output signals -------------------------------------------------------------
PRINT_CLK <= CNK_FAZA_OK_CLK or (not A_EQU_B_INT);

CNK_PRINT_DROP_CLK<= PRINT_CLK;
CNK_A_EQU_B <= A_EQU_B_INT;

end Behavioral;

