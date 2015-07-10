----------------------------------------------------------------------------------
-- Company: 		EBS INK-JET SYSTEMS POLAND 
-- Engineer: 		TOMASZ GRONOWICZ 
-- 
-- Create Date:    17:54:54 05/05/2007 
-- Design Name: 	Printer control logic
-- Module Name:   LICZ_W_BAJT - Behavioral 
-- Project Name: 	EBS7100	
-- Target Devices: XC3S200-4PQ208
-- Tool versions:   ISE 8.2.03i	 
-- Description: LW_STERDRUK_2_0 contains how many drops are important in byte
--						Module counts PRINT_DROP_CLK signal and when it reaches this value
--						Signal LW_KONIEC_BAJTU is generated. This signal reloads counter.
--						Counter can be reloaded by LW_L_KROPWRZ signal also
--						Signal N_HOLD holds the counter
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

entity LICZ_W_BAJT is
    Port ( 
						LW_STERDRUK_2_0 		: in  STD_LOGIC_VECTOR (2 downto 0); -- No of important drops in byte
						LW_PRINT_DROP_CLK		: in	STD_LOGIC;	-- PRINT_DROP_CLK
    			
           	LW_L_KROPWRZ 		: in  STD_LOGIC;	-- Reload counter - L_KROPWRZ
           	LW_NHOLD 				: in  STD_LOGIC;	--Hold on counting

           	LW_KONIEC_BAJTU : out  STD_LOGIC	--Output signal
           );
end LICZ_W_BAJT;

architecture Behavioral of LICZ_W_BAJT is

signal LOAD_CNT 					: std_logic := '0';	--Reload counter signal
signal LW_KONIEC_BAJTU_IN	: std_logic := '1';	--Internal signal LW_KONIEC_BAJTU
signal CUR_CNT						: std_logic_vector(2 downto 0) := "111";	--Current counter
signal CUR_CNT_TMP			: std_logic_vector(2 downto 0) := "000";	--Current counter temporary

begin
LICZ_W_BAJT_PROC: process (LW_PRINT_DROP_CLK)
begin

	if (LW_PRINT_DROP_CLK'event and LW_PRINT_DROP_CLK='1') then
	
		if (LW_NHOLD='1') then
	
			CUR_CNT_TMP <= CUR_CNT_TMP-1;

			if (CUR_CNT_TMP=X"00" or LW_L_KROPWRZ='1') then
				LW_KONIEC_BAJTU <= '0';
				--L_KROPWRZ <= '0';
				
				CUR_CNT_TMP<= LW_STERDRUK_2_0;

			elsif (CUR_CNT_TMP=X"01") then
				LW_KONIEC_BAJTU <= '1';
				--L_KROPWRZ <= '1';
			end if;

--			if (CA_L_ILK='1') then	--Reload counter
--				ADDR10_5_TMP <= CA_KROPWRZ;
--				L_KROPWRZ <= '1';
--			end if;
			
		end if;
	end if;
end process LICZ_W_BAJT_PROC;
----Rewrite correction data into counter------------------------------------------------
--WR_KOR_DATA: process (LOAD_CNT,LW_STERDRUK_2_0)
--begin
--
--	if (LOAD_CNT='1') then
--		CUR_CNT <= LW_STERDRUK_2_0;
--
--	end if;
--
--end process WR_KOR_DATA;
--
----Count data and genetate A_EQU_B signal -------------------------------------------
--CNT_DATA: process (LW_PRINT_DROP_CLK, LW_NHOLD)
--begin
--	if (LW_NHOLD='0') then
--		LW_KONIEC_BAJTU_IN <= LW_KONIEC_BAJTU_IN;
--	elsif (LW_PRINT_DROP_CLK'event and LW_PRINT_DROP_CLK='1') then
--		LW_KONIEC_BAJTU_IN <= '0';
--		CUR_CNT_TMP <= CUR_CNT_TMP+1;
--
--		if (CUR_CNT_TMP = CUR_CNT) then
--			LW_KONIEC_BAJTU_IN <= '1';
--			CUR_CNT_TMP <= "000";
--		end if;
--		
--	end if;
--
--end process CNT_DATA;
--
----Load counter signal
--LOAD_CNT <= LW_L_KROPWRZ or LW_KONIEC_BAJTU_IN;
--
---- LW_KONIEC_BAJTU output signal
--LW_KONIEC_BAJTU <= LW_KONIEC_BAJTU_IN;
end Behavioral;

