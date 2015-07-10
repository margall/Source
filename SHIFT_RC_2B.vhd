----------------------------------------------------------------------------------
-- Company: 	EBS INK-JET SYSTEMS POLAND 
-- Engineer: 	TOMASZ GRONOWICZ
-- 
-- Create Date:    12:30:32 01/16/2007 
-- Design Name: 	 Printer control logic
-- Module Name:    SHIFT_RC_2B - Behavioral 
-- Project Name: 	 EBS7100	
-- Target Devices: XC3S200-4PQ208
-- Tool versions:  ISE 8.2.03i 
-- Description: 	RC Register. Q0 - n+1 Q1 - not n+1
--								Vhdl code translation from original P332 file
--								Modified for better understanding
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
library UNISIM;
use UNISIM.Vcomponents.ALL;

entity SHIFT_RC_2B is
   port ( 
					CLK : in    std_logic; 
          CLR : in    std_logic; 
          IN0 : in    std_logic; 
          Q0  : out   std_logic; 
          Q1  : out   std_logic
				);
end SHIFT_RC_2B;

architecture BEHAVIORAL of SHIFT_RC_2B is

attribute INIT       : string ;
attribute BOX_TYPE   : string ;
	 
signal XLXN_2   : std_logic;
signal Q0_DUMMY : std_logic;
	 
component FDC
-- synopsys translate_off
generic( INIT : bit :=  '0');
-- synopsys translate_on
   port ( C   : in    std_logic; 
          CLR : in    std_logic; 
          D   : in    std_logic; 
          Q   : out   std_logic
				);
end component;
attribute INIT of FDC : component is "0";
attribute BOX_TYPE of FDC : component is "BLACK_BOX";
   
component FDC_1
-- synopsys translate_off
generic( INIT : bit :=  '0');
-- synopsys translate_on
    port ( C   : in    std_logic; 
           CLR : in    std_logic; 
           D   : in    std_logic; 
           Q   : out   std_logic);
end component;

attribute INIT of FDC_1 : component is "0";
attribute BOX_TYPE of FDC_1 : component is "BLACK_BOX";
   
begin
   Q0 <= Q0_DUMMY;
	 
XLXI_1 : FDC
port map (C=>CLK,
          CLR=>CLR,
          D=>IN0,
          Q=>Q0_DUMMY);
   
XLXI_2 : FDC
port map ( C=>CLK,
           CLR=>CLR,
           D=>XLXN_2,
           Q=>Q1);
   
XLXI_3 : FDC_1
port map ( C=>CLK,
           CLR=>CLR,
           D=>Q0_DUMMY,
           Q=>XLXN_2);
   
end BEHAVIORAL;


