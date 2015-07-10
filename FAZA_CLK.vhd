----------------------------------------------------------------------------------
-- Company: 	EBS INK-JET SYSTEMS POLAND 
-- Engineer: 	TOMASZ GRONOWICZ
-- 
-- Create Date:    08:39:07 01/30/2007 
-- Design Name: 	 Printer control logic
-- Module Name:    FAZA_CLK - Behavioral 
-- Project Name: 	 EBS7100	
-- Target Devices: XC3S200-4PQ208
-- Tool versions:  ISE 8.2.03i
-- Description: 	 Phase clock generation
--
-- Dependencies: 
--
-- Revision:
-- 
-- Rev. 1.00
-- 2013-01-10
-- Added PH_FAZA_CLK_DLY signal for switching FAZA_DRUK signal
-- used in phasing during printing. 
-- FAZ_CLK signal delayed by 2 edges of 16MHz clock
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

entity FAZA_CLK is
	Port ( 
		PH_F_16MHz 		: in  STD_LOGIC;		-- 16MHz clock
		PH_CZAS_KROPLI 	: in  STD_LOGIC_VECTOR (7 downto 0);	-- drop time - default 16 us
		PH_PORT_FAZA 	: in  STD_LOGIC_VECTOR (2 downto 0);	-- Phase no: b0-1 - phase b2- neg phase

		PH_FAZA_CLK_OK	: out STD_LOGIC;	-- Phase clock signal to generate drops
		PH_DROP_FREQ	: out STD_LOGIC;	-- Drop frequency signal
		PH_FAZA_CLK_DLY	: out STD_LOGIC;	-- Delayed phase clock for switching FAZA_DRUK signal
		
		--Controll signals and external drop frequency
		PH_FAZA_CLK_CTRL : out STD_LOGIC;	-- Phase clock signal - controll
		PH_DROP_EXT_CTRL : in STD_LOGIC;	-- Drop freq controll - '1' - external drop frequency
		PH_DROP_EXT_FREQ : in STD_LOGIC		-- External drop frequency signal
		);
end FAZA_CLK;

architecture Behavioral of FAZA_CLK is

-- Divider by 8 ------------------------------------
component DIV_8 is
	Port ( 
		PORT_IN : in STD_LOGIC_VECTOR (7 downto 0);
		CLK_IN 	: in STD_LOGIC;
		CLK_OUT : out STD_LOGIC;
		CLR		: in STD_LOGIC
	);
end component DIV_8;

signal FAZA_CLK_INT  : std_logic; -- internal phase clock - for normal breaking 2us

signal FAZA_SHIFT 	: std_logic_vector(7 downto 0) := "00000000"; -- all phases
signal PH_CNT	 	: integer range 0 to 5 := 1;
signal PH_TRIG  	: std_logic_vector(7 downto 0):= "00000000";

signal FAZA_DLY	: std_logic;	-- intermediate clock for FAZA_CLK_DLY

begin

-----------------------------------------------------------------
-- FAZA_CLK_INT is a 16MHz clock divided by CZAS_KROPLI_STER
-- For CZAS_KROPLI_STER = 0x1F the CLK_OUT is 2us
DIV8_MAP: DIV_8
PORT MAP ( 
	PORT_IN => PH_CZAS_KROPLI,
	CLK_IN => PH_F_16MHz,
	CLK_OUT => FAZA_CLK_INT,
	CLR =>'0'
	);

--Output phase signal
PH_FAZA_CLK_CTRL <= FAZA_CLK_INT;

--------------------------------------------------------------------
-- 8 phases generation
PH_8_GEN: process (FAZA_CLK_INT, PH_DROP_EXT_CTRL,PH_DROP_EXT_FREQ)
begin

	if (FAZA_CLK_INT'event and FAZA_CLK_INT='1') then
		--FAZA_SHIFT <= FAZA_SHIFT+1;
		PH_CNT<= PH_CNT+1;
		
		if (PH_DROP_EXT_CTRL='1') then
			FAZA_SHIFT(0) <= PH_DROP_EXT_FREQ;
			PH_TRIG(0) <= '1';
			PH_CNT <= 1;
		else
			--Phase 0
			if (PH_CNT = 4) then
				FAZA_SHIFT(0) <= not FAZA_SHIFT(0);
				PH_TRIG(0) <= '1';
				PH_CNT <= 1;
			end if;
		end if;
		
		--Phase 1
		if (PH_TRIG(0) = '1') then
			FAZA_SHIFT(1) <= FAZA_SHIFT(0);--not FAZA_SHIFT(1);
			PH_TRIG(1) <= '1';
			PH_TRIG(0) <= '0';
		end if;
		
		--Phase 2
		if (PH_TRIG(1) = '1') then
			FAZA_SHIFT(2) <= FAZA_SHIFT(1); --not FAZA_SHIFT(2);
			PH_TRIG(2) <= '1';
			PH_TRIG(1) <= '0';
		end if;
		
		--Phase 3
		if (PH_TRIG(2) = '1') then
			FAZA_SHIFT(3) <= FAZA_SHIFT(2);--not FAZA_SHIFT(3);
			PH_TRIG(3) <= '1';
			PH_TRIG(2) <= '0';
		end if;
		
		--Phase 4
		if (PH_TRIG(3) = '1') then
			FAZA_SHIFT(4) <= FAZA_SHIFT(3); --not FAZA_SHIFT(4);
			PH_TRIG(4) <= '1';
			PH_TRIG(3) <= '0';
		end if;
		
		--Phase 5
		if (PH_TRIG(4) = '1') then
			FAZA_SHIFT(5) <= FAZA_SHIFT(4);--not FAZA_SHIFT(5);
			PH_TRIG(5) <= '1';
			PH_TRIG(4) <= '0';
		end if;
		
		--Phase 6
		if (PH_TRIG(5) = '1') then
			FAZA_SHIFT(6) <= FAZA_SHIFT(5); --not FAZA_SHIFT(6);
			PH_TRIG(6) <= '1';
			PH_TRIG(5) <= '0';
		end if;
		
		--Phase 7
		if (PH_TRIG(6) = '1') then
			FAZA_SHIFT(7) <= FAZA_SHIFT(6); --not FAZA_SHIFT(7);
			--PH_TRIG(4) <= '1';
			PH_TRIG(6) <= '0';
		end if;
		
	end if;
	
end process PH_8_GEN;

-- Drop frequency oputput signal
PH_DROP_FREQ <= FAZA_SHIFT(0);

-------------------------------------------------------------------------------
-- Send phase to output
PH_SEND_PROC: process (FAZA_SHIFT, PH_PORT_FAZA)
begin
	case PH_PORT_FAZA is
		when "000" => PH_FAZA_CLK_OK <= FAZA_SHIFT(0);
		when "001" => PH_FAZA_CLK_OK <= FAZA_SHIFT(1);
		when "010" => PH_FAZA_CLK_OK <= FAZA_SHIFT(2);
		when "011" => PH_FAZA_CLK_OK <= FAZA_SHIFT(3);
		when "100" => PH_FAZA_CLK_OK <= not FAZA_SHIFT(0);
		when "101" => PH_FAZA_CLK_OK <= not FAZA_SHIFT(1);
		when "110" => PH_FAZA_CLK_OK <= not FAZA_SHIFT(2);
		when "111" => PH_FAZA_CLK_OK <= not FAZA_SHIFT(3);
		when others =>PH_FAZA_CLK_OK <= FAZA_SHIFT(0);
	end case;
--	if (PH_PORT_FAZA = "000") then
--			PH_FAZA_CLK_OK <= FAZA_SHIFT(0);
--			
--	elsif (PH_PORT_FAZA = "100") then
--			PH_FAZA_CLK_OK <= not FAZA_SHIFT(0);
--			
--	elsif (PH_PORT_FAZA = "001") then
--			PH_FAZA_CLK_OK <= FAZA_SHIFT(1);
--			
--	elsif (PH_PORT_FAZA = "101") then
--			PH_FAZA_CLK_OK <= not FAZA_SHIFT(1);
--			
--	elsif (PH_PORT_FAZA = "010") then
--			PH_FAZA_CLK_OK <= FAZA_SHIFT(2);
--			
--	elsif (PH_PORT_FAZA = "110") then
--			PH_FAZA_CLK_OK <= not FAZA_SHIFT(2);
--			
--	elsif (PH_PORT_FAZA = "011") then
--			PH_FAZA_CLK_OK <= FAZA_SHIFT(3);
--			
--	elsif (PH_PORT_FAZA = "111") then
--			PH_FAZA_CLK_OK <= not FAZA_SHIFT(3);
--	
--	end if;

end process PH_SEND_PROC;

-------------------------------------------------------------------------------
-- Generate delayed phase clock for switching FAZA_DRUK signal
PH_DELAY_CLK_PROC: process (PH_F_16MHz)
begin
	if (PH_F_16MHz'event and PH_F_16MHz = '1') then
		FAZA_DLY <= FAZA_CLK_INT;
		PH_FAZA_CLK_DLY <= FAZA_DLY;
	end if;
end process PH_DELAY_CLK_PROC;
end Behavioral;

