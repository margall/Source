----------------------------------------------------------------------------------
-- Company: 	EBS INK-JET SYSTEMS POLAND 
-- Engineer: 	TOMASZ GRONOWICZ
-- 
-- Create Date: 	11:03:10 12/16/2006 
-- Design Name: 	Printer control logic
-- Module Name: 	SPI_INTERFACE - Behavioral 
-- Project Name: 	EBS6500/EBS7100
-- Target Devices: XC3S200-4PQ208
-- Tool versions: ISE 10.1.3i
-- Description: 
--
-- Dependencies: 
--
-- Revision:
--
-- Rev. 0.02
-- option PP7K_3B has been added.
-- if 0 - SPI for SS1 and SS3 is blocked
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

entity SPI_INTERFACE is
	Generic (PP7K_3B : integer := 0);	-- if 1 signals for board PP7K-3B and previous
	Port ( 
		SPI_SCK_IN 		: in  STD_LOGIC;
		SPI_SCK_OUT 	: out STD_LOGIC;
			
		SPI_MISO_IN 	: in  STD_LOGIC;
		SPI_MISO_OUT 	: out STD_LOGIC;
				
		SPI_MOSI_IN 	: in  STD_LOGIC;
		SPI_MOSI_OUT 	: out STD_LOGIC;
				
		SPI_NSS			: in  STD_LOGIC;	-- SPI CS from processor
		SPI_CS_IN 		: in  STD_LOGIC_VECTOR (7 downto 0);
		SPI_CS_OUT 		: out STD_LOGIC_VECTOR (7 downto 0)
	);
end SPI_INTERFACE;

architecture Behavioral of SPI_INTERFACE is

signal SPI_CS_TMP0 : std_logic_vector(7 downto 0) := "11111111";
signal SPI_CS_TMP1 : std_logic_vector(7 downto 0) := "11111011";

begin

--PP7K-3C and next
PP7K_3C_NEW: 
	if (PP7K_3B = 0) generate

SPI_MISO_OUT <= SPI_MISO_IN when SPI_CS_IN(0) ='0' else 'Z';
SPI_MISO_OUT <= SPI_MISO_IN when SPI_CS_IN(1) ='0' else 'Z';
SPI_MISO_OUT <= SPI_MISO_IN when SPI_CS_IN(2) ='0' else 'Z';
SPI_MOSI_OUT <= SPI_MOSI_IN;

SPI_SCK_OUT	<= SPI_SCK_IN;

-- Because the CS3 for USB interface must be '1' for operation
-- CS1 (SD card) and CS3 (USB) blocked for PP7K-3C 
SPI_CS_TMP0	<= SPI_CS_IN(7 downto 1) & '1';

CS_PROC: process(SPI_CS_IN, SPI_NSS)
begin
	case(SPI_CS_IN)is
		when "11111111" => SPI_CS_OUT <= SPI_CS_TMP0;
		when "11111110" => SPI_CS_OUT <= SPI_CS_TMP0; --SPI_CS_TMP0(7 downto 1)& SPI_NSS;	
		when "11111101" => SPI_CS_OUT <= SPI_CS_TMP0(7 downto 2)& SPI_NSS & SPI_CS_TMP0(0);
		--when "11111011" => SPI_CS_OUT <= SPI_CS_TMP0;
		when "11111011" => SPI_CS_OUT <= SPI_CS_TMP0(7 downto 3)& SPI_NSS & SPI_CS_TMP0(1 downto 0); 
		when "11110111" => SPI_CS_OUT <= SPI_CS_TMP0(7 downto 4)& SPI_NSS & SPI_CS_TMP0(2 downto 0);
		when "11101111" => SPI_CS_OUT <= SPI_CS_TMP0(7 downto 5)& SPI_NSS & SPI_CS_TMP0(3 downto 0);
		when "11011111" => SPI_CS_OUT <= SPI_CS_TMP0(7 downto 6)& SPI_NSS & SPI_CS_TMP0(4 downto 0);
		when "10111111" => SPI_CS_OUT <= SPI_CS_TMP0(7)& SPI_NSS & SPI_CS_TMP0(5 downto 0);
		when "01111111" => SPI_CS_OUT <= SPI_NSS & SPI_CS_TMP0(6 downto 0);
		when others => SPI_CS_OUT <= SPI_CS_TMP0;
	end case;

end process CS_PROC;
end generate;	--PP7K_3B = 0

--PP7K-3B and previous
PP7K_3B_OLD: 
	if (PP7K_3B = 1) generate

SPI_MISO_OUT <= SPI_MISO_IN when SPI_CS_IN(0) ='0' else 'Z';
SPI_MISO_OUT <= SPI_MISO_IN when SPI_CS_IN(1) ='0' else 'Z';
SPI_MISO_OUT <= SPI_MISO_IN when SPI_CS_IN(2) ='0' else 'Z';
SPI_MOSI_OUT <= SPI_MOSI_IN;

SPI_SCK_OUT	<= SPI_SCK_IN;

--Because the CS3 for USB interface must be '1' for operation
SPI_CS_TMP1	<= SPI_CS_IN(7 downto 3) & not SPI_CS_IN(2) & SPI_CS_IN(1 downto 0);

CS_PROC: process(SPI_CS_IN, SPI_NSS)
begin
	case(SPI_CS_IN)is
		when "11111111" => SPI_CS_OUT <= SPI_CS_TMP1;
		when "11111110" => SPI_CS_OUT <= SPI_CS_TMP1(7 downto 1)& SPI_NSS;	
		when "11111101" => SPI_CS_OUT <= SPI_CS_TMP1(7 downto 2)& SPI_NSS & SPI_CS_TMP1(0);
		when "11111011" => SPI_CS_OUT <= SPI_CS_TMP1(7 downto 3)& not SPI_NSS & SPI_CS_TMP1(1 downto 0); --Because the CS3 for USB interface must be '1' for operation
		when "11110111" => SPI_CS_OUT <= SPI_CS_TMP1(7 downto 4)& SPI_NSS & SPI_CS_TMP1(2 downto 0);
		when "11101111" => SPI_CS_OUT <= SPI_CS_TMP1(7 downto 5)& SPI_NSS & SPI_CS_TMP1(3 downto 0);
		when "11011111" => SPI_CS_OUT <= SPI_CS_TMP1(7 downto 6)& SPI_NSS & SPI_CS_TMP1(4 downto 0);
		when "10111111" => SPI_CS_OUT <= SPI_CS_TMP1(7)& SPI_NSS & SPI_CS_TMP1(5 downto 0);
		when "01111111" => SPI_CS_OUT <= SPI_NSS & SPI_CS_TMP1(6 downto 0);
		when others => SPI_CS_OUT <= SPI_CS_TMP1;
	end case;

end process CS_PROC;
end generate;	--PP7K_3B = 1

end Behavioral;

