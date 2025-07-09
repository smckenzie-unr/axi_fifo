--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
--Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2024.1 (lin64) Build 5076996 Wed May 22 18:36:09 MDT 2024
--Date        : Sun Jul  6 16:00:55 2025
--Host        : System76-Thelio-Major running 64-bit Ubuntu 22.04.5 LTS
--Command     : generate_target top_wrapper.bd
--Design      : top_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity top_wrapper is
  port (
    ddr4_sdram_act_n : out STD_LOGIC;
    ddr4_sdram_adr : out STD_LOGIC_VECTOR ( 16 downto 0 );
    ddr4_sdram_ba : out STD_LOGIC_VECTOR ( 1 downto 0 );
    ddr4_sdram_bg : out STD_LOGIC_VECTOR ( 1 downto 0 );
    ddr4_sdram_ck_c : out STD_LOGIC;
    ddr4_sdram_ck_t : out STD_LOGIC;
    ddr4_sdram_cke : out STD_LOGIC;
    ddr4_sdram_cs_n : out STD_LOGIC;
    ddr4_sdram_dm_n : inout STD_LOGIC_VECTOR ( 7 downto 0 );
    ddr4_sdram_dq : inout STD_LOGIC_VECTOR ( 63 downto 0 );
    ddr4_sdram_dqs_c : inout STD_LOGIC_VECTOR ( 7 downto 0 );
    ddr4_sdram_dqs_t : inout STD_LOGIC_VECTOR ( 7 downto 0 );
    ddr4_sdram_odt : out STD_LOGIC;
    ddr4_sdram_reset_n : out STD_LOGIC;
    diff_clock_rtl_clk_n : in STD_LOGIC;
    diff_clock_rtl_clk_p : in STD_LOGIC;
    dip_switch_4bits_tri_i : in STD_LOGIC_VECTOR ( 3 downto 0 );
    led_4bits_tri_o : out STD_LOGIC_VECTOR ( 3 downto 0 );
    push_button_4bits_tri_i : in STD_LOGIC_VECTOR ( 3 downto 0 );
    reset_rtl : in STD_LOGIC
  );
end top_wrapper;

architecture STRUCTURE of top_wrapper is
  component top is
  port (
    ddr4_sdram_act_n : out STD_LOGIC;
    ddr4_sdram_adr : out STD_LOGIC_VECTOR ( 16 downto 0 );
    ddr4_sdram_ba : out STD_LOGIC_VECTOR ( 1 downto 0 );
    ddr4_sdram_bg : out STD_LOGIC_VECTOR ( 1 downto 0 );
    ddr4_sdram_ck_c : out STD_LOGIC;
    ddr4_sdram_ck_t : out STD_LOGIC;
    ddr4_sdram_cke : out STD_LOGIC;
    ddr4_sdram_cs_n : out STD_LOGIC;
    ddr4_sdram_dm_n : inout STD_LOGIC_VECTOR ( 7 downto 0 );
    ddr4_sdram_dq : inout STD_LOGIC_VECTOR ( 63 downto 0 );
    ddr4_sdram_dqs_c : inout STD_LOGIC_VECTOR ( 7 downto 0 );
    ddr4_sdram_dqs_t : inout STD_LOGIC_VECTOR ( 7 downto 0 );
    ddr4_sdram_odt : out STD_LOGIC;
    ddr4_sdram_reset_n : out STD_LOGIC;
    dip_switch_4bits_tri_i : in STD_LOGIC_VECTOR ( 3 downto 0 );
    led_4bits_tri_o : out STD_LOGIC_VECTOR ( 3 downto 0 );
    push_button_4bits_tri_i : in STD_LOGIC_VECTOR ( 3 downto 0 );
    reset_rtl : in STD_LOGIC;
    diff_clock_rtl_clk_n : in STD_LOGIC;
    diff_clock_rtl_clk_p : in STD_LOGIC
  );
  end component top;
begin
top_i: component top
     port map (
      ddr4_sdram_act_n => ddr4_sdram_act_n,
      ddr4_sdram_adr(16 downto 0) => ddr4_sdram_adr(16 downto 0),
      ddr4_sdram_ba(1 downto 0) => ddr4_sdram_ba(1 downto 0),
      ddr4_sdram_bg(1 downto 0) => ddr4_sdram_bg(1 downto 0),
      ddr4_sdram_ck_c => ddr4_sdram_ck_c,
      ddr4_sdram_ck_t => ddr4_sdram_ck_t,
      ddr4_sdram_cke => ddr4_sdram_cke,
      ddr4_sdram_cs_n => ddr4_sdram_cs_n,
      ddr4_sdram_dm_n(7 downto 0) => ddr4_sdram_dm_n(7 downto 0),
      ddr4_sdram_dq(63 downto 0) => ddr4_sdram_dq(63 downto 0),
      ddr4_sdram_dqs_c(7 downto 0) => ddr4_sdram_dqs_c(7 downto 0),
      ddr4_sdram_dqs_t(7 downto 0) => ddr4_sdram_dqs_t(7 downto 0),
      ddr4_sdram_odt => ddr4_sdram_odt,
      ddr4_sdram_reset_n => ddr4_sdram_reset_n,
      diff_clock_rtl_clk_n => diff_clock_rtl_clk_n,
      diff_clock_rtl_clk_p => diff_clock_rtl_clk_p,
      dip_switch_4bits_tri_i(3 downto 0) => dip_switch_4bits_tri_i(3 downto 0),
      led_4bits_tri_o(3 downto 0) => led_4bits_tri_o(3 downto 0),
      push_button_4bits_tri_i(3 downto 0) => push_button_4bits_tri_i(3 downto 0),
      reset_rtl => reset_rtl
    );
end STRUCTURE;
