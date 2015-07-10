----------------------------------------------------------------------------------
-- Company:  EBS INK-JET
-- Engineer: Tomasz Gronowicz
-- 
-- Create Date:    07:14:39 12/13/2006 
-- Design Name: 	 Printer control logic
-- Module Name:    IOREG8 - Behavioral 
-- Project Name: 		EBS7100
-- Target Devices:  XC3S200-4PQ208
-- Tool versions:   ISE 8.2.03i	
-- Description: 		8-bit register for storing data
--
-- Dependencies: 	KROPKI, PORT_STER, KROPKIWRZ, PORTDRUK, STERDRUK
--								PORTFAZA, KOREKCJE, STER_SHAFT, INTERFACE_E, PORT_SW
--								SPI_CS
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

entity IOREG8 is
    Port ( 
					DATA_IN		: in	STD_LOGIC_VECTOR(7 downto 0);
					DATA_OUT	: out STD_LOGIC_VECTOR(7 downto 0);
					CS 				: in  STD_LOGIC;
					RNW				: in 	STD_LOGIC;
					RST 			: in  STD_LOGIC
					);
end IOREG8;

architecture Behavioral of IOREG8 is
signal DATA : std_logic_vector(7 downto 0);

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

