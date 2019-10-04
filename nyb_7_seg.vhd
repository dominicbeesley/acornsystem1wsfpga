-- Company: 			Dossytronics
-- Engineer: 			Dominic Beesley
-- 
-- Create Date:    	29/9/2019
-- Design Name: 
-- Module Name:    	hex nybble to 7 segment
-- Project Name: 		Acorn System 1 top level
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

--use work.mk1board_types.all;

library work;

entity nyb_7_seg is
	generic (
			G_INVERT_OUTPUTS : boolean
		);
	port(
		nyb_i			: in	unsigned(3 downto 0);

		seg_o			: out	std_logic_vector(6 downto 0)

	);
end nyb_7_seg;

architecture rtl of nyb_7_seg is
	signal i_seg : std_logic_vector(6 downto 0);
begin

	i_seg <= 
		"0111111" when nyb_i = 0 else
		"0000110" when nyb_i = 1 else
		"1011011" when nyb_i = 2 else
		"1001111" when nyb_i = 3 else
		"1100110" when nyb_i = 4 else
		"1101101" when nyb_i = 5 else
		"1111101" when nyb_i = 6 else
		"0000111" when nyb_i = 7 else
		"1111111" when nyb_i = 8 else
		"1100111" when nyb_i = 9 else
		"1110111" when nyb_i = 10 else
		"1111100" when nyb_i = 11 else
		"1011000" when nyb_i = 12 else
		"1011110" when nyb_i = 13 else
		"1111001" when nyb_i = 14 else
		"1110001";


	g_inv: if G_INVERT_OUTPUTS generate
		seg_o <= not i_seg;
	end generate;
	g_not_inv: if not G_INVERT_OUTPUTS generate
		seg_o <= i_seg;
	end generate;

end rtl;