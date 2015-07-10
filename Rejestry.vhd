----------------------------------------------------------------------------------
-- Company:			EBS INK-JET SYSTEMS POLAND 
-- Engineer: 		TOMASZ GRONOWICZ
-- 
-- Create Date:    06:56:03 04/23/2007 
-- Design Name: 		Printer control logic
-- Module Name:    Rejestry - Behavioral 
-- Project Name: 	 EBS7100	
-- Target Devices: XC3S200-4PQ208
-- Tool versions:  ISE 8.2.03i
-- Description: 	Registers - all used data registers
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

entity Rejestry is
	Port (
				--Processor bus
				REG_P_ADDR 			: in		std_logic_vector(15 downto 0);	-- Addr
				REG_P_DATA			: inout std_logic_vector(15 downto 0);	-- Data out
				REG_P_NCS				: in		std_logic;											-- CS
				REG_P_RNW				:	in		std_logic;											-- RNW
				
				-- Registers
				REG_KROPKI					: inout std_logic_vector (7 downto 0);
				REG_PORT_STER				: inout std_logic_vector (7 downto 0);
				REG_KROPWRZ					: inout std_logic_vector (7 downto 0);
				REG_PORTDRUK				: inout std_logic_vector (7 downto 0);
				
				REG_STERDRUK				: inout std_logic_vector (7 downto 0);
				REG_PORTFAZA				: inout std_logic_vector (7 downto 0);
				REG_KOREKCJE				: inout std_logic_vector (7 downto 0);
				REG_STER_SHAFT			: inout std_logic_vector (7 downto 0);
				
				REG_TIMERCTRL				: inout std_logic_vector (15 downto 0);
				REG_TIMERDODEL			: inout std_logic_vector (15 downto 0);
				REG_TIMERRYNNA			: inout std_logic_vector (15 downto 0);
				REG_TIMERSTATUS			: inout std_logic_vector (15 downto 0);
				
				REG_SHIFT16BIT			: inout std_logic_vector (15 downto 0);
				REG_CZASKROPLISTER	: inout std_logic_vector (15 downto 0);
				REG_INTERFACE_E			: inout std_logic_vector (7 downto 0);
				REG_PORT_SW					: inout std_logic_vector (7 downto 0);
				
				REG_SPI_CS					: inout std_logic_vector (7 downto 0);
				
				REG_RST				: in	std_logic				-- Reset
				);
end Rejestry;

architecture Behavioral of Rejestry is

-- Ports addresses ----------------------------------------------------------------
constant KROPKI_ADDR 	   	 : std_logic_vector(15 downto 0):= "0000000000000010" ;
constant PORT_STER_ADDR    : std_logic_vector(15 downto 0):= "0000000000000100" ;
constant KROPWRZ_ADDR    	 : std_logic_vector(15 downto 0):= "0000000000001000" ;
constant PORTDRUK_ADDR 	   : std_logic_vector(15 downto 0):= "0000000000010000" ;
constant STERDRUK_ADDR 	   : std_logic_vector(15 downto 0):= "0000000000100000" ;
constant PORTFAZA_ADDR 	   : std_logic_vector(15 downto 0):= "0000000001000000" ;
constant KOREKCJE_ADDR 	   : std_logic_vector(15 downto 0):= "0000000010000000" ;
constant STER_SHAFT_ADDR   : std_logic_vector(15 downto 0):= "0000000100000000" ;
constant TIMERCTRL_ADDR    : std_logic_vector(15 downto 0):= "0000001000000000" ;
constant TIMERDODEL_ADDR   : std_logic_vector(15 downto 0):= "0000010000000000" ;
constant TIMERRYNNA_ADDR   : std_logic_vector(15 downto 0):= "0000100000000000" ;
constant TIMERSTATUS_ADDR  : std_logic_vector(15 downto 0):= "0001000000000000" ;
constant SHIFT16BIT_ADDR   : std_logic_vector(15 downto 0):= "0010000000000000" ;
constant CZKROPLISTER_ADDR : std_logic_vector(15 downto 0):= "0100000000000000" ;
constant INTERFACE_E_ADDR  : std_logic_vector(15 downto 0):= "1000000000000000" ;
constant PORT_SW1_ADDR 		 : std_logic_vector(15 downto 0):= "0010000000000010" ;
constant SPI_CS_ADDR 			 : std_logic_vector(15 downto 0):= "0010000000000100" ;

-- Ports CS -----------------------------------------------------
signal CS_KROPKI 					: STD_LOGIC;
signal CS_PORT_STER 			: STD_LOGIC;
signal CS_KROPWRZ 				: STD_LOGIC;
signal CS_PORTDRUK 				: STD_LOGIC;
signal CS_STERDRUK 				: STD_LOGIC;
signal CS_PORTFAZA 				: STD_LOGIC;
signal CS_KOREKCJE 				: STD_LOGIC;
signal CS_STER_SHAFT 			: STD_LOGIC;
signal CS_TIMERCTRL 			: STD_LOGIC;
signal CS_TIMERDODEL 			: STD_LOGIC;
signal CS_TIMERRYNNA 			: STD_LOGIC;
signal CS_TIMERSTATUS 		: STD_LOGIC;
signal CS_SHIFT16BIT 			: STD_LOGIC;
signal CS_CZASKROPLISTER	: STD_LOGIC;
signal CS_INTERFACE_E	 		: STD_LOGIC;
signal CS_PORT_SW 		 		: STD_LOGIC;
signal CS_SPI_CS	 		 		: STD_LOGIC;

-- Components ------------------------------------------------
component IOREG8 is
	Port ( 
				DATA_IN			: in	STD_LOGIC_VECTOR(7 downto 0);
				DATA_OUT		: out STD_LOGIC_VECTOR(7 downto 0);
				CS 					: in  STD_LOGIC;
				RNW					: in  STD_LOGIC;
				RST 				: in  STD_LOGIC
			  );
end component IOREG8;

component IOREG16 is
	Port ( 
				DATA_IN		 	: in	STD_LOGIC_VECTOR(15 downto 0);
				DATA_OUT		: out	STD_LOGIC_VECTOR(15 downto 0);
				CS 					: in  STD_LOGIC;
				RNW					: in 	STD_LOGIC;
				RST 				: in  STD_LOGIC
			  );
end component IOREG16;

----------------------------------------------------------------------------
signal REG_P_DATA_IN	: std_logic_vector(15 downto 0);
signal REG_P_DATA_OUT	: std_logic_vector(15 downto 0);
-----------------------------------------------------------------------------

begin

-- Set proper CS -------------------------------------------------------
SWITCH: process (REG_P_NCS, REG_P_RNW, REG_RST)
begin

	 CS_KROPKI <= '0';
	 CS_PORT_STER <= '0';
   CS_KROPWRZ <= '0';
   CS_PORTDRUK <= '0';
   CS_STERDRUK <= '0';
   CS_PORTFAZA <= '0';
   CS_KOREKCJE <= '0';
   CS_STER_SHAFT <= '0';
   CS_TIMERCTRL <= '0';
   CS_TIMERDODEL <= '0';
   CS_TIMERRYNNA <= '0';
   CS_TIMERSTATUS <= '0';
   CS_SHIFT16BIT 	<= '0';
   CS_CZASKROPLISTER <= '0';
   CS_INTERFACE_E <= '0';
   CS_PORT_SW <= '0';
	 CS_SPI_CS <= '0';
			
	if (REG_RST = '0') then
		CS_KROPKI <= '0';
    CS_PORT_STER <= '0';
    CS_KROPWRZ <= '0';
    CS_PORTDRUK <= '0';
    CS_STERDRUK <= '0';
    CS_PORTFAZA <= '0';
    CS_KOREKCJE <= '0';
    CS_STER_SHAFT <= '0';
    CS_TIMERCTRL <= '0';
    CS_TIMERDODEL <= '0';
    CS_TIMERRYNNA <= '0';
    CS_TIMERSTATUS <= '0';
    CS_SHIFT16BIT 	<= '0';
    CS_CZASKROPLISTER <= '0';
    CS_INTERFACE_E <= '0';
    CS_PORT_SW <= '0';
		CS_SPI_CS <= '0';
	
	elsif (REG_P_NCS ='0') then
			
		if (REG_P_ADDR = KROPKI_ADDR) then
			CS_KROPKI<= '1';
			if (REG_P_RNW='1')then
				REG_P_DATA_OUT (7 downto 0) <= (others =>'0');
				REG_P_DATA_OUT (15 downto 8) <= REG_KROPKI;
			end if;
			
		elsif (REG_P_ADDR = PORT_STER_ADDR) then
			CS_PORT_STER <= '1';
			if (REG_P_RNW='1')then
				REG_P_DATA_OUT(7 downto 0) <= (others =>'0');
				REG_P_DATA_OUT (15 downto 8) <= REG_PORT_STER;
			end if;
			
		elsif (REG_P_ADDR = KROPWRZ_ADDR) then
			CS_KROPWRZ <= '1';
			if (REG_P_RNW='1')then
				REG_P_DATA_OUT(7 downto 0) <= (others =>'0');
				REG_P_DATA_OUT (15 downto 8) <= REG_KROPWRZ;
			end if;
			
		elsif (REG_P_ADDR = PORTDRUK_ADDR) then
			CS_PORTDRUK <= '1';
			if (REG_P_RNW='1')then
				REG_P_DATA_OUT(7 downto 0) <= (others =>'0');
				REG_P_DATA_OUT (15 downto 8) <= REG_PORTDRUK;
			end if;
			
		elsif (REG_P_ADDR = STERDRUK_ADDR) then
			CS_STERDRUK <='1';
			if (REG_P_RNW='1')then
				REG_P_DATA_OUT(7 downto 0) <= (others =>'0');
				REG_P_DATA_OUT (15 downto 8) <= REG_STERDRUK;
			end if;
			
		elsif (REG_P_ADDR = PORTFAZA_ADDR) then
			CS_PORTFAZA <= '1';
			if (REG_P_RNW='1')then
				REG_P_DATA_OUT(7 downto 0) <= (others =>'0');
				REG_P_DATA_OUT (15 downto 8) <= REG_PORTFAZA;
			end if;
			
		elsif (REG_P_ADDR = KOREKCJE_ADDR) then
			CS_KOREKCJE <= '1';
			if (REG_P_RNW='1')then
				REG_P_DATA_OUT(7 downto 0) <= (others =>'0');
				REG_P_DATA_OUT (15 downto 8) <= REG_KOREKCJE;
			end if;
			
		elsif (REG_P_ADDR = STER_SHAFT_ADDR) then
			CS_STER_SHAFT <= '1';
			if (REG_P_RNW='1')then
				REG_P_DATA_OUT(7 downto 0) <= (others =>'0');
				REG_P_DATA_OUT (15 downto 8) <= REG_STER_SHAFT;
			end if;
			
		elsif (REG_P_ADDR = TIMERCTRL_ADDR) then
			CS_TIMERCTRL <= '1';
			if (REG_P_RNW='1')then
				REG_P_DATA_OUT <= REG_TIMERCTRL;
			end if;
			
		elsif (REG_P_ADDR = TIMERDODEL_ADDR) then
			CS_TIMERDODEL <= '1';
			if (REG_P_RNW='1')then
				REG_P_DATA_OUT <= REG_TIMERDODEL;
			end if;
			
		elsif (REG_P_ADDR = TIMERRYNNA_ADDR) then
			CS_TIMERRYNNA <= '1';
			if (REG_P_RNW='1')then
				REG_P_DATA_OUT <= REG_TIMERRYNNA;
			end if;
			
		elsif (REG_P_ADDR = TIMERSTATUS_ADDR) then
			CS_TIMERSTATUS <= '1';
			if (REG_P_RNW='1')then
				REG_P_DATA_OUT <= REG_TIMERSTATUS;
			end if;
			
		elsif (REG_P_ADDR = SHIFT16BIT_ADDR) then
			CS_SHIFT16BIT <= '1';
			if (REG_P_RNW='1')then
				REG_P_DATA_OUT <= REG_SHIFT16BIT;
			end if;
			
		elsif (REG_P_ADDR = CZKROPLISTER_ADDR) then
			CS_CZASKROPLISTER <='1';
			if (REG_P_RNW='1')then
				REG_P_DATA_OUT <= REG_CZASKROPLISTER;
			end if;
			
		elsif (REG_P_ADDR = INTERFACE_E_ADDR) then
			CS_INTERFACE_E <= '1';
			if (REG_P_RNW='1')then
				REG_P_DATA_OUT(7 downto 0) <= (others =>'0');
				REG_P_DATA_OUT (15 downto 8) <= REG_INTERFACE_E;
			end if;
			
		elsif (REG_P_ADDR = PORT_SW1_ADDR) then
			CS_PORT_SW <= '1';
			if (REG_P_RNW='1')then
				REG_P_DATA_OUT(7 downto 0) <= (others =>'0');
				REG_P_DATA_OUT (15 downto 8) <= REG_PORT_SW;
			end if;
			
		elsif (REG_P_ADDR = SPI_CS_ADDR) then
			CS_SPI_CS <= '1';
			if (REG_P_RNW='1')then
				REG_P_DATA_OUT(7 downto 0) <= (others =>'0');
				REG_P_DATA_OUT (15 downto 8) <= REG_SPI_CS;
			end if;	
		end if;
		
--	else
--		if (PORTFAZA(4)='1' and PORTFAZA(7)='1') then
--			TIMERCTRL_COR_1 <= TIMERCTRL;
--		elsif (PORTFAZA(4)='0' and PORTFAZA(7)='1') then
--			CS_TIMERCTRL <= '1';
--			RNW_TIMERCTRL <= '0';
--		end if;

	end if; --od (REG_P_NCS='0')

end process SWITCH;

-- PORTS ----------------------------------------------------
--KROPKI
KROPKI_MAP: IOREG8
PORT MAP (
				DATA_IN 	=> REG_P_DATA_IN(7 downto 0),
				DATA_OUT	=> REG_KROPKI,
				CS 		=> CS_KROPKI,
				RNW		=> REG_P_RNW,
				RST 		=> REG_RST
			);
			
--PORTSTER
PORT_STER_MAP: IOREG8
PORT MAP (
				DATA_IN 	=> REG_P_DATA_IN(7 downto 0),
				DATA_OUT	=> REG_PORT_STER,
				CS 		=> CS_PORT_STER,
				RNW		=> REG_P_RNW,
				RST 		=> REG_RST
			);
			
-- KROPKIWRZ
KROPKIWRZ_MAP: IOREG8
PORT MAP (
				DATA_IN(7 downto 0)	=> REG_P_DATA_IN(7 downto 0),
				DATA_OUT	=> REG_KROPWRZ,
				CS 		=> CS_KROPWRZ,
				RNW		=> REG_P_RNW,
				RST 		=> REG_RST
			);

-- PORTDRUK
PORTDRUK_MAP: IOREG8
PORT MAP (
				DATA_IN(7 downto 0)	=> REG_P_DATA_IN(7 downto 0),
				DATA_OUT	=> REG_PORTDRUK,
				CS 		=> CS_PORTDRUK,
				RNW		=> REG_P_RNW,
				RST 		=> REG_RST
			);

-- STERDRUK
STERDRUK_MAP: IOREG8
PORT MAP (
				DATA_IN(7 downto 0)	=> REG_P_DATA_IN(7 downto 0),
				DATA_OUT	=> REG_STERDRUK,
				CS 		=> CS_STERDRUK,
				RNW		=> REG_P_RNW,
				RST 		=> REG_RST
			);

-- PORTFAZA
PORTFAZA_MAP: IOREG8
PORT MAP (
				DATA_IN (7 downto 0)	=> REG_P_DATA_IN(7 downto 0),
				DATA_OUT	=> REG_PORTFAZA,
				CS 		=> CS_PORTFAZA,
				RNW		=> REG_P_RNW,
				RST 		=> REG_RST
			);
	
-- KOREKCJE
KOREKCJE_MAP: IOREG8
PORT MAP (
				DATA_IN (7 downto 0)	=> REG_P_DATA_IN(7 downto 0),
				DATA_OUT	=> REG_KOREKCJE,
				CS 		=> CS_KOREKCJE,
				RNW		=> REG_P_RNW,
				RST 		=> REG_RST
			);

-- STER_SHAFT
STER_SHAFT_MAP: IOREG8
PORT MAP (
				DATA_IN (7 downto 0)	=> REG_P_DATA_IN(7 downto 0),
				DATA_OUT	=> REG_STER_SHAFT,
				CS 		=> CS_STER_SHAFT,
				RNW		=> REG_P_RNW,
				RST 		=> REG_RST
			);

-- TIMERCTRL
TIMERCTRL_MAP: IOREG16
PORT MAP (
				DATA_IN 	=> REG_P_DATA_IN,
				DATA_OUT	=> REG_TIMERCTRL,
				CS 		=> CS_TIMERCTRL,
				RNW		=> REG_P_RNW,
				RST 	=> REG_RST
			);

-- TIMERDODEL
TIMERDODEL_MAP: IOREG16
PORT MAP (
				DATA_IN 	=> REG_P_DATA_IN,
				DATA_OUT	=> REG_TIMERDODEL,
				CS 		=> CS_TIMERDODEL,
				RNW		=> REG_P_RNW,
				RST 		=> REG_RST
			);

-- TIMERRYNNA
TIMERRYNNA_MAP: IOREG16
PORT MAP (
				DATA_IN 	=> REG_P_DATA_IN,
				DATA_OUT	=> REG_TIMERRYNNA,
				CS 		=> CS_TIMERRYNNA,
				RNW		=> REG_P_RNW,
				RST 		=> REG_RST
			);

-- TIMERSTATUS
TIMERSTATUS_MAP: IOREG16
PORT MAP (
				DATA_IN 	=> REG_P_DATA_IN,
				DATA_OUT	=> REG_TIMERSTATUS,
				CS 		=> CS_TIMERSTATUS,
				RNW		=> REG_P_RNW,
				RST 		=> REG_RST
			);

-- SHIFT16BIT
SHIFT16BIT_MAP: IOREG16
PORT MAP (
				DATA_IN 	=> REG_P_DATA_IN,
				DATA_OUT	=> REG_SHIFT16BIT,
				CS 		=> CS_SHIFT16BIT,
				RNW		=> REG_P_RNW,
				RST 		=> REG_RST
			);

-- CZASKROPLISTER
CZASKROPLISTER_MAP: IOREG16
PORT MAP (
				DATA_IN 	=> REG_P_DATA_IN,
				DATA_OUT	=> REG_CZASKROPLISTER,
				CS 		=> CS_CZASKROPLISTER,
				RNW		=> REG_P_RNW,
				RST 		=> REG_RST
			);

-- INTERFACE_E
INTERFACE_E_MAP: IOREG8
PORT MAP (
				DATA_IN(7 downto 0)	=> REG_P_DATA_IN(7 downto 0),
				DATA_OUT	=> REG_INTERFACE_E,
				CS 		=> CS_INTERFACE_E,
				RNW		=> REG_P_RNW,
				RST 		=> REG_RST
			);

-- PORT_SW
PORT_SW_MAP: IOREG8
PORT MAP (
				DATA_IN(7 downto 0)	=> REG_P_DATA_IN(7 downto 0),
				DATA_OUT	=> REG_PORT_SW,
				CS 		=> CS_PORT_SW,
				RNW		=> REG_P_RNW,
				RST 		=> REG_RST
			);

-- SPI_CS
SPI_CS_MAP: IOREG8
PORT MAP (
				DATA_IN(7 downto 0)	=> REG_P_DATA_IN(7 downto 0),
				DATA_OUT	=> REG_SPI_CS,
				CS 				=> CS_SPI_CS,
				RNW				=> REG_P_RNW,
				RST 			=> REG_RST
			);

--SWITCH PROC DATA OUT BUS
REG_P_DATA_OUT_BUS: process (REG_P_DATA_OUT,REG_P_RNW, REG_P_NCS)
begin
		if (REG_P_NCS='0' and REG_P_RNW='1') then
			REG_P_DATA <= REG_P_DATA_OUT;
		else
			REG_P_DATA <= (others => 'Z');
		end if;
end process REG_P_DATA_OUT_BUS;
REG_P_DATA_IN <= REG_P_DATA;

end Behavioral;

