----------------------------------------------------------------------------------
-- Company:			EBS INK-JET SYSTEMS POLAND 
-- Engineer: 		TOMASZ GRONOWICZ 
-- 
-- Create Date:    12:03:02 01/05/2007 
-- Design Name: 	 Printer control logic
-- Module Name:    DROPGENERATION - Behavioral 
-- Project Name:	 EBS7100	
-- Target Devices: XC3S200-4PQ208
-- Tool versions:  ISE 8.2.03i 
-- Description: 	Drop geneation module 
--
-- Dependencies: 
--
-- Revision:
-- 
-- Revision 0.02
-- BLOKADA signal added
-- Changes to fit conception with 2 counters in LICZ_KROPLE
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

entity DROPGENERATION is
	Generic (dropgen_width : integer := 8;
		serial_charging : boolean := true;
		EBS6500_printer : boolean := true;
		EBS6500_NC : boolean := true);
	Port (
		--Correction
		COR_ADDR : out std_logic_vector(18 downto 0);
		COR_DATA : inout std_logic_vector(15 downto 0);
		COR_NWR	 : out std_logic;
		COR_NRD	 : out std_logic;

		-- Charging
		DR_CLOCK : out std_logic;
		DR_DATA : out std_logic;
		DR_LOAD : out std_logic;

		--Ports from processor
		DR_PORTFAZA : in std_logic_vector(3 downto 0); --Control bits

		DR_KOREKCJE		: in std_logic_vector(7 downto 0);
		DR_BLOKADAPO	: in std_logic_vector(7 downto 0);
		DR_KROPKIWRZ	: in std_logic_vector(7 downto 0);
		DR_KROPKI		: in std_logic_vector(7 downto 0);

		DR_SFT16MSB 	: in std_logic_vector(15 downto 0);
		DR_TIMERCTRL 	: inout std_logic_vector(15 downto 0);

		DR_F_16MHZ : in std_logic;

		--Signals from Synt1MHz
		DR_DOT 				: in std_logic;
		DR_TAB_FAZOWANIA 	: in std_logic;

		--Signals to Synt1MHz
		DR_A_EQU_B : out std_logic;

		--Signals from ROWS_FIRE
		--DR_NHOLD		: in std_logic;
		DR_OSTATNI_BIT 	: in std_logic;
		DR_L_ILK		: in std_logic;
		DR_L_LOAD		: in std_logic;	--N_LOAD_12SFT

		--Signals to ROWS_FIRE
		DR_KONIECRZADKA		: out std_logic;
		DR_PRINT_DROP_CLK	: out std_logic; --LICZ_W_BAJT also

		--Signals from FAZA_CLK
		DR_FAZA_OK_CLK : in std_logic;

		-- Testy 25 pix - dodano dwie ponize linie
		DR_SELECTsig	: out std_logic;
		DR_CNT_END 		: out std_logic;

		--Signals to LICZ_W_BAJT
		DR_L_KROPWRZ : out std_logic

		);

end DROPGENERATION;

architecture Behavioral of DROPGENERATION is

--Generate correction address------------------------------------------------------
component COR_ADDR_GEN is
	Generic (drop_kor_width : integer := dropgen_width;
		 EBS6500 : boolean := EBS6500_printer;
		 NEW_CORRECTION : boolean := EBS6500_NC);
	Port ( 
		COR_ADDR : out  STD_LOGIC_VECTOR (18 downto 0); --Output addres

		--For ADDR11_18KOR module - addreses (18 downto 11)
		CA_KOREKCJE 		: in STD_LOGIC_VECTOR(7 downto 0);	--KOREKCJE register
		CA_DOT 				: in  STD_LOGIC;
		CA_TAB_FAZOWANIA 	: in  STD_LOGIC;
		CA_A_EQU_B :		 in  STD_LOGIC;

		-- For LICZ_KROPLE module - addreses (10 downto 5)
		CA_KROPWRZ 	: in STD_LOGIC_VECTOR(5 downto 0);	--KROPWRZ register
		CA_SELECT	: in STD_LOGIC;		-- Select register A or B (0- select A, 1- select B)
		CA_L_ILK	: in STD_LOGIC;		-- Load register

		CA_L_KROPWRZ	: out STD_LOGIC;
		CA_KONIECRZADKA	: out STD_LOGIC;

		-- For PRZESUWAJ_KROP module - addresses(4 downto 0)
		CA_KROPKI	: in STD_LOGIC_VECTOR(7 downto 0);	--KROPKI register
		CA_NLOAD	: in STD_LOGIC;		--Not shift -Load shifter - active '0' (N_LOAD_12SFT)

		CA_PRINT_DROP_CLK : in STD_LOGIC	-- Common input clock
	);
end component COR_ADDR_GEN;

--------------------------------------------------------------------------------
component CO_N_KROPLI is
	Port ( 
		CNK_COR_DATA_12_15 	: in  STD_LOGIC_VECTOR (3 downto 0);
		CNK_FAZA_OK_CLK 	: in  STD_LOGIC;

		CNK_PRINT_DROP_CLK 	: out STD_LOGIC;
		CNK_A_EQU_B 		: out STD_LOGIC
	);
end component CO_N_KROPLI;

--Serial Charge ------------------------------------------------------------------
component SERIAL_CHARGE is
	Port (
		SC_COR_DATA 		: in  STD_LOGIC_VECTOR (11 downto 0); --Correction data
		SC_DOT 				: in  STD_LOGIC;
		SC_TAB_FAZOWANIA	: in  STD_LOGIC;

		SR_CLOCK 	: out  STD_LOGIC;		--Serial clock
		SR_DATA 	: out  STD_LOGIC;		--Serial data
		SR_LOAD 	: out  STD_LOGIC;		--Load data

		SC_FAZA_CLK_OK 	: in  STD_LOGIC;		--Faza OK clock
		SC_CLK			: in STD_LOGIC			--Main 16Mhz clock
	);
end component SERIAL_CHARGE;

--Flash programming
signal COR_DATA_IN 	:	std_logic_vector(15 downto 0);
signal COR_DATA_OUT : std_logic_vector(15 downto 0);
signal COR_ADDR_BUS	: std_logic_vector(18 downto 0);

signal DR_TIMERCTRL_OUT : std_logic_vector(15 downto 0);
signal DR_TIMERCTRL_IN 	: std_logic_vector(15 downto 0);

--Interanal data from flash
signal COR_DATA_INT	: std_logic_vector(15 downto 0);
signal CA_ADDR		: std_logic_vector(18 downto 0);	--Correction address from COR_ADDR_GEN

signal A_EQU_B : std_logic;
signal PRINT_DROP_CLK : std_logic;

--signal ADDR18_11		: std_logic_vector(7 downto 0);		-- form KOREKCJE port table correction no
--signal ADDR10_5			: std_logic_vector(5 downto 0);		-- from KROPWRZ port drops in row no
--signal ADDR4_0				: std_logic_vector(4 downto 0);		-- form KROPKI port drops to print

--BLOKADAPO down counter signals
signal SELECTsig : std_logic;
signal SELECTsig_in : std_logic;
signal BLPO_CNT_REG : std_logic_vector(2 downto 0):= "111";
signal CNT_END :std_logic := '0';	--End of count (counter =0)

begin

--Correction address generation mapping---------------------------------------------
COR_ADDR_GEN_MAP: COR_ADDR_GEN
Port map
	(
		COR_ADDR => CA_ADDR,

		--For ADDR11_18KOR module - addreses (18 downto 11)
		CA_KOREKCJE => DR_KOREKCJE,
		CA_DOT 	=> DR_DOT,
		CA_TAB_FAZOWANIA => DR_TAB_FAZOWANIA,
		CA_A_EQU_B => A_EQU_B,

		-- For LICZ_KROPLE module - addreses (10 downto 5)
		CA_KROPWRZ => DR_KROPKIWRZ(5 downto 0),
		CA_SELECT => SELECTsig,
		CA_L_ILK => DR_L_ILK,
				
		CA_L_KROPWRZ => DR_L_KROPWRZ,
		CA_KONIECRZADKA => DR_KONIECRZADKA,

		-- For PRZESUWAJ_KROP module - addresses(4 downto 0)
		CA_KROPKI => DR_KROPKI,
		CA_NLOAD => DR_L_LOAD,
		
		CA_PRINT_DROP_CLK => PRINT_DROP_CLK
	);

--------------------------------------------------------------------------------
CO_N_KROPLI_MAP: CO_N_KROPLI
Port map
	(
		CNK_COR_DATA_12_15 => COR_DATA_INT(15 downto 12),
		CNK_FAZA_OK_CLK => DR_FAZA_OK_CLK,

		CNK_PRINT_DROP_CLK 	=> PRINT_DROP_CLK,
		CNK_A_EQU_B => A_EQU_B
	);
DR_A_EQU_B <= A_EQU_B;
DR_PRINT_DROP_CLK <= PRINT_DROP_CLK;

--Serial Charge-------------------------------------------------------------------
CHARGING_TRUE: if (serial_charging = true) generate
SERIAL_CHARGE_MAP: SERIAL_CHARGE
Port map
	(
		SC_COR_DATA => COR_DATA_INT(11 downto 0),
		SC_DOT => DR_DOT,
		SC_TAB_FAZOWANIA => DR_TAB_FAZOWANIA,
					
		SR_CLOCK => DR_CLOCK,
		SR_DATA => DR_DATA,
		SR_LOAD => DR_LOAD,
					
		SC_FAZA_CLK_OK 	=> DR_FAZA_OK_CLK,
		SC_CLK => DR_F_16MHZ
	);
end generate;
--------------------------------------------------------------------------------

COR_NWR	<= not DR_PORTFAZA(2);
COR_NRD	<= DR_PORTFAZA(1);

----------------------------------------------------------------------------
COR_BUS_IN : process (DR_PORTFAZA,DR_KOREKCJE,DR_SFT16MSB,DR_TIMERCTRL_IN, COR_DATA_IN,
						DR_KROPKIWRZ, DR_KROPKI, CA_ADDR)
begin

	--Wpis do flash'a
	if (DR_PORTFAZA(0)='1' and DR_PORTFAZA(3)='1') then
		COR_ADDR_BUS <= DR_KOREKCJE & DR_SFT16MSB(10 downto 0);
		COR_DATA_OUT <= DR_TIMERCTRL_IN;
		
	--Weryfikacja flash'a
	elsif (DR_PORTFAZA(0)='0' and DR_PORTFAZA(3)='1') then
		COR_ADDR_BUS <= DR_KOREKCJE & DR_SFT16MSB(10 downto 0);
		DR_TIMERCTRL_OUT <= COR_DATA_IN;
	
	--Normalna praca
	else
		COR_DATA_INT <= COR_DATA_IN;
		COR_ADDR_BUS <= CA_ADDR; --ADDR18_11 & ADDR10_5 & ADDR4_0;
	end if;
	
end process COR_BUS_IN;
COR_ADDR <= COR_ADDR_BUS;

------------------------------------------------------------------------------
--Send data on a flash data bus
COR_BUS_OUT: process (COR_DATA_OUT,DR_PORTFAZA)
begin
	if (DR_PORTFAZA(0)='1' and DR_PORTFAZA(3)='1') then
		COR_DATA <= COR_DATA_OUT;
	else
		COR_DATA <= (others => 'Z');
	end if;
end process COR_BUS_OUT;
COR_DATA_IN <= COR_DATA;

------------------------------------------------------------------------------
--Send data on a TIMERCTRL bus - flash verification
TIMER_CTRL_BUS: process (DR_TIMERCTRL_OUT, DR_PORTFAZA)
begin
	if (DR_PORTFAZA(0)='0' and DR_PORTFAZA(3)='1') then
		DR_TIMERCTRL <= DR_TIMERCTRL_OUT;
	else
		DR_TIMERCTRL <= (others => 'Z');
	end if;
end process TIMER_CTRL_BUS;
DR_TIMERCTRL_IN <= DR_TIMERCTRL;

-------------------------------------------------------------------------------
-- Down counter for BLOKADAPO register
BLOKADAPO_DC_PROC: process (PRINT_DROP_CLK)
begin
	if (PRINT_DROP_CLK'event and PRINT_DROP_CLK='1') then
		if (DR_OSTATNI_BIT='1') then
			BLPO_CNT_REG <= DR_BLOKADAPO(2 downto 0);
		else
			BLPO_CNT_REG <= BLPO_CNT_REG -1;
			
--			if (BLPO_CNT_REG="000") then
--				CNT_END <= '1';
--			elsif (BLPO_CNT_REG="001") then
--				CNT_END <= '0';
--			end if;
		end if;
	end if;
end process BLOKADAPO_DC_PROC;
CNT_END <= '1' when (BLPO_CNT_REG="000") else '0';
SELECTsig_in <= (CNT_END or SELECTsig) and not DR_OSTATNI_BIT;

--Testy 25 pix - dwie ponisze linie
DR_SELECTsig <= SELECTsig;
DR_CNT_END <= CNT_END;

--Generate SELECT signal
SELECT_PROC: process (PRINT_DROP_CLK)
begin
	if (PRINT_DROP_CLK'event and PRINT_DROP_CLK='1') then
		SELECTsig <= SELECTsig_in;
	end if;
end process SELECT_PROC;

-------------------------------------------------------------------------------
end Behavioral;

