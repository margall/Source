----------------------------------------------------------------------------------
-- Company: 	EBS INK-JET SYSTEMS POLAND 
-- Engineer: 	TOMASZ GRONOWICZ
-- 
-- Create Date:    	12:30:32 01/16/2007 
-- Design Name: 	Printer control logic
-- Module Name:    	DIV_8 - Behavioral 
-- Project Name:	EBS7100	
-- Target Devices: 	XC3S200-4PQ208
-- Tool versions:  	ISE 8.2.03i 
-- Description: 	8-bit divider. Divides input clk by data set on PORT_IN
--
-- Dependencies: 
--
-- Revision:
--
-- Rev 0.02 - Changes in DIV_PROCESS to generate proper CLK_OUT signal
--	when PORT_IN = 0. In that case the CLK_OUT is always 1.
--	The changes has been made because of the SHAFT module in which
--	the SHAFT signal was badly divided by 2 when shaft divider was 0
--
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

entity DIV_8 is
    Port ( 
		PORT_IN : in   STD_LOGIC_VECTOR (7 downto 0);
		CLK_IN  : in   STD_LOGIC;
		CLK_OUT : out  STD_LOGIC;
		CLR		: in 	 STD_LOGIC
		);
end DIV_8;

architecture Behavioral of DIV_8 is

signal DATA: integer range 0 to 255 := 0;
signal CLK_TMP: std_logic;

begin

DIV_PROCESS: process (CLK_IN,PORT_IN)
begin
	if (CLR='1') then
		CLK_TMP<= '0';
	elsif (CLK_IN'event and CLK_IN='1') then

--		if (PORT_IN= "00000000") then
--			CLK_TMP <= not CLK_TMP;
--		else
			if (DATA = 0) then
			   CLK_TMP<= '1';
				DATA<= CONV_INTEGER(PORT_IN);
			else
				CLK_TMP<= '0';
				DATA<= DATA-1;
			end if;
--		end if;
	end if;
		
end process DIV_PROCESS;		
CLK_OUT <= CLK_TMP;

end Behavioral;

