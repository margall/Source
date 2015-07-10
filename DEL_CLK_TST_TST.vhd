--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   13:26:47 01/10/2014
-- Design Name:   
-- Module Name:   D:/Projects/Drukarki/P332/CtrLogic/Sources/DEL_CLK_TST_TST.vhd
-- Project Name:  CtrLogic
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: DEL_CLK_TST
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
 
ENTITY DEL_CLK_TST_TST IS
END DEL_CLK_TST_TST;
 
ARCHITECTURE behavior OF DEL_CLK_TST_TST IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT DEL_CLK_TST
    PORT(
         CLK_16MHZ : IN  std_logic;
         CLK_FAZA : IN  std_logic;
         DELAY_CLK1 : out  STD_LOGIC;
		 DELAY_CLK2 : out	std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal CLK_16MHZ : std_logic := '0';
   signal CLK_FAZA : std_logic := '0';

 	--Outputs
   signal DELAY_CLK1 : std_logic;
	signal DELAY_CLK2 : std_logic;
	
   -- Clock period definitions
   constant CLK_16MHZ_period : time := 10 ns;
   constant CLK_FAZA_period : time := 100 ns;
  -- constant DELAY_CLK_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: DEL_CLK_TST PORT MAP (
          CLK_16MHZ => CLK_16MHZ,
          CLK_FAZA => CLK_FAZA,
          DELAY_CLK1 => DELAY_CLK1,
		  DELAY_CLK2 => DELAY_CLK2
        );

   -- Clock process definitions
   CLK_16MHZ_process :process
   begin
		CLK_16MHZ <= '0';
		wait for CLK_16MHZ_period/2;
		CLK_16MHZ <= '1';
		wait for CLK_16MHZ_period/2;
   end process;
 
   CLK_FAZA_process :process
   begin
		CLK_FAZA <= '0';
		wait for CLK_FAZA_period/2;
		CLK_FAZA <= '1';
		wait for CLK_FAZA_period/2;
   end process;
 
 --  DELAY_CLK_process :process
 --  begin
--		DELAY_CLK <= '0';
--		wait for DELAY_CLK_period/2;
--		DELAY_CLK <= '1';
--		wait for DELAY_CLK_period/2;
--   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for CLK_16MHZ_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
