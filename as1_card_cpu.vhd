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

use work.common.all;

library work;

entity as1_card_cpu is
	generic (
		SIM									: boolean := false;			-- skip some stuff, i.e. slow sdram start up
		BOARD_CLOCK_DIV2					: natural := 25;				-- clock speed will be divided down to 1MHz			
																					-- divider will be 2x this value i.e. 25 for a 
																					--	50MHz clock
		CPU_CLK_DELAY						: natural := 3;				-- number of board clock cycles by which phi2 out
																					-- is delayed wrt cpu clken

		CPU_A_DELAY							: natural := 4;				-- how long to delay/hold the address from the cpu				

		CPU_D_DELAY							: natural := 4					-- how long to delay/hold cpu data out
	);
	port(

		EXT_CLK_50M_i		: 	in		std_logic;							-- Waveshare 50MHz clock

		disp_nRST_i			:	in		std_logic;							-- reset active low
		disp_led_seg_o		:  out	std_logic_vector(7 downto 0);	-- 7 segment display 0=a, 6=g, 7=dp
		disp_phi2_o			:  out	std_logic;							-- phi2 cpu clock (delayed by 2 gates)
		disp_casin_i		:	in		std_logic;							-- cassette/serial input
		disp_casout_o		:	out	std_logic;							-- cassette/serial output
		disp_key_sense_i	:	in		std_logic_vector(2 downto 0);	-- keypad row sense active low
		disp_scan_o			: 	out	std_logic_vector(2 downto 0)	-- keypad scan out active low, 

	);
end as1_card_cpu;

architecture rtl of as1_card_cpu is



	-- cpu / phi2 generation
	signal	r_clk_phi2_div_ctr	: unsigned(numbits(BOARD_CLOCK_DIV2)-1 downto 0) := (others => '0');
	signal	i_clk_phi2_div			: boolean;							-- '1' when phi2 about to flip;

	signal	r_clk_phi2_int			: std_logic;						-- the phi2 clock 

	signal	i_phi2_main 			: std_logic; 						-- phi2 as used outside of cpu, may be delayed

	signal	i_cpu_clken				: std_logic;						-- cpu clcken coincides with phi2 falling edge

	-- cpu signals

	signal	i_t65_A					: std_logic_vector(23 downto 0);
	signal	i_t65_D_i				: std_logic_vector(7 downto 0);
	signal	i_t65_D_o				: std_logic_vector(7 downto 0);
	signal	i_t65_RnW 				: std_logic;

	-- bus signals
	signal	i_nRDS					: std_logic;
	signal	i_nWDS					: std_logic;
	signal	i_bus_A					: std_logic_vector(15 downto 0);
	signal	i_bus_D_cpu_o			: std_logic_vector(7 downto 0);
	signal	i_bus_RnW				: std_logic;

	--ic2 signals

	signal	i_IC2_D_o				: std_logic_vector(7 downto 0);
	signal	i_IC2_nCS0				: std_logic;
	signal	i_IC2_CS1				: std_logic;
	signal	i_IC2_MnIO				: std_logic;

	signal	i_IC2_port_A_o			: std_logic_vector(7 downto 0);

	-- IC 3/4 monitor ROM signals

	signal	i_ic_3_4_nCS			: std_logic;
	signal	i_ic_3_4_D_o			: std_logic_vector(7 downto 0);
	signal	i_ic_3_4_clken			: std_logic;

	signal	i_disp_casout_ddr		: std_logic;				-- data direction of porta(6)


begin


---------------------------------------------------------
-- address decode
---------------------------------------------------------
	i_ic_3_4_nCS <= 	'0' when i_bus_A(15 downto 11) = "11111" 
							else '1';

	i_nRDS <= '0' when i_phi2_main = '1' and i_bus_RnW = '1' else
				 '1';

	i_nWDS <= '0' when i_phi2_main = '1' and i_bus_RnW = '0' else
				 '1';

	-- IC2 at 0C00-0CFF, 0000-03FF
	i_IC2_MnIO <= '0' when i_bus_A(15 downto 12) = "0000" and i_bus_A(11 downto 10) = "11" else
					  '1';
	i_IC2_nCS0 <= '0';
	i_IC2_CS1 <= '1' when i_bus_A(15 downto 12) = "0000" and i_bus_A(11 downto 10) = "11" else
					 '1' when i_bus_A(15 downto 12) = "0000" and i_bus_A(11 downto 10) = "00" else
					 '0';


--	i_IC2_MnIO <= i_bus_A(7);
--	i_IC2_nCS0 <= '0' when i_bus_A(15 downto 12) = "0000" and i_bus_A(11 downto 10) = "11" else
--					  '1';
--	i_IC2_CS1 <= i_bus_A(9);

---------------------------------------------------------
-- inboard and offboard phi2 clock generation
---------------------------------------------------------

	assert BOARD_CLOCK_DIV2 > 10 report "BOARD_CLOCK_DIV2 must be > 10" severity error;

	disp_phi2_o <= i_phi2_main;

	e_dly_phi2: entity work.delay
	generic map (
		SIM		=> SIM,
		WIDTH		=> 1,
		DELAY		=> CPU_CLK_DELAY
		)
	port map (
		clk_i		=> EXT_CLK_50M_i,
		d_i(0)	=> r_clk_phi2_int,
		q_o(0)	=> i_phi2_main
	);


	i_clk_phi2_div <= r_clk_phi2_div_ctr = BOARD_CLOCK_DIV2;

	p_phi2_clk_div:process(EXT_CLK_50M_i)
	begin
		if rising_edge(EXT_CLK_50M_i) then
			if i_clk_phi2_div then
				r_clk_phi2_div_ctr <= (others => '0');

				if r_clk_phi2_int = '0' then
					r_clk_phi2_int <= '1';
				else
					r_clk_phi2_int <= '0';
				end if;
			else
				r_clk_phi2_div_ctr <= r_clk_phi2_div_ctr + 1;
			end if;
		end if;
	end process;

	i_cpu_clken <= 	'1' when i_clk_phi2_div and i_phi2_main = '1' else
							'0';

---------------------------------------------------------
-- cpu
---------------------------------------------------------

	e_cpu: entity work.T65 
  	port map (
   	Mode    => "00", -- 6502A
   	Res_n   => disp_nRST_i,
   	Enable  => i_cpu_clken,
   	Clk     => EXT_CLK_50M_i,
   	Rdy     => '1',
   	Abort_n => '1',
   	IRQ_n   => '1',
   	NMI_n   => '1',
   	SO_n    => '1',
   	R_W_n   => i_t65_RnW,
   	Sync    => open,
   	EF      => open,
   	MF      => open,
   	XF      => open,
   	ML_n    => open,
   	VP_n    => open,
   	VDA     => open,
   	VPA     => open,
   	A       => i_t65_A,
   	DI      => i_t65_D_i,
   	DO      => i_t65_D_o
	);

  	-- cpu data in multiplex

  	i_t65_D_i <=
  		i_t65_D_o 			when  i_t65_RnW = '0'		else			-- connect to output when cpu writing as fallback
  		i_ic_3_4_D_o		when  i_ic_3_4_nCS = '0' 	else
  		i_IC2_D_o			when  i_IC2_nCS0 = '0' and i_IC2_CS1 = '1' else
  		(others => '-');

---------------------------------------------------------
-- bus signals from CPU
---------------------------------------------------------
	
	e_dly_cpu_d: entity work.delay
	generic map (
		SIM		=> SIM,
		WIDTH		=> 8,
		DELAY		=> CPU_D_DELAY
		)
	port map (
		clk_i		=> EXT_CLK_50M_i,
		d_i		=> i_t65_D_o,
		q_o		=> i_bus_D_cpu_o
	);
	
	e_dly_cpu_a: entity work.delay
	generic map (
		SIM		=> SIM,
		WIDTH		=> 17,
		DELAY		=> CPU_A_DELAY
		)
	port map (
		clk_i		=> EXT_CLK_50M_i,
		d_i(15 downto 0)		=> i_t65_A(15 downto 0),
		d_i(16)				   => i_t65_RnW,
		q_o(15 downto 0) 		=> i_bus_A,
		q_o(16)					=> i_bus_RnW
	);




---------------------------------------------------------
-- monitor rom in ICs 3/4
---------------------------------------------------------

	i_ic_3_4_clken <= not i_ic_3_4_nCS;

	e_ic_3_4_mon_rom: entity work.prom_ic_3_4_mon
	port map
	(
		address		=> i_t65_A(8 downto 0),
		clock			=> EXT_CLK_50M_i,
		q				=> i_ic_3_4_D_o,
		clken			=> i_ic_3_4_clken
	);

---------------------------------------------------------
-- INS8154 - keyboard and display IC2
---------------------------------------------------------


e_ic2_8154:entity work.ins8154
	generic map (
		SIM		=> SIM
	)
	port map (

		port_A_o						=> i_IC2_port_A_o,

		port_A_i(7)					=> disp_casin_i,
		port_A_i(6)					=> '-',
		port_A_i(5 downto 3)		=> disp_key_sense_i,
		port_A_i(2 downto 0)		=> (others => '-'),
		port_A_DDR_o(6)			=> i_disp_casout_ddr,

		port_B_o				=> disp_led_seg_o,
		port_B_i				=> (others => '-'),

		cpu_D_i				=> i_bus_D_cpu_o,
		cpu_D_o				=> i_IC2_D_o,
		cpu_A_i				=> i_bus_A(6 downto 0),
		cpu_nCS0_i			=> i_IC2_nCS0,
		cpu_CS1_i			=> i_IC2_CS1,
		cpu_MnIO				=> i_IC2_MnIO,
		cpu_nRST				=> disp_nRST_i,
		cpu_nwds				=> i_nWDS,
		cpu_nrds				=> i_nRDS,
		cpu_irq				=> open
	);


	disp_casout_o <= 
		i_IC2_port_A_o(6) when i_disp_casout_ddr = '1' else
		'1';
	disp_scan_o <= i_IC2_port_A_o(2 downto 0);


end rtl;
