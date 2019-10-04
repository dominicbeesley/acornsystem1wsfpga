-- Company: 			Dossytronics
-- Engineer: 			Dominic Beesley
-- 
-- Create Date:    	29/9/2019
-- Design Name: 
-- Module Name:    	arbitrary delay
-- Project Name: 
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

use work.common.all;

library work;

entity delay is
	generic (
		SIM									: boolean := false;			-- skip some stuff, i.e. slow sdram start up
		WIDTH									: natural;
		DELAY									: natural
	);
	port(

		clk_i					: in	std_logic;

		d_i					: in	std_logic_vector(WIDTH-1 downto 0);

		q_o					: out	std_logic_vector(WIDTH-1 downto 0)
	);
end delay;

architecture rtl of delay is

	function max(a:natural; b:natural) return natural is
	begin
		if (a > b) then
			return a;
		else
			return b;
		end if;
	end function;

	type t_dly_item is array (max(0,DELAY-1) downto 0) of std_logic;
	type t_dly is array (0 to WIDTH-1) of t_dly_item;

	signal	r_dly		: t_dly;	


begin

	g_width:for W in 0 to WIDTH - 1 generate

		g2:if DELAY = 0 generate
			q_o(W) <= d_i(W);
		end generate;

		p_dly_phi2:process(clk_i)
		begin
			if rising_edge(clk_i) then
				if (DELAY > 1) then
					r_dly(W)(t_dly_item'high downto 1) <= r_dly(W)(t_dly_item'high-1 downto 0);
				end if;
				r_dly(W)(0) <= d_i(W);
			end if;
		end process;

		g3:if DELAY > 0 generate
			q_o(W) <= r_dly(W)(t_dly_item'high);
		end generate;
	end generate;


end rtl;
