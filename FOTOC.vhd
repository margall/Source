----------------------------------------------------------------------------------
-- Company:			EBS INK-JET SYSTEMS POLAND 
-- Engineer: 		TOMASZ GRONOWICZ  
-- 
-- Create Date:    10:28:00 01/15/2007 
-- Design Name: 	 Printer control logic
-- Module Name:    FOTOC - Behavioral 
-- Project Name: 	EBS7100	
-- Target Devices: XC3S200-4PQ208
-- Tool versions:  ISE 8.2.03i 
-- Description: 	 Module generates IRQ form Photodetector
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

entity FOTOC is
    Port ( 
				FOTOC_IN 		: in  STD_LOGIC;
           	FOTOC_EDGE 		: in  STD_LOGIC; -- Edge selection - PORTDRUK(3)
				FOTOC_BLOCK		: in 	STD_LOGIC; -- Block Photodetector - STERDRUK(4)
					 
				FOTOC_IRQ 		: out  STD_LOGIC;	--IRQ from Photodetector - active HIGH
				FOTOC_STAT 		: out  STD_LOGIC;
					 
				FOTOC_F_16MHZ 	: in  STD_LOGIC
			);
end FOTOC;

architecture Behavioral of FOTOC is

signal FOTOC_BUF 	 		: std_logic;
signal FOTOC_STAT_BUF 	: std_logic;
signal FOTOC_EDGE_DET	: std_logic;

begin

-- Photo input controlled by xor (controlled not)
-- edge detection by bufforing signal
-- signal FOTOC_EDGE decides if structure works on positiv or negativ edge
-- FOTOC_EDGE = 1 -> positiv, 0 -> negativ
-- FOTOC_STATE - normal or inverting FOTOC_IN, depends on active edge 
-- FOTOC_BLOCK - enable/reset FOTOC_IRQ (interrupt)

FOTOC_BUF <= FOTOC_IN xor FOTOC_EDGE;
FOTOC_STAT <=  not FOTOC_BUF;

FOTOC_BUF_PROC: process(FOTOC_F_16MHZ)
begin	

	if (FOTOC_F_16MHZ'event and FOTOC_F_16MHZ='1') then
		FOTOC_STAT_BUF <= FOTOC_BUF;
	end if;
	
end process FOTOC_BUF_PROC;

FOTOC_EDGE_DET <= FOTOC_STAT_BUF and not FOTOC_BUF;
		
-- Photo irq generation

FOTOC_PROC: process (FOTOC_F_16MHZ)
begin

	if (FOTOC_F_16MHZ'event and FOTOC_F_16MHZ = '1') then
		if (FOTOC_BLOCK ='1') then
			FOTOC_IRQ <= '0';
		elsif (FOTOC_EDGE_DET = '1') then
			FOTOC_IRQ <= '1';
		end if;
	end if;

end process FOTOC_PROC;

end Behavioral;

