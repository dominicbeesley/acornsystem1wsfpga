-- Company: 			Dossytronics
-- Engineer: 			Dominic Beesley
-- 
-- Create Date:    	29/9/2019
-- Design Name: 
-- Module Name:    	Acorn System 1 top level
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

entity ins8154 is
	generic (
		SIM									: boolean := false			-- skip some stuff, i.e. slow sdram start up
	);
	port(

		port_A_o				: out	std_logic_vector(7 downto 0);
		port_A_i				: in	std_logic_vector(7 downto 0);
		port_A_DDR_o		: out	std_logic_vector(7 downto 0);
		port_B_o				: out	std_logic_vector(7 downto 0);
		port_B_i				: in	std_logic_vector(7 downto 0);
		port_B_DDR_o		: out	std_logic_vector(7 downto 0);
		cpu_D_i				: in	std_logic_vector(7 downto 0);
		cpu_D_o				: out	std_logic_vector(7 downto 0);
		cpu_A_i				: in	std_logic_vector(6 downto 0);
		cpu_nCS0_i			: in	std_logic;
		cpu_CS1_i			: in	std_logic;
		cpu_MnIO				: in	std_logic;
		cpu_nRST				: in	std_logic;
		cpu_nwds				: in	std_logic;
		cpu_nrds				: in	std_logic;
		cpu_irq				: out	std_logic
	);
end ins8154;

architecture rtl of ins8154 is

	type t_mem_array is array(0 to 127) of std_logic_vector(7 downto 0);

	signal r_mem_128		: t_mem_array;

	signal r_mode			: std_logic_vector(2 downto 0);

	signal r_port_A_od	: std_logic_vector(7 downto 0);
	signal r_port_A_reg	: std_logic_vector(7 downto 0);
	signal i_port_A_read	: std_logic_vector(7 downto 0);

	signal r_port_B_od	: std_logic_vector(7 downto 0);
	signal r_port_B_reg	: std_logic_vector(7 downto 0);
	signal i_port_B_read	: std_logic_vector(7 downto 0);

	signal i_doread 		: boolean;
	signal i_sel			: boolean;
begin

	i_sel <= true when cpu_nCS0_i = '0' and cpu_CS1_i = '1' else
				false;

	i_doread <= true when i_sel and cpu_nrds = '0' else
					false;

	port_A_o <= r_port_A_reg;
	port_A_DDR_o <= r_port_A_od;
	port_B_o <= r_port_B_reg;
	port_B_DDR_o <= r_port_B_od;

	g_bits:FOR I in 0 to 7 generate

		i_port_A_read(I) <= 	port_A_i(I) when r_port_A_od(I) = '0' else
									r_port_A_reg(I);
		i_port_B_read(I) <= 	port_B_i(I) when r_port_B_od(I) = '0' else
									r_port_B_reg(I);

	end generate;

	cpu_D_o <= 
		-- memory read
		r_mem_128(to_integer(unsigned(cpu_A_i))) 										
			when 	i_doread and cpu_MnIO = '1' else
		-- port A bit read
		i_port_A_read(to_integer(unsigned(cpu_A_i(2 downto 0)))) & "0000000" 
			when	i_doread and (cpu_A_i(6 downto 3) = "0010" or cpu_A_i(6 downto 3) = "0000") else
		-- port B bit read
		i_port_B_read(to_integer(unsigned(cpu_A_i(2 downto 0)))) & "0000000" 
			when	i_doread and (cpu_A_i(6 downto 3) = "0011" or cpu_A_i(6 downto 3) = "0001") else
		-- port A byte read
		i_port_A_read 
			when 	i_doread and cpu_A_i = "0100000" else
		i_port_B_read 
			when 	i_doread and cpu_A_i = "0100001" else
		(others => '-');

	p_cpu_write:process(cpu_nRST, i_sel, cpu_nwds)
	begin

		if cpu_nRST = '0' then

			r_mode <= (others => '0');

			r_port_A_reg <= (others => '0');
			r_port_B_reg <= (others => '0');
			r_port_A_od <= (others => '0');
			r_port_B_od <= (others => '0');

		elsif i_sel and rising_edge(cpu_nwds) then

			if cpu_MnIO = '1' then
				r_mem_128(to_integer(unsigned(cpu_A_i))) <= cpu_D_i;
			else
				if cpu_A_i(6 downto 3) = "0010" then
					r_port_A_reg(to_integer(unsigned(cpu_A_i(2 downto 0)))) <= '1';
				elsif cpu_A_i(6 downto 3) = "0000" then
					r_port_A_reg(to_integer(unsigned(cpu_A_i(2 downto 0)))) <= '0';
				elsif cpu_A_i(6 downto 3) = "0011" then
					r_port_B_reg(to_integer(unsigned(cpu_A_i(2 downto 0)))) <= '1';
				elsif cpu_A_i(6 downto 3) = "0001" then
					r_port_B_reg(to_integer(unsigned(cpu_A_i(2 downto 0)))) <= '0';
				elsif cpu_A_i = "0100000" then
					r_port_A_reg <= cpu_D_i;
				elsif cpu_A_i = "0100001" then
					r_port_B_reg <= cpu_D_i;
				elsif cpu_A_i = "0100010" then
					r_port_A_od <= cpu_D_i;
				elsif cpu_A_i = "0100011" then
					r_port_B_od <= cpu_D_i;
				elsif cpu_A_i = "0100100" then
					r_mode <= cpu_D_i(7 downto 5);
				end if;
			end if;

		end if;

	end process;


end rtl;
