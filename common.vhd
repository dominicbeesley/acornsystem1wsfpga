-- Company: 			Dossytronics
-- Engineer: 			Dominic Beesley
-- 
-- Create Date:    	16/04/2019
-- Design Name: 
-- Module Name:    	common.vhd
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 		blitter utility package
-- Dependencies: 
--
-- Revision: 
-- Additional Comments: 
--
----------------------------------------------------------------------------------
package common is
	function ceil_log2(i : natural) return natural;
  function floor_log2(i : natural) return natural;
  -- numbits is the number of bits required to hold w as a *number of options*
  function numbits(w : natural) return natural;
end package;

library ieee;
use ieee.math_real.all;

package body common is
	function ceil_log2(i : natural) return natural is
	begin
   	return integer(ceil(log2(real(i))));  -- Example using real calculation
 	end function;

  function floor_log2(i : natural) return natural is
  begin
    return integer(floor(log2(real(i))));  -- Example using real calculation
  end function;


 	function numbits(w : natural) return natural is
	begin
		assert w > 0 report "width must be > 0" severity error;
		if w = 1 then
			return 1;
		else
			return floor_log2(w-1)+1;
		end if;
	end function;
end package body;