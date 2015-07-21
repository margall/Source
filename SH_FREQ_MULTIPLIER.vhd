----------------------------------------------------------------------------------
-- Company: EBS INK-JET SYSTEMS POLAND
-- Engineer: Marek Gallus
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

type RAM_MEMORY is array (7 downto 0) of signed(22 downto 0);

signal AVERAGE_ERROR : RAM_MEMORY := (others => (others => '0'));

signal IN_BUF : std_logic; -- buffered signal from shaft
signal EDGE : std_logic;	-- edge of SH_IN
signal counter_in : std_logic_vector (21 downto 0);
signal mul_freq_count : std_logic_vector (15 downto 0);
signal mul_freq_count_to : std_logic_vector (15 downto 0);
signal counter_fback : std_logic_vector (7 downto 0);
signal counter_fback_initial : std_logic_vector (7 downto 0) := (others => '0');
signal to_compare_count : std_logic_vector (21 downto 0);
signal mul_freq : std_logic;
signal update : std_logic;
signal update_count : std_logic_vector (1 downto 0);
signal edges_counter_sh : std_logic_vector (1 downto 0);
signal edges_counter_fb : std_logic_vector (1 downto 0);
signal shaft_counter : std_logic_vector (21 downto 0);
signal fback_counter : std_logic_vector (21 downto 0);
signal get_shaft_counter : std_logic;
signal get_fback_counter : std_logic;
signal difference : signed (22 downto 0);
signal start : std_logic;
signal mul_freq_init : std_logic := '0';
signal mul_freq_init_load : std_logic := '0';
signal mul_freq_div : std_logic_vector(21 downto 0);
signal mul_freq_div_out : std_logic_vector(21 downto 0);

begin	

	-- frequency multiplication in DLL feedback (f * (SH_FREQ_MUL(3 downto 0) + 1))
	-- SH_FREQ_MUL(7) = '0' --> both edges of shaft, '1' --> only rising edge (temporarily for tests)
	-- expected operation mode --> only rising edge
	counter_fback_initial <= x"0" & SH_FREQ_MUL(3 downto 0) when SH_FREQ_MUL(7) = '1'
									 else "00" & (SH_FREQ_MUL(3 downto 0) * "10") + 1;
	
	-- edge detection
	EDGE <= SH_IN xor IN_BUF when SH_FREQ_MUL(7) = '1'
			  else (SH_IN xor IN_BUF) and SH_IN;
	
	-- buffer input signal --> edge detection
	buffer_proc : process (SH_16MHz_CLK)
	begin
		if N_RESET = '0' then
			IN_BUF <= '0';
		elsif (SH_16MHz_CLK'event and SH_16MHz_CLK = '1') then
			IN_BUF <= SH_IN;
		end if;
	end process;

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
		
			if counter_in /= "11" & x"FFFFF" then
				counter_in <= counter_in + 1;
			end if;
			
			if to_compare_count /= "11" & x"FFFFF" then
				to_compare_count <= to_compare_count + 1;
			end if;
			
			if EDGE = '1' then
				if start = '1' then
					shaft_counter <= (others => '0');
					to_compare_count <= (others => '0');
					counter_in <= (others => '0');
					fback_counter <= (others => '0');
				else
					shaft_counter <= counter_in;
					counter_in <= (others => '0');
				end if;
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
	-- update parameter of DLL if 3 edges were counted (of SH_IN or MUL_FREQ_COUNT(end of cycle))
	-- if 3 edges come from the same source --> query the second counter and update his value
	-- new setting DLL is update using the computed difference / (SH_FREQ_MUL/weight)
	-- weight --> quantity of frequency multiplication
	-- if the computed difference = 65535 --> new value = current value + difference
	-- if the computed difference > 32 --> new value = current value + difference / (weight/4)
	-- if the computed difference < weight/2 --> new value = current value
	-- if the computed difference > xFFFF or < 0 setting are changed +/- '1' 
	compare : process (SH_16MHz_CLK)
	begin
		if N_RESET = '0' then
			edges_counter_sh<= (others => '0');
			edges_counter_fb<= (others => '0');
			update <= '0';
			update_count <= (others => '0');
			get_shaft_counter <= '0';
			get_fback_counter <= '0';
			mul_freq_count_to<= (others => '1');
		elsif (SH_16MHz_CLK'event and SH_16MHz_CLK = '1') then
			
			if (EDGE = '1') then
				edges_counter_sh <= edges_counter_sh + 1;
			elsif (counter_fback = x"00" and mul_freq_count = x"0000") then
				edges_counter_fb <= edges_counter_fb + 1;
			end if;
			
			if ((edges_counter_sh + edges_counter_fb) = "11") then
				if mul_freq_init = '1' or mul_freq_init_load = '1' then
					get_fback_counter <= '1';
					update <= '0';
					edges_counter_sh <= (others => '0');
					edges_counter_fb <= (others => '0');
				elsif (edges_counter_sh /= "00" and edges_counter_fb /= "00") then
					update <= '1';
					update_count <= update_count + 1;
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
			
			if (shaft_counter /= "00" & x"00000" and fback_counter = "00" & x"00000" and EDGE = '1') then
				mul_freq_init <= '1';
			elsif  mul_freq_init = '1' and EDGE = '1' then
				mul_freq_init_load <= '1';
				mul_freq_init <= '0';
			elsif mul_freq_init_load = '1' and EDGE = '1' then
				mul_freq_init_load <= '0';
				mul_freq_count_to <= mul_freq_div_out (15 downto 0);
			elsif update_count = "00" and update <= '1' then
				if (difference > signed(SH_FREQ_MUL) ) and difference < 64 then
					if mul_freq_count_to < x"FFFF" then
						mul_freq_count_to <= mul_freq_count_to - '1';
					end if;
				elsif (difference < -(signed(SH_FREQ_MUL))) and difference > -64 then
					if mul_freq_count_to > x"0000" then
						mul_freq_count_to <= mul_freq_count_to + '1';
					end if;
				elsif difference < 128 or difference > -128 then
					if (signed(mul_freq_count_to) + shift_right(difference(15 downto 0), 5)) < 65535 and (signed(mul_freq_count_to) + shift_right(difference(15 downto 0), 5)) > 0 then
						if (signed(mul_freq_count_to) + shift_right(difference(15 downto 0), 5)) /= signed(mul_freq_count_to) then
							mul_freq_count_to <= std_logic_vector(signed(mul_freq_count_to) - shift_right(difference(15 downto 0), 5));
						elsif difference > 0 then
							mul_freq_count_to <= mul_freq_count_to + '1';
						else
							mul_freq_count_to <= mul_freq_count_to - '1';
						end if;
					end if;
				else
					if (signed(mul_freq_count_to) + shift_right(difference(15 downto 0), 8)) < 65535 and (signed(mul_freq_count_to) + shift_right(difference(15 downto 0), 8)) > 0 then
						mul_freq_count_to <= std_logic_vector(signed(mul_freq_count_to) - shift_right(difference(15 downto 0), 8));
					end if;
				end if;
			end if;
			
			if counter_in = "11" & x"FFFFF" or shaft_counter = "11" & x"FFFFF" then
				start <= '1';
			else
				start <= '0';
			end if;
			
		end if;
	end process;
	
init_divider : process (SH_16MHz_CLK)
begin
	if N_RESET = '0' then
			mul_freq_div <= (others => '0');
			mul_freq_div_out <= (others => '0');
	elsif (SH_16MHz_CLK'event and SH_16MHz_CLK = '1') then
		if mul_freq_init = '1' then
			mul_freq_div <= shaft_counter;
		elsif mul_freq_div >= counter_fback_initial then
			mul_freq_div <= mul_freq_div - counter_fback_initial;
			mul_freq_div_out <= mul_freq_div_out + '1';
		end if;
	end if;
end process;

avr_diff : process (SH_16MHz_CLK)
begin
	if N_RESET = '0' then
			AVERAGE_ERROR <= (others => (others => '0'));
			difference<= (others => '0');
	elsif (SH_16MHz_CLK'event and SH_16MHz_CLK = '1') then
		if update = '0' then
			difference <= ((AVERAGE_ERROR(0) + AVERAGE_ERROR(1) + AVERAGE_ERROR(2) + AVERAGE_ERROR(3) 
			+ AVERAGE_ERROR(4) + AVERAGE_ERROR(5) + AVERAGE_ERROR(6) + AVERAGE_ERROR(7))/ x"8");
		elsif update = '1' then
			AVERAGE_ERROR(7) <= AVERAGE_ERROR(6);
			AVERAGE_ERROR(6) <= AVERAGE_ERROR(5);
			AVERAGE_ERROR(5) <= AVERAGE_ERROR(4);
			AVERAGE_ERROR(4) <= AVERAGE_ERROR(3);
			AVERAGE_ERROR(3) <= AVERAGE_ERROR(2);
			AVERAGE_ERROR(2) <= AVERAGE_ERROR(1);
			AVERAGE_ERROR(1) <= AVERAGE_ERROR(0);
			AVERAGE_ERROR(0) <= (signed('0' & shaft_counter) - signed(fback_counter));
		end if;
	end if;
end process;
			
			

	
-- MUX of output --> if	SH_FREQ_MUL = x"00" then output = input
FREQ_OUT <= SH_IN when SH_FREQ_MUL = x"00"
				else mul_freq;

end Behavioral;

