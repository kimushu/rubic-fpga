-- nios2_fast_fpu_pixelsimd_inst.vhd

-- This file was auto-generated as part of a generation operation.
-- If you edit it your changes will probably be lost.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity nios2_fast_fpu_pixelsimd_inst is
	port (
		dataa  : in  std_logic_vector(31 downto 0) := (others => '0'); -- nios_custom_instruction_slave_0.dataa
		datab  : in  std_logic_vector(31 downto 0) := (others => '0'); --                                .datab
		result : out std_logic_vector(31 downto 0);                    --                                .result
		clk    : in  std_logic                     := '0';             --                                .clk
		clk_en : in  std_logic                     := '0';             --                                .clk_en
		reset  : in  std_logic                     := '0';             --                                .reset
		start  : in  std_logic                     := '0';             --                                .start
		done   : out std_logic;                                        --                                .done
		n      : in  std_logic_vector(2 downto 0)  := (others => '0')  --                                .n
	);
end entity nios2_fast_fpu_pixelsimd_inst;

architecture rtl of nios2_fast_fpu_pixelsimd_inst is
	component pixelsimd is
		port (
			dataa  : in  std_logic_vector(31 downto 0) := (others => 'X'); -- dataa
			datab  : in  std_logic_vector(31 downto 0) := (others => 'X'); -- datab
			result : out std_logic_vector(31 downto 0);                    -- result
			clk    : in  std_logic                     := 'X';             -- clk
			clk_en : in  std_logic                     := 'X';             -- clk_en
			reset  : in  std_logic                     := 'X';             -- reset
			start  : in  std_logic                     := 'X';             -- start
			done   : out std_logic;                                        -- done
			n      : in  std_logic_vector(2 downto 0)  := (others => 'X')  -- n
		);
	end component pixelsimd;

begin

	nios2_fast_fpu_pixelsimd_inst : component pixelsimd
		port map (
			dataa  => dataa,  -- nios_custom_instruction_slave_0.dataa
			datab  => datab,  --                                .datab
			result => result, --                                .result
			clk    => clk,    --                                .clk
			clk_en => clk_en, --                                .clk_en
			reset  => reset,  --                                .reset
			start  => start,  --                                .start
			done   => done,   --                                .done
			n      => n       --                                .n
		);

end architecture rtl; -- of nios2_fast_fpu_pixelsimd_inst
