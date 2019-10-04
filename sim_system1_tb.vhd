----------------------------------------------------------------------------------
-- Company: 			Dossytronics
-- Engineer: 			Dominic Beesley
-- 
-- Create Date:    	23/3/2018
-- Design Name: 
-- Module Name:    	test bench for dmac blitter on mk2 board uising t65 core
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 		For mk1 board simulation
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--  This test bench emulates a cut-down BBC micro with a single 16k MOS ROM
--  and 32k RAM, hardware at FC00-FEFF does nothing special other than return 
--  'X', one special register at FEFF is used to terminate the simulation
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sim_system1_tb is
end sim_system1_tb;

architecture Behavioral of sim_system1_tb is

	signal	sim_ENDSIM			: 	std_logic 		:= '0';
	
	signal	EXT_CLK_50M			: 	std_logic;

	signal	EXT_nRESET			:	std_logic;



begin
	

	e_top: entity work.AcornSystem1
	generic map (
		SIM => true
	)
	port map (
		EXT_CLK_50M_i							=> EXT_CLK_50M,
		EXT_nRESET_i							=> EXT_nRESET

		
	);

	main_clkc50: process
	begin
		if sim_ENDSIM='0' then
			EXT_CLK_50M <= '0';
			wait for 10 ns;
			EXT_CLK_50M <= '1';
			wait for 10 ns;
		else
			wait;
		end if;
	end process;

	

	stim: process
	variable usct : integer := 0;
	
	begin
			
			EXT_nRESET <= '1';
			
			wait for 34 ns;

			EXT_nRESET <= '0';

			wait for 4000 ns;

			EXT_nRESET <= '1';

			wait	for 10000 us;
			
			sim_ENDSIM <= '1';

			wait for 10 us;

			wait;
	end process;


end;