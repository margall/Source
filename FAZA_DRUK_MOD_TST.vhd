--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:45:35 01/13/2014
-- Design Name:   
-- Module Name:   D:/Projects/Drukarki/P332/CtrLogic/Sources/FAZA_DRUK_MOD_TST.vhd
-- Project Name:  CtrLogic
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: FAZA_DRUK_MOD
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY FAZA_DRUK_MOD_TST IS
END FAZA_DRUK_MOD_TST;
 
ARCHITECTURE behavior OF FAZA_DRUK_MOD_TST IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT FAZA_DRUK_MOD
    PORT(
         FDM_FAZA_DRUK : OUT  std_logic;
         FDM_FAZA_DLY_CLK : IN  std_logic;
         FDM_DRUK : IN  std_logic;
         FDM_PERMIT : IN  std_logic;
         FDM_KONIEC_RZADKA : IN  std_logic;
         FDM_ILPO : IN  std_logic_vector(2 downto 0);
         FDM_PRINT_DROP_CLK : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal FDM_FAZA_DLY_CLK : std_logic := '0';
   signal FDM_DRUK : std_logic := '0';
   signal FDM_PERMIT : std_logic := '0';
   signal FDM_KONIEC_RZADKA : std_logic := '0';
   signal FDM_ILPO : std_logic_vector(2 downto 0) := "111";
   signal FDM_PRINT_DROP_CLK : std_logic := '0';

 	--Outputs
   signal FDM_FAZA_DRUK : std_logic;

   -- Clock period definitions
   constant FDM_FAZA_DLY_CLK_period : time := 10 ns;
   constant FDM_PRINT_DROP_CLK_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: FAZA_DRUK_MOD PORT MAP (
          FDM_FAZA_DRUK => FDM_FAZA_DRUK,
          FDM_FAZA_DLY_CLK => FDM_FAZA_DLY_CLK,
          FDM_DRUK => FDM_DRUK,
          FDM_PERMIT => FDM_PERMIT,
          FDM_KONIEC_RZADKA => FDM_KONIEC_RZADKA,
          FDM_ILPO => FDM_ILPO,
          FDM_PRINT_DROP_CLK => FDM_PRINT_DROP_CLK
        );

   -- Clock process definitions
   FDM_FAZA_DLY_CLK_process :process
   begin
		FDM_FAZA_DLY_CLK <= '0';
		wait for FDM_FAZA_DLY_CLK_period/2;
		FDM_FAZA_DLY_CLK <= '1';
		wait for FDM_FAZA_DLY_CLK_period/2;
   end process;
 
   FDM_PRINT_DROP_CLK_process :process
   begin
		FDM_PRINT_DROP_CLK <= '0';
		wait for FDM_PRINT_DROP_CLK_period/2;
		FDM_PRINT_DROP_CLK <= '1';
		wait for FDM_PRINT_DROP_CLK_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		FDM_PERMIT <= '1';
		FDM_DRUK <= '1';
		FDM_ILPO <= "111";
      wait for FDM_FAZA_DLY_CLK_period*10;

      -- insert stimulus here
		
		wait for 100 ns;
		
		FDM_KONIEC_RZADKA <= '1';
		
		wait for 100 ns;
		FDM_DRUK <= '0';
		FDM_KONIEC_RZADKA <= '0';
		
		wait for 500 ns;
		FDM_DRUK <= '1';
		wait for 100 ns;
		FDM_KONIEC_RZADKA <= '1';
		wait for 100 ns;
		FDM_DRUK <= '0';
      wait;
   end process;

END;
