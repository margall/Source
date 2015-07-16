----------------------------------------------------------------------------------
-- Company: EBS INK-JET SYSTEMS POLAND
-- Engineer: 
-- 
-- Create Date:    09:09:52 07/13/2015 
-- Design Name: 
-- Module Name:    SH_FREQ_MULTIPLIER - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

entity SH_FREQ_MULTIPLIER is
    Port ( SH_IN			: in STD_LOGIC;	-- SHAFT ENCODER INPUT
			  SH_16MHz_CLK : in STD_LOGIC;	-- GLOBAL CLOCK
			  SH_FREQ_MUL 	: in STD_LOGIC_VECTOR(7 downto 0);	-- STATUS REGISTER (STER_SH_MUL)
			  N_RESET		: in STD_LOGIC;	-- RESET
           FREQ_OUT 		: out STD_LOGIC	-- OUTPUT
			  );
end SH_FREQ_MULTIPLIER;

architecture Behavioral of SH_FREQ_MULTIPLIER is

signal IN_BUF : std_logic; -- buffered signal from shaft
signal EDGE : std_logic;	-- edge of SH_IN
signal counter_in : std_logic_vector (15 downto 0);
signal mul_freq_count : std_logic_vector (15 downto 0);
signal mul_freq_count_to : std_logic_vector (15 downto 0);
signal counter_fback : std_logic_vector (7 downto 0);
signal counter_fback_initial : std_logic_vector (7 downto 0);
signal to_compare_count : std_logic_vector (15 downto 0);
signal mul_freq : std_logic;
signal update : std_logic;
signal edges_counter_sh : std_logic_vector (1 downto 0);
signal edges_counter_fb : std_logic_vector (1 downto 0);
signal shaft_counter : std_logic_vector (15 downto 0);
signal fback_counter : std_logic_vector (15 downto 0);
signal get_shaft_counter : std_logic;
signal get_fback_counter : std_logic;
signal diffrence : std_logic_vector (16 downto 0);


begin	

	-- frequency multiplication in DLL feedback (f * (SH_FREQ_MUL(3 downto 0) + 1))
	counter_fback_initial <= x"0" & SH_FREQ_MUL(3 downto 0);
	
	-- buffering input signal to detected edges
	buffer_proc : process (SH_16MHz_CLK)
	begin
		if N_RESET = '0' then
			IN_BUF <= '0';
		elsif (SH_16MHz_CLK'event and SH_16MHz_CLK = '1') then
			IN_BUF <= SH_IN;
		end if;
	end process;
	
	-- edge detection
	EDGE <= SH_IN xor IN_BUF;

	-- counting pulses from 16MHz clock in SHAFT_IN and mul_freq period**
	-- **[mul_freq period * counter_fback_initial] period --> mulitiplication of frequency
	counters_proc : process (SH_16MHz_CLK)
	begin
		if N_RESET = '0' then
			counter_in <= (others => '0');
			to_compare_count <= (others => '0');
			shaft_counter <= (others => '0');
			fback_counter <= (others => '0');
		elsif (SH_16MHz_CLK'event and SH_16MHz_CLK = '1') then
			if counter_in /= x"FFFF" then
				counter_in <= counter_in + 1;
			end if;
			if to_compare_count /= x"FFFF" then
				to_compare_count <= to_compare_count + 1;
			end if;
			if EDGE = '1' then
				shaft_counter <= counter_in;
				counter_in <= (others => '0');
			elsif get_shaft_counter = '1' then
				shaft_counter <= counter_in;
			end if;
			if (counter_fback = x"00" and mul_freq_count = x"0000") then
				fback_counter <= to_compare_count;
				to_compare_count <= (others => '0');
			elsif get_fback_counter = '1' then
				fback_counter <= to_compare_count;
			end if;	
		end if;
	end process;
	
	-- generate higher frequency signal (mul_freq)
	mul_freq_proc : process (SH_16MHz_CLK)
	begin
		if N_RESET = '0' or counter_in = x"FFFF" then
			mul_freq <= '0';
			counter_fback <= (others => '0');
			mul_freq_count <= x"0001"; 
		elsif (SH_16MHz_CLK'event and SH_16MHz_CLK = '1') then
			if (mul_freq_count = x"0000") then
				mul_freq <= not mul_freq;
				if counter_fback = x"00" then
					counter_fback <= counter_fback_initial;
				else
					counter_fback <= counter_fback - 1;
				end if;
				mul_freq_count <= mul_freq_count_to;
			elsif (mul_freq_count_to /= x"FFFF") then 
				mul_freq_count <= mul_freq_count - 1;			
			end if;
		end if;
	end process;
	
	-- compare period of SHAFT_IN and mul_freq
	-- determination of difference
	-- update parameter of DLL if 3 edges were counted
	-- if 3 edges come from the same source --> query the second counter and update his value
	-- new setting DLL is update using the computed difference / 8 (srl 3)
	-- if the computed difference > xFFFF or <0 setting are changed +/- '1' 
	compare : process (SH_16MHz_CLK)
	begin
		if N_RESET = '0' then
			edges_counter_sh<= (others => '0');
			edges_counter_fb<= (others => '0');
			update <= '0';
			get_shaft_counter <= '0';
			get_fback_counter <= '0';
			diffrence<= '0' & x"FFFF";
			mul_freq_count_to<= (others => '1');
		elsif (SH_16MHz_CLK'event and SH_16MHz_CLK = '1') then
			if (EDGE = '1') then
				edges_counter_sh <= edges_counter_sh + 1;
			elsif (counter_fback = x"00" and mul_freq_count = x"0000") then
				edges_counter_fb <= edges_counter_fb + 1;
			end if;			
			if ((edges_counter_sh + edges_counter_fb) = "11") then
				if (edges_counter_sh /= "00" and edges_counter_fb /= "00") then
					update <= '1';
					edges_counter_sh <= "00";
					edges_counter_fb <= "00";
				elsif (edges_counter_sh = "00") then
					get_shaft_counter <= '1';
					edges_counter_sh <= edges_counter_sh + 1;
					edges_counter_fb <= edges_counter_fb - 1;
				elsif (edges_counter_fb = "00") then
					get_fback_counter <= '1';
					edges_counter_fb <= edges_counter_fb + 1;
					edges_counter_sh <= edges_counter_sh - 1;
				end if;
			else
				update <= '0';
				get_fback_counter	<= '0';			
				get_shaft_counter <= '0';
			end if;
			if update = '1' then
				if shaft_counter > fback_counter then
					if mul_freq_count_to /= x"FFFF" then
						if ((shaft_counter - fback_counter) > x"0008") then
							diffrence <= '0' & mul_freq_count_to + std_logic_vector((unsigned(shaft_counter - fback_counter)) srl 3);
						else
							diffrence <= '0' & mul_freq_count_to + '1';
						end if;
					else
						diffrence <= '0' & mul_freq_count_to + shaft_counter - fback_counter;
					end if;
				elsif shaft_counter < fback_counter then
					if mul_freq_count_to /= x"FFFF" then
						if ((fback_counter - shaft_counter) > x"0008") then
							diffrence <= '0' & mul_freq_count_to -  std_logic_vector((unsigned(fback_counter + shaft_counter)) srl 3);
						else
							diffrence <= '0' & mul_freq_count_to - '1';
						end if;
					else
						diffrence <= '0' & mul_freq_count_to - fback_counter + shaft_counter;
					end if;
				end if;
			end if;
			if diffrence(16) = '0' then
				mul_freq_count_to <= diffrence(15 downto 0);
			elsif shaft_counter > fback_counter then
				mul_freq_count_to <= mul_freq_count_to + 1;
				diffrence <= '0' & mul_freq_count_to + 1;
			else
				mul_freq_count_to <= mul_freq_count_to - 1;
				diffrence <= '0' & mul_freq_count_to - 1;
			end if;
		end if;
	end process;
	
-- MUX of output --> if	SH_FREQ_MUL = x"0" then output = input
FREQ_OUT <= SH_IN when SH_FREQ_MUL = x"0"
				else mul_freq;

end Behavioral;

