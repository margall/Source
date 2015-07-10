----------------------------------------------------------------------------------
-- Company:  EBS INK-JET
-- Engineer: Tomasz Gronowicz
-- 
-- Create Date:    	07:27:38 12/13/2006 
-- Design Name: 		Printer control logic
-- Module Name:   	IOREG16 - Behavioral 
-- Project Name: 		EBS7100
-- Target Devices:  XC3S200-4PQ208
-- Tool versions:   ISE 8.2.03i	
-- Description: 		16-bit register for storing data
--
-- Dependencies: 		TIMERCTRL, TIMERDODEL, TIMERRYNNA, TIMERSTATUS, SHIFT16BIT
--									CZASKROPLISTER
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

entity IOREG16 is
	 Port ( 
					DATA_IN		 	: in STD_LOGIC_VECTOR(15 downto 0);
					DATA_OUT		: out   STD_LOGIC_VECTOR(15 downto 0);
					CS 					: in    STD_LOGIC;
					RNW					: in    STD_LOGIC;
					RST 				: in    STD_LOGIC
			  );
end IOREG16;

architecture Behavioral of IOREG16 is
signal DATA : std_logic_vector(15 downto 0);
begin

DATA_IN_PROC:process(CS,RST,RNW)
begin
DATA_OUT	<= DATA;	
--	if (RST='0') then
--		DATA <= (others => '0');
--	els
	if (CS='1' and RNW='0') then
		DATA <= DATA_IN;
	end if;
	
end process;

end Behavioral;

