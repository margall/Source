----------------------------------------------------------------------------------
-- Company: 	EBS INK-JET SYSTEMS POLAND 
-- Engineer: 	TOMASZ GRONOWICZ
-- 
-- Create Date:    12:30:32 01/16/2007 
-- Design Name: 	 Printer control logic
-- Module Name:    SHAFT - Behavioral 
-- Project Name: 	 EBS7100	
-- Target Devices: XC3S200-4PQ208
-- Tool versions:  ISE 8.2.03i 
-- Description: 	SHAFT control module
--								Vhdl code translation from original P332 file
--								Modified for better understanding
--								Added DIV_8 instead SUB_CNT's
--
--								Rows fire - generates signal for printing a row
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

entity SHAFT is
   port ( 
					ROWS_S			: out std_logic;	--Start printing a row
					
					CO_POL_TAKT : in  std_logic; --PORT_STER(6)
          F_16MHZ     : in  std_logic;
					
          START_B     : in  std_logic; --Enable encoder - '1' - enabled - PORTDRUK(4)
          CLR_FIRE		: in	std_logic;	--Clear fire signal
					STERSHAFT   : in  std_logic_vector (7 downto 0);  --STER_SHAFT
					SHFT_NGEN		: in	std_logic; -- 1 - encoder 0 - generator - PORTDRUK(0)
					
					SHAFT_IN    : in  std_logic; --Encoder input
          --SHAFT_DIV   : out   std_logic	-- Encoder output divided by STER_SHAFT
					GEN					: in 	std_logic	-- Internal generator printing
				);
end SHAFT;

architecture BEHAVIORAL of SHAFT is
attribute INIT       : string ;
attribute BOX_TYPE   : string ;

signal CLKA        : std_logic;
signal CLR         : std_logic;
signal LOAD        : std_logic;
signal XLXN_3      : std_logic;
signal XLXN_7      : std_logic;
signal XLXN_10     : std_logic;
signal XLXN_12     : std_logic;
signal XLXN_13     : std_logic;
signal XLXN_30     : std_logic;
signal XLXN_40     : std_logic;
signal XLXN_41     : std_logic;
signal XLXN_42     : std_logic;
signal XLXN_43     : std_logic;
signal XLXN_44     : std_logic;
signal XLXN_45     : std_logic;
signal XLXN_46     : std_logic;
signal XLXN_47     : std_logic;
signal XLXN_63     : std_logic;
signal XLXN_64     : std_logic;
	 
component DIV_8
port ( PORT_IN : in   STD_LOGIC_VECTOR (7 downto 0);
			 CLK_IN  : in   STD_LOGIC;
			 CLK_OUT : out  STD_LOGIC;
			 CLR			: in 	 STD_LOGIC);
end component;
						
component SHIFT_RC_2B
port ( IN0 : in    std_logic; 
       CLK : in    std_logic; 
       CLR : in    std_logic; 
       Q0  : out   std_logic; 
       Q1  : out   std_logic);
end component;
   
component FDC
 -- synopsys translate_off
	generic( INIT : bit :=  '0');
 -- synopsys translate_on
port ( C   : in    std_logic; 
       CLR : in    std_logic; 
       D   : in    std_logic; 
       Q   : out   std_logic);
end component;

attribute INIT of FDC : component is "0";
attribute BOX_TYPE of FDC : component is "BLACK_BOX";
   
component AND2
port ( I0 : in    std_logic; 
       I1 : in    std_logic; 
       O  : out   std_logic);
end component;
attribute BOX_TYPE of AND2 : component is "BLACK_BOX";
   
component XOR2
port ( I0 : in    std_logic; 
       I1 : in    std_logic; 
       O  : out   std_logic);
end component;
attribute BOX_TYPE of XOR2 : component is "BLACK_BOX";
   
component AND3B1
port ( I0 : in    std_logic; 
       I1 : in    std_logic; 
       I2 : in    std_logic; 
       O  : out   std_logic);
end component;
attribute BOX_TYPE of AND3B1 : component is "BLACK_BOX";
   
component INV
port ( I : in    std_logic; 
       O : out   std_logic);
end component;
attribute BOX_TYPE of INV : component is "BLACK_BOX";

signal SHAFT_DIV	: std_logic;   
signal ROWS_S_CLK : std_logic;
   
begin

ROWS_S_PROC: process(ROWS_S_CLK, CLR_FIRE, START_B)
begin

	if (CLR_FIRE='1' or START_B = '0') then
		ROWS_S <= '0';
	elsif(ROWS_S_CLK'event and ROWS_S_CLK='1') then
		ROWS_S <= '1';
	end if;

end process ROWS_S_PROC;

MUX_GEN_SHAFT: process (SHAFT_DIV,GEN, SHFT_NGEN)
begin

	if (SHFT_NGEN ='1') then
		ROWS_S_CLK <= SHAFT_DIV;
	else
		ROWS_S_CLK <= GEN;
	end if;
	
end process MUX_GEN_SHAFT;

-- Shaft divider block
-- Signal SHAFT_DIV is used to generate the ROWS_S signal if SHFT_NGEN = 0
DIV_8_MAP: DIV_8
port map ( PORT_IN => STERSHAFT,
					 CLK_IN  => CLKA,
					 CLK_OUT => LOAD,
					 CLR	=> CLR
					 );

U27 : SHIFT_RC_2B
port map (CLK=>F_16MHZ,
          IN0=>CLKA,
          Q0=>XLXN_30,
          Q1=>XLXN_63,
  				CLR => CLR
  				);
								
U28 : SHIFT_RC_2B
port map (CLK=>F_16MHZ,
          CLR=>CLR,
          IN0=>XLXN_7,
          Q0=>XLXN_12,
          Q1=>XLXN_10);
   
XLXI_27 : FDC
port map (C=>F_16MHZ,
          CLR=>CLR,
          D=>SHAFT_IN,
          Q=>XLXN_3);
   
XLXI_28 : FDC
port map (C=>CLKA,
          CLR=>CLR,
          D=>LOAD,
          Q=>XLXN_64);
   
XLXI_29 : AND2
port map (I0=>SHAFT_IN,
          I1=>XLXN_3,
          O=>XLXN_7);
   
XLXI_30 : AND2
port map (I0=>XLXN_10,
          I1=>CO_POL_TAKT,
          O=>XLXN_13);
   
XLXI_31 : XOR2
port map (I0=>XLXN_13,
          I1=>XLXN_12,
          O=>CLKA);
   
XLXI_32 : AND3B1
port map (I0=>XLXN_63,
          I1=>XLXN_30,
          I2=>XLXN_64,
          O=>SHAFT_DIV);
   
XLXI_33 : INV
port map (I=>START_B,
          O=>CLR);
   
  
end BEHAVIORAL;


