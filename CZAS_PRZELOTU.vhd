----------------------------------------------------------------------------------
-- Company: EBS INK-JET SYSTEMS POLAND 
-- Engineer: 	TOMASZ GRONOWICZ
-- 
-- Create Date:    08:00:35 05/23/2007 
-- Design Name: 	Printer control logic
-- Module Name:    CZAS_PRZELOTU - Behavioral 
-- Project Name: 	EBS7100	
-- Target Devices: XC3S200-4PQ208
-- Tool versions:  	ISE 8.2.03i 
-- Description: 	The module counts drop passing time from gun to the gutter.
--						When signal from gutter is got the IRQ5 is generated.
--						The IRQ is generated also when the CP_TOUT signal is '1'
--
-- Dependencies: 
--
-- Revision:
--
-- Rev 0.03
-- INIFAZ_IRQ signal added - it generates IRQ when CP_INIFAZ is set and
-- defined time is reached. It has been added for generating IRQ5 when
-- printing is finished - it allows to speed up the phasing after printing
-- thus it allows to shorten the space between texts.
-- 
-- Rev 0.02
-- Bug with wrong time geneation fixed
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

entity CZAS_PRZELOTU is
	Generic (
			EBS6500_DROPPASSING_TIME : boolean := false;	-- drop passing times for EBS6500
			TIME_TST : integer := 0	-- if 1 test values for timings
			);
	Port ( 
		CP_ST1_RYNNA 		: in STD_LOGIC;	-- Signal from gutter to stop counting (falling edge)
		CP_F_1MHZ	 		: in STD_LOGIC;	-- 1MHz clock
		CP_RESET 			: in STD_LOGIC;	-- TIMERCTRL(11) 
		CP_STOP 				: in STD_LOGIC;	-- TIMERCTRL(5) -> block IRQ from ink detection, only timeout
		CP_SPEED				: in STD_LOGIC;	-- TIMERCTRL(9) - 140kHz/not 62.5kHz
		CP_TST_OUT			: in STD_LOGIC;	-- TIMERCTRL(4)
		--CP_DELAY			: in	STD_LOGIC_VECTOR(1 downto 0); --TIMERCTRL(7:6)
		CP_INIFAZ			: in STD_LOGIC;		-- Phasing init (start counting first IRQ after printend)
															--> TIMERCTRL(7), block timeout, block detection of ink
															
		CP_TST_FAZ 			: out STD_LOGIC;	-- CZAS_TMP(11) and CP_TST_OUT
		CP_TOUT				: out STD_LOGIC;	-- Timeout - if '1' the IRQ5 is generated
		CP_STATUS_STOP		: out STD_LOGIC;	-- if '1' the IRQ5 is generated
		CP_IRQ5				: out STD_LOGIC;	-- IRQ5 - active '0'; not CP_TOUT or not CP_STATUS_STOP
		CP_CZASPRZELOTU 	: out STD_LOGIC_VECTOR (13 downto 0)
		);
end CZAS_PRZELOTU;

architecture Behavioral of CZAS_PRZELOTU is

signal CZAS_TMP 	: std_logic_vector(13 downto 0);	--Temporary czasprzelotu counter
signal CLK_INT 	: std_logic;							--Internal clock

signal N_BL_POCZ 		: std_logic;		--N_BLOKADA_POCZATKU
signal N_BL_POCZ_i 	: std_logic;

signal TOUT_INT 				: std_logic; -- Internal TimeOUT
signal STATUS_STOP_INT 		: std_logic; -- Internal STATUS_STOP
signal STATUS_STOP_INT_i 	: std_logic;
signal F_1MHZ 					: std_logic; -- Additonal clock for counter

signal INIFAZ_IRQ : std_logic; 	-- Signal for generating IRQ when phasing
											-- has been started
begin

-- Count time --------------------------------------------------------------------
F_1MHZ <= CP_F_1MHZ when (TOUT_INT ='0' and STATUS_STOP_INT_i ='0') else '0';

CNT_TIME_PROC: process (F_1MHZ,CP_RESET)
begin

	if (CP_RESET = '1') then
		CZAS_TMP <= (others => '0');

	elsif (F_1MHZ'event and F_1MHZ='1') then
	
		CZAS_TMP <= CZAS_TMP+1;

	end if;

end process CNT_TIME_PROC;

-- EBS7100
TOUT_INT_TST_1FALSE:
	if (TIME_TST = 1 and EBS6500_DROPPASSING_TIME = false) generate
		--TOUT_INT <= CZAS_TMP(11) and CZAS_TMP(7) when (CP_INIFAZ = '0') else '0';-- Timeout 2.13ms (2.176)
		TOUT_INT <= CZAS_TMP(11) and CZAS_TMP(9);	--Timeout 2.5ms
end generate;

TOUT_INT_TST_0FALSE:
	if (TIME_TST = 0 and EBS6500_DROPPASSING_TIME = false) generate
		TOUT_INT <= CZAS_TMP(10) and CZAS_TMP(9) and CZAS_TMP(6) when (CP_INIFAZ = '0') else '0';-- Timeout 1.6ms
end generate;

--EBS6500
TOUT_INT_TST_1TRUE:
	if (TIME_TST = 1 and EBS6500_DROPPASSING_TIME = true) generate
		TOUT_INT <= CZAS_TMP(11) and CZAS_TMP(9);	--Timeout 2.5ms
end generate;

TOUT_INT_TST_0TRUE:
	if (TIME_TST = 0 and EBS6500_DROPPASSING_TIME = true) generate
		TOUT_INT <= CZAS_TMP(11) and CZAS_TMP(10) and CZAS_TMP(9) when (CP_INIFAZ = '0') else '0';-- Timeout 3.5ms
end generate;

--TOUT_INT <= CZAS_TMP(11) when (CP_INIFAZ = '0') else '0';-- Timeout 2ms -- and CZAS_TMP(9);	--Timeout 2.5ms
--TOUT_INT <= CZAS_TMP(11) and CZAS_TMP(10) and CZAS_TMP(9);	--Timeout 3.5ms
--TOUT_INT <= CZAS_TMP(7) and CZAS_TMP(6) and CZAS_TMP(5);

-- EBS7100
N_BL_POCZ_TST_1FALSE:
	if (TIME_TST = 1 and EBS6500_DROPPASSING_TIME = false) generate
		--N_BL_POCZ_i <= CZAS_TMP(11) when (CP_SPEED='0') else CZAS_TMP(10) and CZAS_TMP(8); --2ms lub 1.2ms
		N_BL_POCZ_i <= CZAS_TMP(11) and CZAS_TMP(8) when (CP_SPEED='0') else CZAS_TMP(10) and CZAS_TMP(8) and CZAS_TMP(7); --2.3ms lub 1.4ms
end generate;

N_BL_POCZ_TST_0FALSE:
	if (TIME_TST = 0 and EBS6500_DROPPASSING_TIME = false) generate
		N_BL_POCZ_i <= CZAS_TMP(10) and CZAS_TMP(9) when (CP_SPEED='0') else CZAS_TMP(9) and CZAS_TMP(8) and CZAS_TMP(7); --1.5ms lub 0.9ms
end generate;

-- EBS6500
N_BL_POCZ_TST_1TRUE:
	if (TIME_TST = 1 and EBS6500_DROPPASSING_TIME = true) generate
		--N_BL_POCZ_i <= CZAS_TMP(11) when (CP_SPEED='0') else CZAS_TMP(10) and CZAS_TMP(8); --2ms lub 1.2ms
		N_BL_POCZ_i <= CZAS_TMP(11) and CZAS_TMP(8) when (CP_SPEED='0') else CZAS_TMP(10) and CZAS_TMP(8) and CZAS_TMP(7); --2.3ms lub 1.4ms
end generate;

N_BL_POCZ_TST_0TRUE:
	if (TIME_TST = 0 and EBS6500_DROPPASSING_TIME = true) generate
		N_BL_POCZ_i <= CZAS_TMP(10) and CZAS_TMP(9) when (CP_SPEED='0') else CZAS_TMP(10); --1.5ms lub 1ms
end generate;

--N_BL_POCZ_i <= CZAS_TMP(10) and CZAS_TMP(9) when (CP_SPEED='0') else CZAS_TMP(10); --1.5ms lub 1ms
--N_BL_POCZ <= CZAS_TMP(6) and CZAS_TMP(5) when (CP_SPEED='0') else CZAS_TMP(6);

N_BL_POCZ <= N_BL_POCZ_i when (CP_INIFAZ = '0') else '0';

-- EBS7100
INIFAZ_IRQ_TST_1FALSE:
	if (TIME_TST = 1 and EBS6500_DROPPASSING_TIME = false) generate
		--INIFAZ_IRQ <= CZAS_TMP(11) and CZAS_TMP(10) and CZAS_TMP(9) and CZAS_TMP(7) when (CP_INIFAZ='1') else '0'; -- 3.7ms
		INIFAZ_IRQ <= CZAS_TMP(12) and CZAS_TMP(8) and CZAS_TMP(6) when (CP_INIFAZ='1') else '0'; -- 4.4ms
end generate;

INIFAZ_IRQ_TST_0FALSE:
	if (TIME_TST = 0 and EBS6500_DROPPASSING_TIME = false) generate
		INIFAZ_IRQ <= CZAS_TMP(11) and CZAS_TMP(9) and CZAS_TMP(8) when (CP_INIFAZ='1') else '0'; -- 2.8ms
end generate;

-- EBS6500
INIFAZ_IRQ_TST_1TRUE:
	if (TIME_TST = 1 and EBS6500_DROPPASSING_TIME = true) generate
		--INIFAZ_IRQ <= CZAS_TMP(11) and CZAS_TMP(10) and CZAS_TMP(9) and CZAS_TMP(7) when (CP_INIFAZ='1') else '0'; -- 3.7ms
		INIFAZ_IRQ <= CZAS_TMP(12) and CZAS_TMP(8) and CZAS_TMP(6) when (CP_INIFAZ='1') else '0'; -- 4.4ms
end generate;

INIFAZ_IRQ_TST_0TRUE:
	if (TIME_TST = 0 and EBS6500_DROPPASSING_TIME = true) generate
		INIFAZ_IRQ <= CZAS_TMP(11) and CZAS_TMP(9) and CZAS_TMP(8) when (CP_INIFAZ='1') else '0'; -- 2.8ms
end generate;

--INIFAZ_IRQ <= CZAS_TMP(10) and CZAS_TMP(11) when (CP_INIFAZ='1') else '0'; -- 3ms
--INIFAZ_IRQ <= CZAS_TMP(11) and CZAS_TMP(9) when (CP_INIFAZ='1') else '0'; -- 2.5ms

--Start counting time --------------------------------------------------------------
ST_CNT_TIME_PROC: process(CP_F_1MHZ)
begin

	if (CP_RESET='1') then
		STATUS_STOP_INT <= '0';

	elsif (CP_F_1MHZ'event and CP_F_1MHZ='1') then
		STATUS_STOP_INT <= N_BL_POCZ or STATUS_STOP_INT;

	end if;

end process ST_CNT_TIME_PROC;

--Generate IRQ-------------------------------------------------------------------
GEN_IRQ_PROC : process(CP_ST1_RYNNA,CP_RESET)
begin

	if (CP_RESET = '1') then
		STATUS_STOP_INT_i <= '0';

	elsif (CP_ST1_RYNNA'event and CP_ST1_RYNNA='0') then

		if (CP_STOP ='0' and CP_INIFAZ = '0') then
			STATUS_STOP_INT_i<= STATUS_STOP_INT;
		end if;

	end if;

end process GEN_IRQ_PROC;

--Set outputs--------------------------------------------------------------------
CP_CZASPRZELOTU <= CZAS_TMP;
CP_TOUT <= TOUT_INT or INIFAZ_IRQ;
CP_STATUS_STOP <= STATUS_STOP_INT_i;--STATUS_STOP_DEL;
CP_IRQ5 <=  not(TOUT_INT or STATUS_STOP_INT_i or INIFAZ_IRQ);
--CP_IRQ5 <=  not(TOUT_INT or STATUS_STOP_INT_i);

CP_TST_FAZ <= CZAS_TMP(11) and CP_TST_OUT;

end Behavioral;

