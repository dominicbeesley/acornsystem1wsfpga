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

--use work.mk1board_types.all;

library work;

entity AcornSystem1 is
	generic (
		SIM									: boolean := false							-- skip some stuff, i.e. slow sdram start up
	);
	port(
		-- crystal osc 50Mhz - on WS board
		EXT_CLK_50M_i						: in		std_logic;
		EXT_nRESET_i						: in		std_logic;

		LED_0_seg							: out		std_logic_vector(6 downto 0);	
		LED_0_dp								: out		std_logic;	
		LED_0_col							: out		std_logic;	
		LED_0_ct1							: out		std_logic;	
		LED_0_ct2							: out		std_logic;	
		LED_0_ct3							: out		std_logic;	
		LED_0_ct4							: out		std_logic;

		LED_1_seg							: out		std_logic_vector(6 downto 0);	
		LED_1_dp								: out		std_logic;	
		LED_1_col							: out		std_logic;	
		LED_1_ct1							: out		std_logic;	
		LED_1_ct2							: out		std_logic;	
		LED_1_ct3							: out		std_logic;	
		LED_1_ct4							: out		std_logic;


		xLED_seg								: out		std_logic_vector(6 downto 0);	
		xLED_dp								: out		std_logic;	
		xLED_ct								: out		std_logic_vector(7 downto 0);


		EXT_KEYS_COMMAND_I				: in		std_logic_vector(7 downto 0);

		EXT_PAD_16_COL_o					: out		std_logic_vector(3 downto 0);
		EXT_PAD_16_ROW_i					: in		std_logic_vector(3 downto 0);

		CASOUT_o								: out		std_logic;
		CASIN_i								: in		std_logic

	);
end AcornSystem1;

architecture rtl of AcornSystem1 is


-- cpu to disp board connects
		signal	i_cpudisp_nRST			: std_logic;
		signal	i_cpudisp_led_seg		: std_logic_vector(7 downto 0);
		signal	i_cpudisp_phi2			: std_logic;							-- phi2 cpu clock (delayed by 2 gates)
		signal	i_cpudisp_casin		: std_logic;							-- cassette/serial input
		signal	i_cpudisp_casout		: std_logic;							-- cassette/serial output
		signal	i_cpudisp_key_sense	: std_logic_vector(2 downto 0);	-- keypad row sense active low
		signal	i_cpudisp_scan			: std_logic_vector(2 downto 0);	-- keypad scan out active low, 

		signal	i_disp_ext_led_seg	 : std_logic_vector(7 downto 0);
		signal	i_disp_ext_led_digsel : std_logic_vector(7 downto 0);

begin

	e_cpu_card:entity work.as1_card_cpu
	generic map (
		SIM									=> SIM,
		BOARD_CLOCK_DIV2					=> 25
	)
	port map (
	
		EXT_CLK_50M_i		=> EXT_CLK_50M_i,

		disp_nRST_i			=> i_cpudisp_nRST,
		disp_led_seg_o		=> i_cpudisp_led_seg,
		disp_phi2_o			=> i_cpudisp_phi2,
		disp_casin_i		=> i_cpudisp_casin,
		disp_casout_o		=> i_cpudisp_casout,
		disp_key_sense_i	=> i_cpudisp_key_sense,
		disp_scan_o			=> i_cpudisp_scan

	);


	e_disp_card:entity work.as1_card_disp
	generic map (
		SIM		=> SIM
	)
	port map (

		EXT_nRST_i			=> EXT_nRESET_i,
		disp_nRST_o			=> i_cpudisp_nRST,
		disp_led_seg_i		=> i_cpudisp_led_seg,
		disp_phi2_i			=> i_cpudisp_phi2,
		disp_casin_o		=> i_cpudisp_casin,
		disp_casout_i		=> i_cpudisp_casout,
		disp_key_sense_o	=> i_cpudisp_key_sense,
		disp_scan_i			=> i_cpudisp_scan,

		ext_led_segs_o		=> i_disp_ext_led_seg,
		ext_led_digsel_o	=> i_disp_ext_led_digsel,

		ext_keys_command_i=> ext_keys_command_i,

		EXT_PAD_16_COL_o 	=> EXT_PAD_16_COL_o,
		EXT_PAD_16_ROW_i  => EXT_PAD_16_ROW_i,

		EXT_CASIN_i => CASIN_i,
		EXT_CASOUT_o => CASOUT_o
	);

	LED_0_seg <= i_disp_ext_led_seg(6 downto 0);
	LED_0_dp <= i_disp_ext_led_seg(7);
	LED_0_col <= '1';
	LED_1_seg <= i_disp_ext_led_seg(6 downto 0);
	LED_1_dp <= i_disp_ext_led_seg(7);
	LED_1_col <= '1';

	LED_0_ct1 <= i_disp_ext_led_digsel(0);
	LED_0_ct2 <= i_disp_ext_led_digsel(1);
	LED_0_ct3 <= i_disp_ext_led_digsel(2);
	LED_0_ct4 <= i_disp_ext_led_digsel(3);
	LED_1_ct1 <= i_disp_ext_led_digsel(4);
	LED_1_ct2 <= i_disp_ext_led_digsel(5);
	LED_1_ct3 <= i_disp_ext_led_digsel(6);
	LED_1_ct4 <= i_disp_ext_led_digsel(7);

	xLED_dp <= not i_disp_ext_led_seg(7);
	xLED_seg <= not i_disp_ext_led_seg(6 downto 0);
	xLED_ct <= not i_disp_ext_led_digsel;


end rtl;
