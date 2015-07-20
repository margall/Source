----------------------------------------------------------------------------------
-- Company:			EBS INK-JET SYSTEMS POLAND 
-- Engineer: 		TOMASZ GRONOWICZ
-- 
-- Create Date:		13:18:48 12/04/2006 
-- Design Name: 	 Printer control logic
-- Module Name:		Main - Behavioral 
-- Project Name: 	EBS6500
-- Target Devices: XC3S200-4PQ208
-- Tool versions:	ISE 10.1.3i
-- Description: 		Main module
--
-- Dependencies: 	IOREG16, IOREG8, SPI_INTEFACE, FOTOC, DROPGENERATION
--
-- Revision:
--
-- Rev. 4.51
-- 2014-06-04
-- Port SHAFT_B (SHAFTB) added for including conveyer direction
-- Output port SH_DIR - encoder direction for KROPWRZ[7]
--
-- Rev. 4.50
-- 2014-05-09
-- Fixed bug with USB controler.
-- There was no contact with USB controler in EBS6600 printer. Processor always read data from USB as zeros.
-- The reason was that in process "SWITCH" data on PROC_DATA_OUT was set zeros during read cycle, and shold
-- "free" data bus - data comes from USB controler.
-- Bug was fixed in process "PROC_DATA_OUT_BUS" by ignoring read cycle for signal CS_USB_DATA = '1'
--
-- Rev 2.01
-- 2014-04-02
-- Changes in phasing during printing implementation
-- For fast, close to max. speed printing when one row is as fast as possbile
-- generated after another - the last drop in the second row was cut off.
-- It was caused by signal sSTART_DELAY which was not cancelled properly (with sFAZA_DRUK)
-- Now signal is cancelled by inermediate signal sFAZA_DRUK_IN
-- 
-- Rev. 2.00
-- 2014-01-10
-- Implemented phasing during printing.
-- Register TIMERDODEL changed to FAZATEST_X
-- Module FAZA_DRUK_MOD added
--
-- Rev 1.02
-- Signals for RKM4 board tests connected to the ST6 connector.
-- ST6_TEST = 0 option
--
-- Rev. 1.01
-- USB bug corrected
--
-- Rev 1.00
-- First revision for EBS6500 printer
--
-- Rev. 0.04
-- For board PP7K-3C and next the parallel comunication for USB chip
-- has been implemented. 
-- Xilinx generates signals /RD WR and collects RXE, TXE signals for this chip
-- 
-- Revision 0.03
-- Changes to fit conception with 2 counters in LICZ_KROPLE
-- BLOKADA register added
--
-- Revision 0.02
-- Problems with correction flash/ram programming solved
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

entity MAIN_6500 is
	Generic (ST6_TST : integer := 2;	-- if 1 test signals for ST6 connector
		--EBS6500_dropgen_width : integer := 5;	-- 5 drops used in correction
		EBS6500_dropgen_width : integer := 8;	-- 8 drops used in correction
		EBS6500_serial_charging : boolean := false;		--  do not use serial charging interface
		EBS6500_droppassing_time : boolean := true;	-- drop passing times (for CZAS_PRZELOTU)
		EBS6500 : boolean := true;	-- printer type (true for EBS6500)
		EBS6500_NewCorrection : boolean := true;	-- New correction options
		EBS6500_PhDurPrinting : boolean := true		-- Phasing during printing
		);
	Port (
			--Processor bus
			PROC_ADDR	: in std_logic_vector(15 downto 0);
			PROC_DATA	: inout std_logic_vector(15 downto 0);
			
			PROC_NCSEL	: in std_logic;	-- /CS8
			PROC_R_NW	: in std_logic;	-- R/W
			PROC_NDS		: in std_logic;	-- /DS
				
			PROC_16MHZ	: in std_logic;	-- 16MHz
			PROC_GEN		: in std_logic;
			PROC_SFTCLK	: in std_logic;
				
			-- Interrupts
			PROC_NIRQ5		: out std_logic;
			PROC_NIRQ6		: out std_logic;
				
			-- SPI Interface
			PROC_NSS	: in std_logic;	--PCS0
			PROC_NPSC3	: in std_logic;	--PCS3
			PROC_MOSI	: in std_logic;	--SPI Master Output Slave Input
			PROC_MISO	: out std_logic;	--SPI Master Input Slave Output
			PROC_SCK	: in std_logic;	--SPI clock
				
			MOSI		: out std_logic;	-- SPI output
			MISO		: in std_logic;	-- SPI input
			SCK			: out std_logic;	-- SPI output clock
			--SS1			: out std_logic;	-- SPI CS1 - XDS memory card
			SS2			: out std_logic;	-- SPI CS2 - Extenral connector ST20  (e.g. WIZNET CS)
			SS3			: out std_logic;	-- SPI CS3 - Ink programming
			--SS4		: out std_logic;	-- SPI CS4 - Breaking (Braking spi clk -RSCLK)
				
			--USB
			SS1			: in std_logic; -- TXE status
			--SS1			: out std_logic;	-- for PP7K-3B and previous
			PGCK3		: in std_logic; -- RXF status
			--PGCK3		: out std_logic;	--for PP7K-3B and previous
			NDATA_REQ	: out std_logic; --USB_WR
			NDATA_ACK	: out std_logic; --USB_RD
			--NDATA_ACK	: in std_logic; --for PP7K-3B and previous
			
			--Ethernet EM202
			MD			: out std_logic;	-- Working mode
			RSTI		: out std_logic;	-- Output reset
			SPEC2RTS	: out std_logic;	-- RTS
			SPEC2CTS	: in std_logic;		-- CTS
			
			-- Programing bus
			--CCLK1		: in 	std_logic; (NRLOAD)
			DIN			: in std_logic;
			--DIN1		: in	std_logic; (NRCLR)
			--N_IRQ7	: out std_logic; (INT_USB)
			
			--Breaking voltage
			NRLOAD	: out std_logic;
			NRCLR	: out std_logic;
			RSCLK	: out std_logic;
				
			-- Corrections
			COR_ADDR	: out std_logic_vector(18 downto 0);
			COR_DATA	: inout	std_logic_vector(15 downto 0);
			COR_NWR		: out std_logic;
			COR_NRD		: out std_logic;
				
			--Phasing
			ST1_RYN		: in std_logic;		-- Phase signal
			
			--Photodetector
			FOTO			: in std_logic;
			STAN_FOT		: out std_logic;	-- STAN_FOT_Z
			FOT_ACK		: out std_logic;	-- PORT_STER(2)
				
			--Encoder
			SHAFT_IN	: in std_logic;
			SHAFTB		: in std_logic;		-- Encoder implementation
			
			--Fans
			FANI		: in std_logic;		-- Fan encoder input - not used
			FANO		: out std_logic;	-- Fan control (on/off)
				
			-- Stroboscopes
			STER_STB	: out std_logic;	-- Stroboscope LED
			EXT_STROB	: out std_logic;	-- PORT_STER(3)
				
			--Counters control
			CNT_END		: out std_logic; 	-- END_OF_COUNT  PORT_STER(4)
			CNT_CLR		: in std_logic;		-- Clear counter - ZER_LICZ TIMERSTATUS(15)
			CNT_GATE	: in std_logic;		-- Gate clock - TIMERSTATUS(13)
				
			ROBOT		: in std_logic;		-- ZAPAS_WE0

			STROB_KOD0	: in std_logic;		-- TIMERSTATUS(14)
			SFT_OUT		: out std_logic;	-- Free - not used
			SFT_IN		: in std_logic;		-- SFT0_IN - free not used
			
			CLK_WY0		: out std_logic;	-- PROC_SFTCLK
			ZAPAS_WY0	: out std_logic;	-- IB_A0-ZWY0 - INTERFACE_E(0)
			RESOUTSF	: out std_logic;	-- IB_A4-ROSF - INTEFACE_E(4)
			LADEXSF		: out std_logic;	-- IB_A7-LESF -  INTERFACE_E(7)
				
			PILA_GER	: out std_logic;	-- PILA_GERODUR
				
			N_RESET		: in std_logic;		-- /RESET
			
			INT_USB		: out std_logic;	-- former USB interrupt (now IRQ7)
			N_INIT		: out std_logic;	-- IRQ4 signal (for RES_LICZNIKI ==3) - not used yet
			
			--Code switch
			PKR_K	: in std_logic;	-- Direction
			PKR_S	: in std_logic; -- Strobe
			
			PKR_B	: in std_logic_vector(3 downto 0);
			--PKR_B0 : in std_logic;
			--PKR_B1 : in std_logic;
			--PKR_B2 : in std_logic;
			--PKR_B3 : in std_logic;
			
			PKR_C	: in std_logic_vector(3 downto 0);
			--PKR_C0 : in std_logic;
			--PKR_C1 : in std_logic;
			--PKR_C2 : in std_logic;
			--PKR_C3 : in std_logic;
			
			PKR_D	: in std_logic_vector(3 downto 0)
			--PKR_D0 : in std_logic;
			--PKR_D1 : in std_logic;
			--PKR_D2 : in std_logic;
			--PKR_D3 : in std_logic
		);
end MAIN_6500;

architecture Behavioral of MAIN_6500 is

-- Registers --------------------------------------------------------------------------
constant KROPKI_ADDR				: std_logic_vector(15 downto 0):= "0000000000000010" ;
constant PORT_STER_ADDR			: std_logic_vector(15 downto 0):= "0000000000000100" ;
constant KROPWRZ_ADDR			: std_logic_vector(15 downto 0):= "0000000000001000" ;
constant PORTDRUK_ADDR			: std_logic_vector(15 downto 0):= "0000000000010000" ;
constant STERDRUK_ADDR			: std_logic_vector(15 downto 0):= "0000000000100000" ;
constant PORTFAZA_ADDR			: std_logic_vector(15 downto 0):= "0000000001000000" ;
constant KOREKCJE_ADDR			: std_logic_vector(15 downto 0):= "0000000010000000" ;
constant BLOKADAPO_ADDR			: std_logic_vector(15 downto 0):= "0000000010000010" ;
constant STER_SHAFT_ADDR		: std_logic_vector(15 downto 0):= "0000000100000000" ;
constant STER_SH_MUL_ADDR		: std_logic_vector(15 downto 0):= "0000000100000010" ;
constant TIMERCTRL_ADDR			: std_logic_vector(15 downto 0):= "0000001000000000" ;
constant FAZATEST_X_ADDR		: std_logic_vector(15 downto 0):= "0000010000000000" ;
constant TIMERRYNNA_ADDR		: std_logic_vector(15 downto 0):= "0000100000000000" ;
constant TIMERSTATUS_ADDR		: std_logic_vector(15 downto 0):= "0001000000000000" ;
constant SHIFT16BIT_ADDR		: std_logic_vector(15 downto 0):= "0010000000000000" ;
constant CZKROPLISTER_ADDR 	: std_logic_vector(15 downto 0):= "0100000000000000" ;
constant INTERFACE_E_ADDR		: std_logic_vector(15 downto 0):= "1000000000000000" ;
constant PORT_SW1_ADDR 			: std_logic_vector(15 downto 0):= "0010000000000010" ;
constant SPI_CS_ADDR		 		: std_logic_vector(15 downto 0):= "0010000000000100" ;
constant USB_DATA_ADDR			: std_logic_vector(15 downto 0):= "0010000000001001" ;
constant USB_STAT_ADDR			: std_logic_vector(15 downto 0):= "0010000000001011" ;

signal PROC_ADDR_M			: std_logic_vector(15 downto 0);	--Processor address with bit 0 set always to 0

signal CS_KROPKI 			: STD_LOGIC;
signal KROPKI				: STD_LOGIC_VECTOR (7 downto 0);
signal CS_PORT_STER 		: STD_LOGIC;
signal PORT_STER			: std_logic_vector (7 downto 0);
signal CS_KROPWRZ 			: STD_LOGIC;
signal KROPWRZ				: std_logic_vector (7 downto 0);
signal CS_PORTDRUK 			: STD_LOGIC;
signal PORTDRUK				: std_logic_vector (7 downto 0);
signal CS_STERDRUK 			: STD_LOGIC;
signal STERDRUK				: std_logic_vector (7 downto 0);
signal CS_PORTFAZA 			: STD_LOGIC;
signal PORTFAZA				: std_logic_vector (7 downto 0);
signal CS_KOREKCJE 			: STD_LOGIC;
signal KOREKCJE				: std_logic_vector (7 downto 0);
signal CS_STER_SHAFT 		: STD_LOGIC;
signal STER_SHAFT			: std_logic_vector (7 downto 0);
signal CS_STER_SH_MUL 		: STD_LOGIC;
signal STER_SH_MUL			: std_logic_vector (7 downto 0);
signal BLOKADAPO			: std_logic_vector (7 downto 0);
signal CS_BLOKADAPO			: STD_LOGIC;
signal CS_TIMERCTRL 		: STD_LOGIC;
signal RNW_TIMERCTRL 		: STD_LOGIC;
signal TIMERCTRL			: std_logic_vector (15 downto 0);
signal TIMERCTRL_COR		: std_logic_vector (15 downto 0);
signal CS_TIMERCTRL_COR		: STD_LOGIC;
signal TIMERCTRL_COR_1		: std_logic_vector (15 downto 0);
signal CS_FAZATEST_X 		: STD_LOGIC;
signal FAZATEST_X			: std_logic_vector (7 downto 0);
signal CS_TIMERRYNNA 		: STD_LOGIC;
signal TIMERRYNNA			: std_logic_vector (15 downto 0);
signal CS_TIMERSTATUS 		: STD_LOGIC;
signal TIMERSTATUS			: std_logic_vector (15 downto 0);
signal TIMERSTATUS_IN		: std_logic_vector (15 downto 0);
signal CS_SHIFT16BIT 		: STD_LOGIC;
signal SHIFT16BIT			: std_logic_vector (15 downto 0);
signal CS_CZASKROPLISTER	: STD_LOGIC;
signal CZASKROPLISTER		: std_logic_vector (15 downto 0);
signal CS_INTERFACE_E	 	: STD_LOGIC;
signal INTERFACE_E			: std_logic_vector (7 downto 0);
signal CS_PORT_SW 		 	: STD_LOGIC;
signal PORT_SW				: std_logic_vector (15 downto 0);
signal PORT_SW_IN			: std_logic_vector (15 downto 0);
signal CS_SPI_CS	 		: STD_LOGIC;
signal SPI_CS				: std_logic_vector (7 downto 0);
signal CS_USB_DATA			: std_logic;
signal USB_DATA				: std_logic_vector (1 downto 0) := "10";
signal USB_STAT				: std_logic_vector (1 downto 0);

--I/O registers-------------------------------------------------------------------
component IOREG8 is
Port (
		DATA_IN		: in	STD_LOGIC_VECTOR(7 downto 0);
		DATA_OUT	: out 	STD_LOGIC_VECTOR(7 downto 0);
		CS 			: in	STD_LOGIC;
		RNW			: in	STD_LOGIC;
		RST 		: in	STD_LOGIC
	);
end component IOREG8;
				
component IOREG16 is
Port ( 
		DATA_IN		: in	STD_LOGIC_VECTOR(15 downto 0);
		DATA_OUT	: out	STD_LOGIC_VECTOR(15 downto 0);
		CS 			: in	STD_LOGIC;
		RNW			: in 	STD_LOGIC;
		RST 		: in	STD_LOGIC
	);
end component IOREG16;
				
--SPI INTERFACE -----------------------------------------------------------------
component SPI_INTERFACE is
Port ( 
		SPI_SCK_IN 		: in  STD_LOGIC;
		SPI_SCK_OUT 	: out STD_LOGIC;
		SPI_MISO_IN 	: in  STD_LOGIC;
		SPI_MISO_OUT 	: out STD_LOGIC;
		SPI_MOSI_IN 	: in  STD_LOGIC;
		SPI_MOSI_OUT 	: out STD_LOGIC;
		SPI_NSS			: in STD_LOGIC;
		SPI_CS_IN 		: in  STD_LOGIC_VECTOR (7 downto 0);
		SPI_CS_OUT 		: out  STD_LOGIC_VECTOR (7 downto 0)
	);
end component SPI_INTERFACE;

signal SPI_SS : std_logic_vector(7 downto 0);

-- DROP GENERATION -------------------------------------------------------------
component DROPGENERATION is
Generic (dropgen_width : integer := EBS6500_dropgen_width;
			serial_charging : boolean := EBS6500_serial_charging;
			EBS6500_printer : boolean := EBS6500;
			EBS6500_NC : boolean := EBS6500_NewCorrection);
Port (
		--Correction
		COR_ADDR : out 	std_logic_vector(18 downto 0);
		COR_DATA : inout	std_logic_vector(15 downto 0);
		COR_NWR	 : out	std_logic;
		COR_NRD	 : out	std_logic;

		-- Charging
		DR_CLOCK	: out std_logic;
		DR_DATA		: out std_logic;
		DR_LOAD		: out std_logic;
						
		--Ports from processor
		DR_PORTFAZA	 : in std_logic_vector(3 downto 0); --Control bits 4,5,6,7
						
		DR_KOREKCJE	 : in std_logic_vector(7 downto 0);
		DR_BLOKADAPO : in std_logic_vector(7 downto 0);
		DR_KROPKIWRZ : in std_logic_vector(7 downto 0);
		DR_KROPKI	 : in std_logic_vector(7 downto 0);
						
		DR_SFT16MSB  : in std_logic_vector(15 downto 0);
		DR_TIMERCTRL : inout std_logic_vector(15 downto 0);

		DR_F_16MHZ	: in std_logic;

		--Signals from Synt1MHz
		DR_DOT	: in std_logic;
		DR_TAB_FAZOWANIA : in std_logic;

		--Signals to Synt1MHz
		DR_A_EQU_B	: out std_logic;
					
		--Signals from ROWS_FIRE
		DR_OSTATNI_BIT	: in std_logic;
		DR_L_ILK		: in std_logic;
		DR_L_LOAD		: in std_logic;	--N_LOAD_12SFT
						
		--Signals to ROWS_FIRE
		DR_KONIECRZADKA		: out std_logic;
		DR_PRINT_DROP_CLK	: out std_logic; --LICZ_W_BAJT also

		--Signals from FAZA_CLK
		DR_FAZA_OK_CLK 	: in std_logic;

		--Signals to LICZ_W_BAJT
		DR_L_KROPWRZ : out std_logic
	);
end component DROPGENERATION;

--Synt1MHZ---------------------------------------------------------------------
component Synt1MHz is
Port ( 
		--Inputs for generation 1MHz clock
		S1M_F_16MHz : in STD_LOGIC; -- 16Mhz or 25 Mhz input clock
		S1M_CLR 	: in STD_LOGIC;	-- Clear phase counter - TIMERCTRL(12)
		S1M_CTRL	: in STD_LOGIC;	-- Switch between 16MHz(0) and 25MHz(1) clock - TIMERCTRL(8)
				
        S1M_F_1MHz 	: out STD_LOGIC;	-- Output 1MHz clock
		S1M_F_2MHz 	: out STD_LOGIC;	-- Output 2MHz clock - for stroboscope

		--Inputs for DOT and TAB_FAZOWANIA
		S1M_KOREKCJE	: in STD_LOGIC_VECTOR(7 downto 0);
		S1M_A_EQU_B		: in STD_LOGIC;

		S1M_FAZA_OK_CLK	: in STD_LOGIC;
		S1M_NEG_PHASE	: in STD_LOGIC;		-- STERDRUK(5)
				
		S1M_FAZA_NO		: in STD_LOGIC_VECTOR(1 downto 0); --Phase time choose for phasing (TIMERCTRL(1:0))
		S1M_FAZA_START	: in STD_LOGIC; --Begin of phase time (TIMERCTRL(12) - active low

		S1M_TAB_FAZOWANIA	: out STD_LOGIC;
		S1M_DOT				: out STD_LOGIC
	);
end component Synt1MHz;

--FAZA_CLK---------------------------------------------------------------------
component FAZA_CLK is
Port ( 
		PH_F_16MHz 		: in  STD_LOGIC;		-- 16MHz clock
		PH_CZAS_KROPLI 	: in  STD_LOGIC_VECTOR (7 downto 0);	-- drop time - default 16 us
		PH_PORT_FAZA 	: in  STD_LOGIC_VECTOR (2 downto 0);	-- Phase no: b0-1 - phase b2- neg phase
						
		PH_FAZA_CLK_OK	: out STD_LOGIC;	-- Phase clock signal to generate drops
		PH_DROP_FREQ	: out STD_LOGIC;	-- Drop frequency signal
		PH_FAZA_CLK_DLY	: out STD_LOGIC;	-- Delayed phase clock for switching FAZA_DRUK signal
		
		--Controll signals and external drop frequency
		PH_FAZA_CLK_CTRL	: out STD_LOGIC; -- Phase clock signal - controll
		PH_DROP_EXT_CTRL 	: in STD_LOGIC;	 -- Drop freq controll - '1' - external drop frequency
		PH_DROP_EXT_FREQ 	: in STD_LOGIC	 -- External drop frequency signal
	);
end component FAZA_CLK;

--LICZ_W_BAJT------------------------------------------------------------------
component LICZ_W_BAJT is
Port ( 
		LW_STERDRUK_2_0 	: in STD_LOGIC_VECTOR (2 downto 0); -- No of important drops in byte
    	LW_PRINT_DROP_CLK	: in STD_LOGIC;	-- PRINT_DROP_CLK
    			
        LW_L_KROPWRZ 	: in STD_LOGIC;	-- Reload counter - L_KROPWRZ
        LW_NHOLD 		: in STD_LOGIC;	--Hold on counting

        LW_KONIEC_BAJTU : out STD_LOGIC	--Output signal
	);
end component LICZ_W_BAJT;

--ROWS_FIRE--------------------------------------------------------------------
component ROWS_FIRE is
Port ( 
		RF_BLOK_RZAD		: in std_logic; 	-- STERDRUK(3)
		RF_EN_OVR			: in std_logic; 	-- CZAS_KROPLI_STER(10)
		RF_KONIEC_BAJTU		: in std_logic; 	-- from LICZ_W_BAJT
		RF_KONIEC_RZADKA	: in std_logic; 	-- from LICZ_KROPLE
		RF_LAD_KROPKI		: in std_logic; 	-- MC_ADDR(KROPKI(b1)) and NOT_MC_CS and NOT_RNW
		RF_MAX_GAZ			: in std_logic; 	-- PORTDRUK(5)
		RF_OVR_CLR			: in std_logic; 	-- CZAS_KROPLI_STER(9)
		RF_PRINT_DROP_CLK	: in std_logic; 	-- form CO_N_KROPLI
		RF_ROWS_S			: in std_logic; 	-- ENCODER or GENERATOR signal (from SHAFT)
		RF_START_B			: in std_logic; 	-- PORT_DRUK(4)
				
		RF_IRQ_R			: out std_logic; 	-- IRQ6 (together with FOTO signal)
		RF_LAD_L_ILK		: out std_logic; 	-- to LICZ_KROPLE (COR_ADDR_GEN)
		RF_OSTATNI_BIT 		: out std_logic; 	-- to LICZ_KROPLE (COR_ADDR_GEN)
		RF_N_LOAD_12SFT		: out std_logic; 	-- to PRZESUWAJ KROPLE (COR_ADDR_GEN)
		RF_OVERUN			: out std_logic; 	-- TIMERSTATUS(11)
		RF_START1			: out std_logic;	-- ready for Photo - to FOTOC
		RF_DRUK				: out std_logic;	-- printing in progress
		RF_RZADEK_N_WOLNY	: out std_logic		-- for phasing during printing 
	);
end component ROWS_FIRE;

 --MICROSCOP-------------------------------------------------------------------
component MIKROSKOP is
Port (
		MI_DROP_FREQ	: in std_logic;
		MI_FAZA_OK		: in std_logic;
		MI_F_2MHZ		: in std_logic;
		MI_F_16MHZ		: in std_logic;
		MI_LD_KROPKIWRZ : in std_logic;
				
		MI_ROWS			: in std_logic; --ROWS not DROPS - PORTSTER(5)
				
		MI_DELAY		: in std_logic;  --Delay rows - TIMERCTRL(4)
		MI_IN_DELAY		: in std_logic;	--Increase delay - TIMERCTRL(3)
		MI_STRBSKP_OUT	: out std_logic
	);
end component MIKROSKOP;

-- PHOTODETECTOR ------------------------------------------------------------
component FOTOC is
Port ( 
		FOTOC_IN 	: in STD_LOGIC;
        FOTOC_EDGE 	: in STD_LOGIC; -- Edge selection - PORTDRUK(3)
		FOTOC_BLOCK	: in STD_LOGIC; -- Block Photodetector - STERDRUK(4)
					 
		FOTOC_IRQ 	: out STD_LOGIC;	--IRQ from Photodetector - active HIGH
		FOTOC_STAT	: out STD_LOGIC;
					 
		FOTOC_F_16MHZ : in STD_LOGIC
	);
end component FOTOC;

--SHAFT------------------------------------------------------------------------
component SHAFT is
Port ( 
		SH_ROWS_S	: out std_logic;	--Start printing a row
		SH_DIR		: out std_logic;	-- Encoder direction
		
		--Encoder signals
		SH_CO_POL_TAKT	: in std_logic; --PORT_STER(6)

		SH_START_B		: in std_logic; --Enable encoder - '1' - enabled - PORTDRUK(4)
		SH_CLR_FIRE		: in std_logic;	--Clear fire signal
		SH_STERSHAFT	: in std_logic_vector (7 downto 0);	--STER_SHAFT
		SH_SHAFT_IN		: in std_logic; --Encoder input
		SH_SHAFT_B		: in std_logic;	-- Encoder input bis
		
		SH_SHFT_NGEN 	: in std_logic; 	-- 1 - encoder 0 - generator - PORTDRUK(0)
					
		--Generator signals
		SH_GEN			: in std_logic;		-- Internal generator printing
		SH_F_16MHZ		: in std_logic;
		
		-- Frequency multiplier settings signal
		SH_FREQ_MUL		: in  std_logic_vector (7 downto 0); -- DLL (MULTIPLIER FREQUENCY * SH_FREQ_MUL(3 downto 0))	
		N_RESET				: in  std_logic
	);
end component SHAFT;
signal SHAFT_DIRECTION :std_logic;

--CZAS_PRZELOTU----------------------------------------------------------------
component CZAS_PRZELOTU is
Generic (EBS6500_DROPPASSING_TIME : boolean := EBS6500_droppassing_time;
			TIME_TST : integer := 0
			);
Port ( 
		CP_ST1_RYNNA	: in STD_LOGIC;	-- Signal from gutter to stop counting
		CP_F_1MHZ		: in STD_LOGIC;	-- 1MHz clock
		CP_RESET 		: in STD_LOGIC;	-- TIMERCTRL(11) + FAZA_DRUK
		CP_STOP 		: in STD_LOGIC;	-- TIMERCTRL(5)
		CP_SPEED 		: in STD_LOGIC;	--TIMERCTRL(9) - 140kHz/not 62.5kHz
		CP_TST_OUT		: in STD_LOGIC;	--TIMERCTRL(4)
		--CP_DELAY		: in STD_LOGIC_VECTOR(1 downto 0); --TIMERCTRL(7:6)
		CP_INIFAZ		: in STD_LOGIC;		-- Phasing init (start counting first IRQ after printend)
																						-- TIMERCTRL(7)
		CP_TST_FAZ 		: out STD_LOGIC;
		CP_TOUT			: out STD_LOGIC;	-- Timeout - if '1' the IRQ5 is generated
		CP_STATUS_STOP	: out STD_LOGIC;	-- if '1' the IRQ5 is generated
		CP_IRQ5			: out STD_LOGIC;	--IRQ5 - active '0'; not CP_TOUT or not CP_STATUS_STOP
		CP_CZASPRZELOTU : out STD_LOGIC_VECTOR (13 downto 0)
	);
end component CZAS_PRZELOTU;
signal sCZAS_PRZELOTU_RESET : std_logic;

--BREAKING VOLTAGE-------------------------------------------------------------
component BREAK_VOL is
Port ( 
		BR_DROP_CLK : in STD_LOGIC;
		BR_F16MHZ 	: in STD_LOGIC;
		BR_SPI_CS 	: in STD_LOGIC;
		BR_SPI_SCK 	: in STD_LOGIC;
						
		BR_NCLR		: out STD_LOGIC;
		BR_NLOAD	: out STD_LOGIC;
		BR_SCLK 	: out STD_LOGIC
	);
end component BREAK_VOL;

--FAZA_DRUK_MODULE ------------------------------------------------------------
component FAZA_DRUK_MOD is
Port ( 
		FDM_FAZA_DRUK 		: out STD_LOGIC;
		FDM_FAZA_DLY_CLK 	: in STD_LOGIC;
		FDM_DRUK 			: in STD_LOGIC;
		FRM_START_PRINTING	: in STD_LOGIC; -- RZADEK_N_WOLNY z ROWS_FIRE
		FDM_PERMIT 			: in STD_LOGIC;	--TYLKO_TEXT (FAZATST_X(7))
		FDM_KONIEC_RZADKA 	: in STD_LOGIC;
		FDM_ILPO 			: in STD_LOGIC_VECTOR(2 downto 0);	--BlokadaPO
		FDM_DANE_DO_CPU		: in STD_LOGIC;
		FDM_PRINT_DROP_CLK	: in STD_LOGIC;
		FDM_TEST_1			: out STD_LOGIC
	);
end component FAZA_DRUK_MOD;
signal ZER_EXTRA_IRQ : std_logic;
signal PORT_FAZA_CUR : std_logic_vector(2 downto 0); -- current FAZA
signal KOREKCJE_CUR : std_logic_vector(7 downto 0);	-- current KOREKCJE reg
constant TAB_FAZ_CONST : std_logic_vector(7 downto 0):= "00011110" ;

signal DRUK_MOD_TST	: std_logic;
--End of component definitions-------------------------------------------------

--Signals between components---------------------------------------------------
signal DOT 				: std_logic;
signal TAB_FAZOWANIA	: std_logic;
signal OSTATNI_BIT		: std_logic;
signal L_IK 			: std_logic;
signal NLOAD 			: std_logic;
signal FAZA_OK_CLK 		: std_logic;
signal L_KROPWRZ 		: std_logic;
signal KONIEC_RZADKA	: std_logic;
signal PRINT_DROP_CLK 	: std_logic;
signal A_EQU_B 			: std_logic;
signal F_1MHZ 			: std_logic;
signal F_2MHZ 			: std_logic;
signal DROP_FREQ 		: std_logic;
signal KONIEC_BAJTU 	: std_logic;
signal CLR_FIRE 		: std_logic;
signal ROWS_S 			: std_logic;
signal STAN_FOT_INT		: std_logic;
signal OVERUN			: std_logic;
signal STER_STB_INT		: std_logic;
signal SPI_SCK_INT		: std_logic;	--internal SPI clock
signal MISO_INT			: std_logic;	--internal MISO signal

-------------------------------------------------------------------------------
-- Phasing during printing
signal DRUK			: std_logic;
signal FAZA_CLK_DLY	: std_logic;
signal FAZA_DRUK	: std_logic;	-- 
signal RZADEK_N_WOLNY : std_logic;
signal DANE_DO_CPU	: std_logic;
--------------------------------------------------------------------------------
-- Breaking voltage
signal sNRCLR	: std_logic;
signal sNRLOAD	: std_logic;
signal sRSCLK	: std_logic;
signal sMOSI	: std_logic;

--------------------------------------------------------------------------------
--Signals form components not connected yet
signal FAZA_CLK_CTRL	: std_logic;
signal DROP_EXT_CTRL	: std_logic;
signal DROP_EXT_FREQ	: std_logic;
signal LAD_KROPKI		: std_logic; 	-- MC_ADDR(KROPKI(b1)) and NOT_MC_CS and NOT_RNW
signal IRQ_R 	: std_logic;	-- IRQ6 (together with FOTO signal)
signal IRQ_F 	: std_logic;	-- IRQ6 (together with ROWS signal)
signal TST_FAZ 	: std_logic;

signal CH_CLK_i		: std_logic;
signal CH_DATA_i 	: std_logic;
signal CH_LOAD_i	: std_logic;
-------------------------------------------------------------------------------

signal CP_STOP_TMP 	: std_logic;
signal CP_RST_TMP 	: std_logic;
--signal F8MHZ_TMP 	: std_logic := '0';
--signal F4MHZ_TMP 	: std_logic := '0';

--signal PROC_CLK_INT		: std_logic;	--Internal clock signal
--signal NIRQ6_SIG	: std_logic;
signal NIRQ5_SIG	: std_logic;
----------------------------------------------------------------------------

----------------------------------------------------------------------------
signal PROC_DATA_IN		: std_logic_vector(15 downto 0);
signal PROC_DATA_OUT	: std_logic_vector(15 downto 0);
-----------------------------------------------------------------------------

begin
----Processor bus
--			PROC_DATA <= (others => 'Z');
--			
--			-- Interrupts
--			PROC_NIRQ5 <= '1';
--			PROC_NIRQ6 <= '1';
--				
--			-- SPI Interface
--			PROC_MISO <= '0';
--							
--			MOSI <= '0';
--			SCK <= '0';
--			SS2 <= '0';
--			SS3 <= '0';
--							
--			--USB
--			NDATA_REQ <= '1';
--			NDATA_ACK <= '1';
--						
--			--Ethernet EM202
--			MD <= '1';			
--			RSTI <= '1';		
--			SPEC2RTS <= '0';
--						
--			--Breaking voltage
--			NRLOAD	<= '1';
--			NRCLR <= '1';
--			RSCLK <= '0';
--				
--			-- Corrections
--			COR_ADDR <= (others => '0');
--			COR_DATA	<= (others => 'Z');
--			COR_NWR	<= '1';
--			COR_NRD	<= '1';
--				
--				--Photodetector
--			STAN_FOT <= '0';
--			FOT_ACK <= '0';
--				
--			--Fans
--			FANO	<= '0';
--				
--			-- Stroboscopes
--			STER_STB <= '0';
--			EXT_STROB <= '0';
--				
--			--Counters control
--			CNT_END <= '0';
--			
--			SFT_OUT <= '0';	
--						
--			CLK_WY0 <= '0';
--			ZAPAS_WY0 <= '0';
--			RESOUTSF	<= '0';
--			LADEXSF	<= '0';
--				
--			PILA_GER<= '0';
--				
--						
--			INT_USB <= '0';
--			N_INIT <= '1';
			
			
			
SPI_SCK_INT <= PROC_SCK;

-- SPI --------------------------------
SPI_INTEFACE_MAP: SPI_INTERFACE
PORT MAP (
			SPI_SCK_IN => SPI_SCK_INT,
			SPI_MISO_OUT => MISO_INT,
			SPI_MOSI_IN => PROC_MOSI,
				
			SPI_SCK_OUT => SCK,
			SPI_MISO_IN => MISO,
			SPI_MOSI_OUT => sMOSI,
					
			SPI_NSS	=> PROC_NSS,
			SPI_CS_IN => SPI_CS,
			
			SPI_CS_OUT	=> SPI_SS
		);
--SS1 <= SPI_SS(0); -- or PCS0 - PROC_NSS
SS2 <= SPI_SS(1); -- of PCS3 - PROC_NPSC3
SS3 <= SPI_SS(2);
--SS4 <= SPI_SS(3);
PROC_MISO <= MISO_INT;
MOSI <= sMOSI;

--BREAKING VOLTAGE -----------------------------
BREAKING_VOL_MAP: BREAK_VOL
PORT MAP (
			BR_DROP_CLK => DROP_FREQ,
			BR_F16MHZ 	=> PROC_16MHZ,
			BR_SPI_CS 	=> SPI_SS(3),
			BR_SPI_SCK 	=> SPI_SCK_INT,
					
			BR_NCLR  => sNRCLR,
			BR_NLOAD => sNRLOAD,
			BR_SCLK  => sRSCLK
		);

NRCLR <= sNRCLR;
NRLOAD <= sNRLOAD;
RSCLK <= sRSCLK;

-- Set proper CS -------------------------
SWITCH: process (PROC_NCSEL,PROC_R_NW,TIMERCTRL,PORTFAZA)
begin
				
	CS_KROPKI <= '0';
	CS_PORT_STER <= '0';
	CS_KROPWRZ <= '0';
	CS_PORTDRUK <= '0';
	CS_STERDRUK <= '0';
	CS_PORTFAZA <= '0';
	CS_KOREKCJE <= '0';
	CS_BLOKADAPO <= '0';
	CS_STER_SHAFT <= '0';
	CS_STER_SH_MUL <= '0';
	CS_TIMERCTRL <= '0';
	CS_TIMERCTRL_COR <= '0';
	CS_FAZATEST_X <= '0';
	CS_TIMERRYNNA <= '0';
	CS_TIMERSTATUS <= '0';
	CS_SHIFT16BIT 	<= '0';
	CS_CZASKROPLISTER <= '0';
	CS_INTERFACE_E <= '0';
	CS_PORT_SW <= '0';
	CS_SPI_CS <= '0';
		
	CS_USB_DATA <= '0';
	NDATA_REQ <= '1';
	NDATA_ACK <= '1';
		
	if (N_RESET = '0') then
		CS_KROPKI <= '0';
		CS_PORT_STER <= '0';
		CS_KROPWRZ <= '0';
		CS_PORTDRUK <= '0';
		CS_STERDRUK <= '0';
		CS_PORTFAZA <= '0';
		CS_KOREKCJE <= '0';
		CS_BLOKADAPO <= '0';
		CS_STER_SHAFT <= '0';
		CS_STER_SH_MUL <= '0';
		CS_TIMERCTRL <= '0';
		CS_TIMERCTRL_COR <= '0';
		CS_FAZATEST_X <= '0';
		CS_TIMERRYNNA <= '0';
		CS_TIMERSTATUS <= '0';
		CS_SHIFT16BIT 	<= '0';
		CS_CZASKROPLISTER <= '0';
		CS_INTERFACE_E <= '0';
		CS_PORT_SW <= '0';
		CS_SPI_CS <= '0';
		
		CS_USB_DATA <= '0';
		NDATA_REQ <= '1';
		NDATA_ACK <= '1';
			
	elsif (PROC_NCSEL='0') then
			
		if (PROC_ADDR = KROPKI_ADDR) then
			CS_KROPKI<= '1';
			if (PROC_R_NW='1')then
				PROC_DATA_OUT (7 downto 0) <= (others =>'0');
				PROC_DATA_OUT (15 downto 8) <= KROPKI;
			end if;
			
		elsif (PROC_ADDR = PORT_STER_ADDR) then
			CS_PORT_STER <= '1';
			if (PROC_R_NW='1')then
				PROC_DATA_OUT(7 downto 0) <= (others =>'0');
				PROC_DATA_OUT (15 downto 8) <= PORT_STER;
			end if;
			
		elsif (PROC_ADDR = KROPWRZ_ADDR) then
			CS_KROPWRZ <= '1';
			if (PROC_R_NW='1')then
				PROC_DATA_OUT(7 downto 0) <= (others =>'0');
				PROC_DATA_OUT (15 downto 8) <= SHAFT_DIRECTION & KROPWRZ(6 downto 0);
			end if;
			
		elsif (PROC_ADDR = PORTDRUK_ADDR) then
			CS_PORTDRUK <= '1';
			if (PROC_R_NW='1')then
				PROC_DATA_OUT(7 downto 0) <= (others =>'0');
				PROC_DATA_OUT (15 downto 8) <= PORTDRUK;
			end if;
			
		elsif (PROC_ADDR = STERDRUK_ADDR) then
			CS_STERDRUK <='1';
			if (PROC_R_NW='1')then
				PROC_DATA_OUT(7 downto 0) <= (others =>'0');
				PROC_DATA_OUT (15 downto 8) <= STERDRUK;
			end if;
			
		elsif (PROC_ADDR = PORTFAZA_ADDR) then
			CS_PORTFAZA <= '1';
			if (PROC_R_NW='1')then
				PROC_DATA_OUT(7 downto 0) <= (others =>'0');
				PROC_DATA_OUT (15 downto 8) <= PORTFAZA;
			end if;
			
		elsif (PROC_ADDR = KOREKCJE_ADDR) then
			CS_KOREKCJE <= '1';
			if (PROC_R_NW='1')then
				PROC_DATA_OUT(7 downto 0) <= (others =>'0');
				PROC_DATA_OUT (15 downto 8) <= KOREKCJE;
			end if;
		
		elsif (PROC_ADDR = BLOKADAPO_ADDR) then
			CS_BLOKADAPO <= '1';
			if (PROC_R_NW='1')then
				PROC_DATA_OUT(7 downto 0) <= (others =>'0');
				PROC_DATA_OUT (15 downto 8) <= BLOKADAPO;
			end if;
			
		elsif (PROC_ADDR = STER_SHAFT_ADDR) then
			CS_STER_SHAFT <= '1';
			if (PROC_R_NW='1')then
				PROC_DATA_OUT(7 downto 0) <= (others =>'0');
				PROC_DATA_OUT (15 downto 8) <= STER_SHAFT;
			end if;
			
		elsif (PROC_ADDR = STER_SH_MUL_ADDR) then
			CS_STER_SH_MUL <= '1';
			if (PROC_R_NW='1')then
				PROC_DATA_OUT(7 downto 0) <= (others =>'0');
				PROC_DATA_OUT (15 downto 8) <= STER_SH_MUL;
			end if;
			
		elsif (PROC_ADDR = TIMERCTRL_ADDR or PROC_ADDR = TIMERCTRL_ADDR+1) then
			if (PORTFAZA(7)='0') then
				CS_TIMERCTRL <= '1';
				if (PROC_R_NW='1')then
					PROC_DATA_OUT <= TIMERCTRL;
				end if;
			else
				CS_TIMERCTRL_COR <= '1';
				if (PROC_R_NW='1'and PORTFAZA(4)='1')then
					PROC_DATA_OUT <= TIMERCTRL_COR;
				elsif (PROC_R_NW='1'and PORTFAZA(4)='0') then
					PROC_DATA_OUT <= TIMERCTRL_COR_1;
				end if;
			end if;
			
		elsif (PROC_ADDR = FAZATEST_X_ADDR) then
			CS_FAZATEST_X <= '1';
			if (PROC_R_NW='1')then
				PROC_DATA_OUT(7 downto 0) <= (others =>'0');
				PROC_DATA_OUT(15 downto 8) <= FAZATEST_X;
			end if;
			
		elsif (PROC_ADDR = TIMERRYNNA_ADDR or PROC_ADDR = TIMERRYNNA_ADDR+1) then
			CS_TIMERRYNNA <= '1';
			if (PROC_R_NW='1')then
				PROC_DATA_OUT <= TIMERRYNNA;
			end if;
			
		elsif (PROC_ADDR = TIMERSTATUS_ADDR or PROC_ADDR = TIMERSTATUS_ADDR+1) then
			CS_TIMERSTATUS <= '1';
			if (PROC_R_NW='1')then
				PROC_DATA_OUT <= TIMERSTATUS;
			end if;
			
		elsif (PROC_ADDR = SHIFT16BIT_ADDR or PROC_ADDR = SHIFT16BIT_ADDR+1) then
			CS_SHIFT16BIT <= '1';
			if (PROC_R_NW='1')then
				PROC_DATA_OUT <= SHIFT16BIT;
			end if;
			
		elsif (PROC_ADDR = CZKROPLISTER_ADDR or PROC_ADDR = CZKROPLISTER_ADDR+1) then
			CS_CZASKROPLISTER <='1';
			if (PROC_R_NW='1')then
				PROC_DATA_OUT <= CZASKROPLISTER;
			end if;
			
		elsif (PROC_ADDR = INTERFACE_E_ADDR) then
			CS_INTERFACE_E <= '1';
			if (PROC_R_NW='1')then
				PROC_DATA_OUT(7 downto 0) <= (others =>'0');
				PROC_DATA_OUT (15 downto 8) <= INTERFACE_E;
			end if;
			
		elsif (PROC_ADDR = PORT_SW1_ADDR or PROC_ADDR = PORT_SW1_ADDR+1) then
			CS_PORT_SW <= '1';
			if (PROC_R_NW='1')then
				PROC_DATA_OUT <= PORT_SW;
			end if;
			
		elsif (PROC_ADDR = SPI_CS_ADDR) then
			CS_SPI_CS <= '1';
			if (PROC_R_NW='1')then
				PROC_DATA_OUT(7 downto 0) <= (others =>'0');
				PROC_DATA_OUT (15 downto 8) <= SPI_CS;
			end if;
			
		elsif (PROC_ADDR = USB_DATA_ADDR) then
			CS_USB_DATA <= '1';
			
			if (PROC_R_NW = '1') then
				PROC_DATA_OUT <= (others => 'Z');
				NDATA_ACK <= '0';
			else
				NDATA_REQ <='0';
			end if;
			
		elsif (PROC_ADDR = USB_STAT_ADDR) then
			if (PROC_R_NW='1')then
				PROC_DATA_OUT(1 downto 0) <= USB_STAT;
				PROC_DATA_OUT (7 downto 2) <= (others => '0');
				PROC_DATA_OUT (15 downto 8) <= (others => '0');
			end if;
		end if;
	
	elsif (PROC_NCSEL='1') then
		PROC_DATA_OUT <= (others => 'Z');
	end if; --od (PROC_NCSEL='0')

end process SWITCH;

-- REGISTERS ----------------------------------------------------
--KROPKI
KROPKI_MAP: IOREG8
PORT MAP (
			DATA_IN 	=> PROC_DATA_IN(7 downto 0),
			DATA_OUT	=> KROPKI,
			CS 		=> CS_KROPKI,
			RNW		=> PROC_R_NW,
			RST 	=> N_RESET
		);
			
--PORTSTER
PORT_STER_MAP: IOREG8
PORT MAP (
			DATA_IN 	=> PROC_DATA_IN(7 downto 0),
			DATA_OUT	=> PORT_STER,
			CS 		=> CS_PORT_STER,
			RNW		=> PROC_R_NW,
			RST 	=> N_RESET
		);
			
-- KROPKIWRZ
KROPKIWRZ_MAP: IOREG8
PORT MAP (
			DATA_IN(7 downto 0)	=> PROC_DATA_IN(7 downto 0),
			DATA_OUT	=> KROPWRZ,
			CS 		=> CS_KROPWRZ,
			RNW		=> PROC_R_NW,
			RST 	=> N_RESET
		);

-- PORTDRUK
PORTDRUK_MAP: IOREG8
PORT MAP (
			DATA_IN(7 downto 0)	=> PROC_DATA_IN(7 downto 0),
			DATA_OUT	=> PORTDRUK,
			CS 		=> CS_PORTDRUK,
			RNW		=> PROC_R_NW,
			RST 	=> N_RESET
		);

-- STERDRUK
STERDRUK_MAP: IOREG8
PORT MAP (
			DATA_IN(7 downto 0)	=> PROC_DATA_IN(7 downto 0),
			DATA_OUT	=> STERDRUK,
			CS 		=> CS_STERDRUK,
			RNW		=> PROC_R_NW,
			RST 	=> N_RESET
		);

-- PORTFAZA
PORTFAZA_MAP: IOREG8
PORT MAP (
			DATA_IN (7 downto 0)	=> PROC_DATA_IN(7 downto 0),
			DATA_OUT	=> PORTFAZA,
			CS 		=> CS_PORTFAZA,
			RNW		=> PROC_R_NW,
			RST 	=> N_RESET
		);
	
-- KOREKCJE
KOREKCJE_MAP: IOREG8
PORT MAP (
			DATA_IN (7 downto 0)	=> PROC_DATA_IN(7 downto 0),
			DATA_OUT	=> KOREKCJE,
			CS 		=> CS_KOREKCJE,
			RNW		=> PROC_R_NW,
			RST 	=> N_RESET
		);

-- BLOKADAPO
BLOKADAPO_MAP: IOREG8
PORT MAP (
			DATA_IN (7 downto 0)	=> PROC_DATA_IN(7 downto 0),
			DATA_OUT	=> BLOKADAPO,
			CS 		=> CS_BLOKADAPO,
			RNW		=> PROC_R_NW,
			RST 	=> N_RESET
		);
			
-- STER_SHAFT
STER_SHAFT_MAP: IOREG8
PORT MAP (
			DATA_IN (7 downto 0)	=> PROC_DATA_IN(7 downto 0),
			DATA_OUT	=> STER_SHAFT,
			CS 		=> CS_STER_SHAFT,
			RNW		=> PROC_R_NW,
			RST		=> N_RESET
		);
		
-- STER_SH_MUL
STER_SH_MUL_MAP: IOREG8
PORT MAP (
			DATA_IN (7 downto 0)	=> PROC_DATA_IN(7 downto 0),
			DATA_OUT	=> STER_SH_MUL,
			CS 		=> CS_STER_SH_MUL,
			RNW		=> PROC_R_NW,
			RST		=> N_RESET
		);

-- TIMERCTRL
TIMERCTRL_MAP: IOREG16
PORT MAP (
			DATA_IN 	=> PROC_DATA_IN,
			DATA_OUT	=> TIMERCTRL,
			CS 		=> CS_TIMERCTRL,
			RNW		=> PROC_R_NW,--RNW_TIMERCTRL,
			RST 	=> N_RESET
		);

-- TIMERCTRL_COR
TIMERCTRL_COR_MAP: IOREG16
PORT MAP (
			DATA_IN 	=> PROC_DATA_IN,
			DATA_OUT	=> TIMERCTRL_COR,
			CS 		=> CS_TIMERCTRL_COR,
			RNW		=> PROC_R_NW,--RNW_TIMERCTRL,
			RST 	=> N_RESET
		);


-- FAZATEST_X		
FAZATEST_X_MAP: IOREG8
PORT MAP (
			DATA_IN(7 downto 0)	=> PROC_DATA_IN(7 downto 0),
			DATA_OUT	=> FAZATEST_X,
			CS 		=> CS_FAZATEST_X,
			RNW		=> PROC_R_NW,
			RST 	=> N_RESET
		);

-- TIMERRYNNA -- ReadOnlyRegister
--TIMERRYNNA_MAP: IOREG16
--PORT MAP (
--				DATA_IN 	=> PROC_DATA_IN,
--				DATA_OUT	=> TIMERRYNNA,
--				CS 		=> CS_TIMERRYNNA,
--				RNW		=> PROC_R_NW,
--				RST 		=> N_RESET
--			);

-- TIMERSTATUS -- ReadOnly Register
--TIMERSTATUS_MAP: IOREG16
--PORT MAP (
--				DATA_IN 	=> PROC_DATA_IN,
--				DATA_OUT	=> TIMERSTATUS,
--				CS 		=> CS_TIMERSTATUS,
--				RNW		=> PROC_R_NW,
--				RST 		=> N_RESET
--			);

-- SHIFT16BIT
SHIFT16BIT_MAP: IOREG16
PORT MAP (
			DATA_IN 	=> PROC_DATA_IN,
			DATA_OUT	=> SHIFT16BIT,
			CS 		=> CS_SHIFT16BIT,
			RNW		=> PROC_R_NW,
			RST 	=> N_RESET
		);

-- CZASKROPLISTER
CZASKROPLISTER_MAP: IOREG16
PORT MAP (
			DATA_IN 	=> PROC_DATA_IN,
			DATA_OUT	=> CZASKROPLISTER,
			CS 		=> CS_CZASKROPLISTER,
			RNW		=> PROC_R_NW,
			RST		=> N_RESET
		);

-- INTERFACE_E
INTERFACE_E_MAP: IOREG8
PORT MAP (
			DATA_IN(7 downto 0)	=> PROC_DATA_IN(7 downto 0),
			DATA_OUT	=> INTERFACE_E,
			CS 		=> CS_INTERFACE_E,
			RNW		=> PROC_R_NW,
			RST		=> N_RESET
		);

-- PORT_SW - read only register
--PORT_SW_MAP: IOREG16
--PORT MAP (
--			DATA_IN => PROC_DATA_IN,
--			DATA_OUT	=> PORT_SW,
--			CS 		=> CS_PORT_SW,
--			RNW		=> PROC_R_NW,
--			RST		=> N_RESET
--		);

-- SPI_CS
SPI_CS_MAP: IOREG8
PORT MAP (
			DATA_IN(7 downto 0)	=> PROC_DATA_IN(7 downto 0),
			DATA_OUT	=> SPI_CS,
			CS 			=> CS_SPI_CS,
			RNW			=> PROC_R_NW,
			RST			=> N_RESET
		);
		
-- USB_STAT - Readonly register
--USB_STAT_MAP: IOREG8
--PORT MAP (
--			DATA_IN(7 downto 0)	=> PROC_DATA_IN(7 downto 0),
--			DATA_OUT	=> USB_STAT,
--			CS 			=> CS_USB_STAT,
--			RNW			=> PROC_R_NW,
--			RST			=> N_RESET
--		);
		
--END OF REGISTERS-------------------------------------------------------------

-- DROPGENERATION-------------------------------------------------------------
DROPGENERATION_MAP: DROPGENERATION
PORT MAP (
			--Correction
			COR_ADDR	=> COR_ADDR,
			COR_DATA 	=> COR_DATA,
			COR_NWR		=> COR_NWR,
			COR_NRD	 	=> COR_NRD,

			-- Charging
			DR_CLOCK => CH_CLK_i,--CHAR_SCK,
			DR_DATA	=> CH_DATA_i, --CHAR_DATA,
			DR_LOAD	=> CH_LOAD_i, --CHAR_LOAD,
						
			--Ports from processor
			DR_PORTFAZA		=> PORTFAZA (7 downto 4),
			DR_KOREKCJE	  	=> KOREKCJE_CUR,--KOREKCJE,
			DR_KROPKIWRZ 	=> KROPWRZ,
			DR_BLOKADAPO	=> BLOKADAPO,
			DR_KROPKI	 	=> KROPKI,
			DR_SFT16MSB  	=> SHIFT16BIT,
			DR_TIMERCTRL 	=>TIMERCTRL_COR_1,

			DR_F_16MHZ		=> PROC_16MHZ,

			--Signals from Synt1MHz
			DR_DOT	=> DOT,
			DR_TAB_FAZOWANIA => TAB_FAZOWANIA,

			--Signals to Synt1MHz
			DR_A_EQU_B	=> A_EQU_B,
						
			--Signals from ROWS_FIRE
			DR_OSTATNI_BIT	=> OSTATNI_BIT,
			DR_L_ILK		=> L_IK,
			DR_L_LOAD		=> NLOAD,
						
			--Signals to ROWS_FIRE
			DR_KONIECRZADKA		=> KONIEC_RZADKA,
			DR_PRINT_DROP_CLK	=> PRINT_DROP_CLK,

			--Signals from FAZA_CLK
			DR_FAZA_OK_CLK 	=> FAZA_OK_CLK,

			--Signals to LICZ_W_BAJT
			DR_L_KROPWRZ => L_KROPWRZ
		);

-- Phasing during printing ----------------------------------------------------
PHASING_DURING_PRINTING_TRUE:
	if (EBS6500_PhDurPrinting = true) generate
FAZA_DRUK_MOD_MAP: FAZA_DRUK_MOD
PORT MAP ( 
		FDM_FAZA_DRUK 		=> FAZA_DRUK,
		FDM_FAZA_DLY_CLK 	=> FAZA_CLK_DLY,
		FDM_DRUK 			=> DRUK,
		FRM_START_PRINTING	=> RZADEK_N_WOLNY,
		FDM_PERMIT 			=> FAZATEST_X(7),	--TYLKO_TEXT (FAZATST_X(7))
		FDM_KONIEC_RZADKA 	=> KONIEC_RZADKA,
		FDM_ILPO 			=> BLOKADAPO(2 downto 0),
		FDM_DANE_DO_CPU		=> DANE_DO_CPU,
		FDM_PRINT_DROP_CLK	=> PRINT_DROP_CLK,
		FDM_TEST_1			=> DRUK_MOD_TST
	);
DANE_DO_CPU <= PORTFAZA(7) or FAZATEST_X(5);

-- Use correct register
PORT_FAZA_CUR <= PORTFAZA(2 downto 0) when (FAZA_DRUK = '1') else FAZATEST_X(2 downto 0);
KOREKCJE_CUR <= KOREKCJE when (FAZA_DRUK = '1') else TAB_FAZ_CONST;

-- Clear irq after phasing
CLR_EXTRA_IRQ_PROC: process (FAZA_DRUK,FAZATEST_X(6))
begin
	if (FAZATEST_X(6) = '1') then
		ZER_EXTRA_IRQ <= '0';
	elsif (FAZA_DRUK'event and FAZA_DRUK = '0') then
		ZER_EXTRA_IRQ <= '1';
	end if;
end process CLR_EXTRA_IRQ_PROC;
TIMERSTATUS_IN(4) <= ZER_EXTRA_IRQ;
	end generate;

PHASING_DURING_PRINTING_FALSE:
	if (EBS6500_PhDurPrinting = false) generate
PORT_FAZA_CUR <= PORTFAZA(2 downto 0);
KOREKCJE_CUR <= KOREKCJE;
ZER_EXTRA_IRQ <= '0';
	end generate;

--Synt1MHZ---------------------------------------------------------------------
SYNT1MHZ_MAP: Synt1MHz
PORT MAP ( 
    		--Inputs for generation 1MHz clock
			S1M_F_16MHz  => PROC_16MHZ,
			S1M_CLR 	 => TIMERCTRL(12),
			S1M_CTRL	 => TIMERCTRL(8),
					
			S1M_F_1MHz => F_1MHZ,
			S1M_F_2MHz => F_2MHz, 	
			--Inputs for DOT and TAB_FAZOWANIA
			S1M_KOREKCJE	=> KOREKCJE_CUR, --KOREKCJE,
			S1M_A_EQU_B		=> A_EQU_B,

			S1M_FAZA_OK_CLK	=> FAZA_OK_CLK,
			S1M_NEG_PHASE	=> STERDRUK(5),
				
			S1M_FAZA_NO		=> TIMERCTRL(1 downto 0),
			S1M_FAZA_START	=> TIMERCTRL(12),

			S1M_TAB_FAZOWANIA	=> TAB_FAZOWANIA,
			S1M_DOT				=> DOT
		);
CP_RST_TMP <= TIMERCTRL(12) when PORTFAZA(7)='0' else '0';

--FAZA_CLK---------------------------------------------------------------------
FAZA_CLK_MAP: FAZA_CLK
PORT MAP ( 
			PH_F_16MHz => PROC_16MHZ,
			PH_CZAS_KROPLI 	=> CZASKROPLISTER(7 downto 0),
			PH_PORT_FAZA 	=> PORT_FAZA_CUR,--PORTFAZA(2 downto 0),
			
			PH_FAZA_CLK_OK	=> FAZA_OK_CLK,
			PH_DROP_FREQ	=> DROP_FREQ,
			PH_FAZA_CLK_DLY => FAZA_CLK_DLY,
			
			--Controll signals and external drop frequency
			PH_FAZA_CLK_CTRL	=> FAZA_CLK_CTRL,
			PH_DROP_EXT_CTRL 	=> DROP_EXT_CTRL,
			PH_DROP_EXT_FREQ 	=> DROP_EXT_FREQ
		);

--LICZ_W_BAJT------------------------------------------------------------------
LICZ_W_BAJT_MAP:  LICZ_W_BAJT
PORT MAP( 
    		LW_STERDRUK_2_0 	=> STERDRUK(2 downto 0),
    		LW_PRINT_DROP_CLK	=> PRINT_DROP_CLK,
    			
           	LW_L_KROPWRZ 	=> L_KROPWRZ,
           	LW_NHOLD 		=> '1',--NHOLD,

           	LW_KONIEC_BAJTU => KONIEC_BAJTU
		);

--ROWS_FIRE--------------------------------------------------------------------
ROWS_FIRE_MAP: ROWS_FIRE
PORT MAP( 
			RF_BLOK_RZAD		=> STERDRUK(3),
			RF_EN_OVR			=> CZASKROPLISTER(10),
			RF_KONIEC_BAJTU		=> KONIEC_BAJTU,
			RF_KONIEC_RZADKA	=> KONIEC_RZADKA,
			RF_LAD_KROPKI		=> LAD_KROPKI,	-- MC_ADDR(KROPKI(b1)) and NOT_MC_CS and NOT_RNW
			RF_MAX_GAZ			=> PORTDRUK(5),
			RF_OVR_CLR			=> CZASKROPLISTER(9),
			RF_PRINT_DROP_CLK 	=> PRINT_DROP_CLK,
			RF_ROWS_S			=> ROWS_S,
			RF_START_B			=> PORTDRUK(4),
				
			RF_IRQ_R		=> IRQ_R,	-- IRQ6 (together with FOTO signal)
			RF_LAD_L_ILK	=> L_IK,
			RF_OSTATNI_BIT	=> OSTATNI_BIT,
			RF_N_LOAD_12SFT	=> NLOAD,
			RF_OVERUN		=> OVERUN,	--Signal is placed in TIMERSTATUS_IN(11)
			RF_START1		=> CLR_FIRE,
			RF_DRUK			=> DRUK,
			RF_RZADEK_N_WOLNY => RZADEK_N_WOLNY
		);
LAD_KROPKI <= PROC_ADDR(1) and (not PROC_NCSEL and not PROC_R_NW);

--MICROSCOP-------------------------------------------------------------------
MIKROSKOP_MAP : MIKROSKOP
PORT MAP(
	 		MI_DROP_FREQ	=> DROP_FREQ,
			MI_FAZA_OK		=> FAZA_OK_CLK,
			MI_F_2MHZ		=> F_2MHZ,
			MI_F_16MHZ		=> PROC_16MHZ,
			MI_LD_KROPKIWRZ => L_KROPWRZ,
				
			MI_ROWS		=> PORT_STER(5),--ROWS_S,
				
			MI_DELAY		=> TIMERCTRL(4),
			MI_IN_DELAY		=> TIMERCTRL(3),
			MI_STRBSKP_OUT	=> STER_STB_INT
		);

STER_STB <= STER_STB_INT when PORTDRUK(7)='1' else '0';

-- PHOTODETECTOR ------------------------------------------------------------
FOTOC_MAP: FOTOC
PORT MAP( 
			FOTOC_IN 	=> FOTO,
           	FOTOC_EDGE 	=> PORTDRUK(3),
			FOTOC_BLOCK	=> STERDRUK(4),
					 
			FOTOC_IRQ 	=> IRQ_F,
			FOTOC_STAT 	=> STAN_FOT_INT,
					 
			FOTOC_F_16MHZ => PROC_16MHZ
		);
STAN_FOT <= STAN_FOT_INT;

--SHAFT------------------------------------------------------------------------
SHAFT_MAP: SHAFT
PORT MAP ( 
			SH_ROWS_S	=> ROWS_S,
			SH_DIR	=> SHAFT_DIRECTION,
			
			--Encoder signals
			SH_CO_POL_TAKT => PORT_STER(6),
					
			SH_START_B		=> PORTDRUK(4),
			SH_CLR_FIRE		=> CLR_FIRE,
			SH_STERSHAFT 	=> STER_SHAFT,
			SH_SHAFT_IN		=> SHAFT_IN,
			SH_SHAFT_B		=> SHAFTB,
			SH_SHFT_NGEN 	=> PORTDRUK(0),
					
			--Generator signals
			SH_GEN		=> PROC_GEN,
			SH_F_16MHZ	=> PROC_16MHZ,
			SH_FREQ_MUL => STER_SH_MUL,
			N_RESET => N_RESET
		);

--CZAS_PRZELOTU----------------------------------------------------------------
CZAS_PRZELOTU_MAP: CZAS_PRZELOTU
PORT MAP ( 
			CP_ST1_RYNNA 	=> ST1_RYN,
			CP_F_1MHZ 		=> F_1MHZ,
			CP_RESET 		=> sCZAS_PRZELOTU_RESET,
			CP_STOP 		=> TIMERCTRL(5),
			CP_SPEED 		=> TIMERCTRL(9),
			CP_TST_OUT		=> TIMERCTRL(4),
			--CP_DELAY		=> TIMERCTRL(7 downto 6),
					
			CP_INIFAZ		=> TIMERCTRL(7),
			CP_TST_FAZ 		=> TST_FAZ,
			CP_TOUT			=> TIMERSTATUS_IN(2),
			CP_STATUS_STOP	=> TIMERSTATUS_IN(3),
			CP_IRQ5			=> NIRQ5_SIG,
			CP_CZASPRZELOTU => TIMERRYNNA(13 downto 0)
		);
sCZAS_PRZELOTU_RESET <= TIMERCTRL(11) or FAZA_DRUK;
--CP_STOP_TMP <= TIMERCTRL(5)when PORTFAZA(7)='0' else '0';
PROC_NIRQ5 <= NIRQ5_SIG and (not ZER_EXTRA_IRQ);
--------------------------------------------------------------------------------

-- SWITCH PROC DATA OUT BUS
PROC_DATA_OUT_BUS: process (PROC_DATA_OUT,PROC_R_NW, PROC_NCSEL, CS_USB_DATA)
begin
		if (PROC_NCSEL='0' and PROC_R_NW='1' and CS_USB_DATA = '0') then
			PROC_DATA <= PROC_DATA_OUT;
		else
			PROC_DATA <= (others => 'Z');
		end if;
end process PROC_DATA_OUT_BUS;
PROC_DATA_IN <= PROC_DATA;

TIMERCTRL_COR_PROC: process (PORTFAZA,PROC_DATA,TIMERCTRL)
begin
	if (PORTFAZA(7)='1' and PORTFAZA(4)='1') then
		TIMERCTRL_COR_1 <= TIMERCTRL_COR;
	else
		TIMERCTRL_COR_1 <= (others => 'Z');
	end if;

end process TIMERCTRL_COR_PROC;

--TIMERSTATUS(11) - SHAFT or OVERRUN--------------------------------------------
TIMERSTATUS_IN(11) <= OVERUN when (CZASKROPLISTER(9)='0') else SHAFT_IN;

--IRQ6 - from FOTOC or ROWS
PROC_NIRQ6 <= not (IRQ_R or IRQ_F);

-- USB -------------------------------------------------------
USB_STAT(0) <= PGCK3;	--RXF
USB_STAT(1) <= SS1;		--TXE

--NDATA_REQ <= '1' when ((CS_USB_DATA = '1') and (PROC_R_NW = '0')) else '0';
--NDATA_REQ <= '0' when ((CS_USB_DATA = '1') and (PROC_R_NW = '0')) else '1';
--NDATA_ACK <= '0' when ((CS_USB_DATA = '1') and (PROC_R_NW = '1')) else '1';
		
--Test signals on ST6 connector ------------------------------

ST6_TST_2:
	if (ST6_TST = 2) generate
LADEXSF <= SHAFT_DIRECTION; --temporary SH_FREQ_MUL;
RESOUTSF <= SHAFT_IN; -- shaft
CLK_WY0 <= ROWS_S;
SFT_OUT <= FAZATEST_X(7);
ZAPAS_WY0 <= (RZADEK_N_WOLNY and KONIEC_RZADKA);--FAZATEST_X(6);
end generate;


ST6_TST_1:
	if (ST6_TST = 1) generate
LADEXSF <= FAZA_DRUK; --FAZA_DRUK;
RESOUTSF <= KONIEC_RZADKA;
CLK_WY0 <= DRUK_MOD_TST;
SFT_OUT <= FAZATEST_X(7);
ZAPAS_WY0 <= (RZADEK_N_WOLNY and KONIEC_RZADKA);--FAZATEST_X(6);
end generate;

-- Serial code switch - not used - need implementation
-- SHIFT16bit register must be implemented
ST6_TST_0:
	if (ST6_TST = 0) generate
LADEXSF <= DROP_FREQ;
RESOUTSF <= FAZA_CLK_CTRL; -- TEST_FAZA_CLK
CLK_WY0 <= FAZA_OK_CLK; -- TEST_FAZ_OK
SFT_OUT <= DOT; -- TEST_DOT
ZAPAS_WY0 <= TST_FAZ; -- TEST_FAZOW
end generate;

-- Parallel code switch ----------------------
PORT_SW_IN(3 downto 0) <= PKR_D;
PORT_SW_IN(7 downto 4) <= PKR_C;
PORT_SW_IN(11 downto 8) <= PKR_B;
PORT_SW_IN(12) <= '0';
PORT_SW_IN(13) <= '0';
PORT_SW_IN(14) <= PKR_K;
PORT_SW_IN(15) <= PKR_S;
PORT_SW <= PORT_SW_IN;

--Fans ------------------------
FANO		<= '1';

-- Other signals ---------
SPEC2RTS	<= STERDRUK(6);

CNT_END 	<= PORT_STER(4);
EXT_STROB 	<= PORT_STER(3);
FOT_ACK	 	<= PORT_STER(2);
PILA_GER	<= PORT_STER(0);

MD <= INTERFACE_E(3);			--MD line state (RS2323<->Ethernet converter)
RSTI <= INTERFACE_E(2);			-- Reset line for (RS2323<->Ethernet converter)
--ZAPAS_WY0 <= INTERFACE_E(0);

TIMERSTATUS_IN(15) <= CNT_CLR;
TIMERSTATUS_IN(14) <= STROB_KOD0;
TIMERSTATUS_IN(13) <= CNT_GATE;
TIMERSTATUS_IN(12) <= STAN_FOT_INT;
--TIMERSTATUS_IN(11) <= STAN_SHAFT;
TIMERSTATUS_IN(10) <= SPEC2CTS;
TIMERSTATUS_IN(9) <= '0';	--Free
TIMERSTATUS_IN(8) <= '0'; --Free
TIMERSTATUS_IN(7) <= '0'; --Free
TIMERSTATUS_IN(6) <= '0'; --Free
TIMERSTATUS_IN(0) <= ROBOT;
TIMERSTATUS <= TIMERSTATUS_IN;

INT_USB <= '1';
N_INIT <= '1';
end Behavioral;

