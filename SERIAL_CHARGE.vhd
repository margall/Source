----------------------------------------------------------------------------------
-- Company: EBS INK-JET SYSTEMS POLAND 
-- Engineer: 	TOMASZ GRONOWICZ
-- 
-- Create Date:    12:34:32 05/13/2007 
-- Design Name: 	Printer control logic
-- Module Name:   SERIAL_CHARGE - Behavioral 
-- Project Name: 	EBS7100	
-- Target Devices: XC3S200-4PQ208
-- Tool versions:  	ISE 8.2.03i 
-- Description: 	It is a simple SPI - one way data + load signal
--						Module gets correction data (1st 12 bit fom correction flash) - the drop ampilude
--						and sends it serialy to the charging electrode. The load signal starts charging
--						electrode
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
-- Revision 0.02 - New concept of working: data is send always on rising edge of FAZA_CLK_OK
--									and on falling edge of FAZA_CLK_OK when TAB_FAZOWANIA=1
--									Before sending small delay is introduced
--									Signal LOAD is generated directly after data is send
--									Signal DOT is not used
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SERIAL_CHARGE is
		Port (
					SC_COR_DATA 	: in  STD_LOGIC_VECTOR (11 downto 0); --Correction data
					SC_DOT 				: in  STD_LOGIC;
					SC_TAB_FAZOWANIA : in  STD_LOGIC;
					
					SR_CLOCK	: out  STD_LOGIC;		--Serial clock
					SR_DATA 	: out  STD_LOGIC;		--Serial data
					SR_LOAD 	: out  STD_LOGIC;		--Load data
					
					SC_FAZA_CLK_OK 	: in  STD_LOGIC;		--Faza OK clock
					SC_CLK					: in STD_LOGIC			--Main 16Mhz clock
				);
end SERIAL_CHARGE;

architecture Behavioral of SERIAL_CHARGE is

signal SC_CLK_TMP : std_logic := '0';	-- Internal clock: SC_CLK/2
signal SFT_REG 		: std_logic_vector(11  downto 0);

signal SFT_CNT : integer range 0 to 12 := 0; --shift counter
constant SFT_CNT_VAL : integer range 0 to 12 := 11;

signal RS_EDG	: std_logic := '0';	--Detection of rising edge of FAZA_OK_CLK
signal FL_EDG	: std_logic := '0';	--Detection of falling edge of FAZA_OK_CLK

signal SR_DATA_i : std_logic;

signal SR_LOAD_i 	: std_logic := '1';
signal SR_LOAD_ii : std_logic := '1';

signal LD_SFT		: std_logic := '0';	--Load SFT_REG on rising edge of FAZA_OK_CLK
signal LD_SFT_F	: std_logic := '0'; --Load SFT_REG on falling edge of FAZA_OK_CLK
signal LD_SFT_i	: std_logic := '0';
signal CLK_EN		: std_logic := '0'; --Clock enable


begin

--Generate SC_CLK/2 clock--------------------------------------------------------
GEN_8MHZ_PROC: process(SC_CLK)
begin
	if (SC_CLK'event and SC_CLK='1') then
		SC_CLK_TMP <= not SC_CLK_TMP;
	end if;
end process GEN_8MHZ_PROC;

--Detect the falling and rising edge of SC_FAZA_CLK_OK----------------------------
DET_EDG:process(SC_CLK_TMP)
begin
	if (SC_CLK_TMP'event and SC_CLK_TMP='0') then
		if (SC_FAZA_CLK_OK='1') then
			RS_EDG <= '1';
			FL_EDG <= '0';
		else
			RS_EDG <='0';
			FL_EDG <='1';
		end if;
	end if;
	
end process DET_EDG;

--Generate load shift register signal on rising edge---------------------------
GEN_RS_LD_SFT: process (CLK_EN,RS_EDG)
begin
	if (CLK_EN = '1') then
		LD_SFT <='0';
	elsif (RS_EDG'event and RS_EDG='1') then
		LD_SFT <='1';
	end if;
end process GEN_RS_LD_SFT;

--Generate load shift register signal on falling edge---------------------------
GEN_FL_LD_SFT: process (CLK_EN,FL_EDG)
begin
	if (CLK_EN = '1') then
		LD_SFT_F <='0';
	elsif (FL_EDG'event and FL_EDG='1') then
		if (SC_TAB_FAZOWANIA='1') then
			LD_SFT_F <='1';
		end if;
	end if;
end process GEN_FL_LD_SFT;

--Generate load shift register signal-------------------------------------------
--GEN_LD_SFT: process(SC_CLK_TMP)
--begin
--	if (SC_CLK_TMP'event and SC_CLK_TMP='1') then
--		
--		if (LD_SFT = '1') then
--			LD_SFT <= '0';
--		--	LD_SFT_i <='0';
--				
--		elsif (((SC_FAZA_CLK_OK='1') or (SC_FAZA_CLK_OK='0' and SC_TAB_FAZOWANIA='1')) and CLK_EN='0') then
--		--	LD_SFT_i <= '1';
--			LD_SFT <= '1';--LD_SFT_i;
--		end if;
--		
--	end if;
--
--end process GEN_LD_SFT;

--Load and shift data----------------------------------------------------------
process (SC_CLK_TMP) 
begin 
   if (SC_CLK_TMP'event and SC_CLK_TMP='0') then
	 
			if (LD_SFT = '1' or LD_SFT_F = '1') then 
         SFT_REG  <= SC_COR_DATA;
				 CLK_EN <= '1';
				 SFT_CNT <= 0;
      elsif CLK_EN = '1' then 
         SFT_REG <= SFT_REG(10 downto 0) & '0';
				 SFT_CNT <= SFT_CNT+1;
				 
--				 if (SFT_CNT = SFT_CNT_VAL-1) then
--					SR_LOAD_i <= '0';
--				 end if;
				 
				 if (SFT_CNT = SFT_CNT_VAL) then
					CLK_EN <= '0';
					--SR_LOAD_i <='1';
					--SFT_REG(10) <= '0';
				end if;
				
      end if;
			
   end if;
end process;

--Generate LOAD signal------------------------------------------------------------
GEN_LOAD_SIG: process (SC_CLK_TMP)
begin
	if (SC_CLK_TMP'event and SC_CLK_TMP='1') then
		if (SFT_CNT = SFT_CNT_VAL) then
			SR_LOAD_i <= '0';
		else
			SR_LOAD_i<= '1';
		end if;
	end if;
	
end process;

--Delay output signal 1/2 input clock----------------------------------------------
DEL_OUT:process (SC_CLK)
begin
	if (SC_CLK'event and SC_CLK='0') then
		SR_DATA_i<=SFT_REG(11) and SR_LOAD_i;
		SR_LOAD_ii <= SR_LOAD_i;
	end if;
end process;

--Set output
SR_DATA <= SR_DATA_i;--SFT_REG(11);
SR_CLOCK <= SC_CLK_TMP when (CLK_EN='1') else '0';
SR_LOAD <= SR_LOAD_ii;
end Behavioral;

