-- Company: 			Dossytronics
-- Engineer: 			Dominic Beesley
-- 
-- Create Date:    	29/9/2019
-- Design Name: 
-- Module Name:    	cpu card
-- Project Name: 		Acorn System 1
-- Target Devices: 
-- Tool versions: 
-- Description: 		
-- Dependencies: 
--
-- Revision: 
-- Additional Comments: 
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.common.all;

library work;

entity as1_card_disp is
	generic (
		SIM									: boolean := false			-- skip some stuff, i.e. slow sdram start up
	);
	port(

		EXT_nRST_i			: 	in		std_logic;


		disp_nRST_o			:	out	std_logic;							-- reset active low
		disp_led_seg_i		:  in		std_logic_vector(7 downto 0);	-- 7 segment display 0=a, 6=g, 7=dp
		disp_phi2_i			:  in		std_logic;							-- phi2 cpu clock (delayed by 2 gates)
		disp_casin_o		:	out	std_logic;							-- cassette/serial input
		disp_casout_i		:	in		std_logic;							-- cassette/serial output
		disp_key_sense_o	:	out	std_logic_vector(2 downto 0);	-- keypad row sense active low
		disp_scan_i			: 	in		std_logic_vector(2 downto 0);	-- keypad scan out active low, 

		ext_led_segs_o		:	out	std_logic_vector(7 downto 0); -- led segments dp, g..a active low
		ext_led_digsel_o	:  out	std_logic_vector(7 downto 0); -- led digit select active high

		ext_keys_command_i:  in		std_logic_vector(7 downto 0);	-- 8 active low command keys
		ext_pad_16_col_o	:	out	std_logic_vector(3 downto 0);
		ext_pad_16_row_i	:	in	   std_logic_vector(3 downto 0);
		ext_casin_i			:  in		std_logic;
		ext_casout_o		:	out	std_logic
	);
end as1_card_disp;

architecture rtl of as1_card_disp is

	signal	i_colsel : std_logic_vector(7 downto 0);

	signal	r_pad_scan_ctr: unsigned(10 downto 0);

	signal	r_pad_tgl:	std_logic;
	signal	r_pad_col:	unsigned(1 downto 0);

	signal 	r_pad_mem:	std_logic_vector(15 downto 0);

begin

	disp_nRST_o <= EXT_nRST_i;

	-- select column of display/keyboard scan
	p_digsel:process(disp_scan_i)
	begin
		i_colsel <= (others => '0');
		g:for I in 0 to 7 loop
			if I = unsigned(disp_scan_i) then
				i_colsel(I) <= '1';
			end if;
		end loop;
	end process;


	-- keypad 4x4 scanner
	p_key16_col:process(EXT_nRST_i, disp_phi2_i)
	begin
		if EXT_nRST_i = '0' then
			r_pad_scan_ctr <= (others => '0');
			r_pad_col <= (others => '0');
			r_pad_mem <= (others => '1');
		elsif rising_edge(disp_phi2_i) then
			r_pad_scan_ctr <= r_pad_scan_ctr + 1;

			if r_pad_scan_ctr = 0 then
				if r_pad_tgl = '0' then
					r_pad_tgl <= '1';

					r_pad_col <= r_pad_col + 1;					
				else
					r_pad_tgl <= '0';

					if r_pad_col = 0 then
						r_pad_mem(3 downto 0) <= ext_pad_16_row_i;
					elsif r_pad_col = 1 then
						r_pad_mem(7 downto 4) <= ext_pad_16_row_i;
					elsif r_pad_col = 2 then
						r_pad_mem(11 downto 8) <= ext_pad_16_row_i;
					else
						r_pad_mem(15 downto 12) <= ext_pad_16_row_i;
					end if;

				end if;
			end if;
		end if;

	end process;

	p_key16_col2:process(r_pad_col)
	begin
		ext_pad_16_col_o <= (others => 'Z');
		for i in 0 to 3 loop
			if r_pad_col = i then
				ext_pad_16_col_o(I) <= '0';
			end if;
		end loop;
	end process;

	ext_led_digsel_o <= i_colsel;

	ext_led_segs_o <= not disp_led_seg_i;

	disp_key_sense_o(0) <= and_reduce(
		not i_colsel or r_pad_mem(15 downto 8)
		);
	disp_key_sense_o(1) <= and_reduce(
		not i_colsel or ext_keys_command_i
		);
	disp_key_sense_o(2) <= and_reduce(
		not i_colsel or r_pad_mem(7 downto 0)
		);

	ext_casout_o <= disp_casout_i;
	disp_casin_o <= ext_casin_i;


end rtl;