-- spu.vhd

-- This file was auto-generated as part of a generation operation.
-- If you edit it your changes will probably be lost.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spu is
	port (
		csi_global_clock     : in  std_logic                     := '0';             --       global.clk
		csi_global_reset     : in  std_logic                     := '0';             -- global_reset.reset
		csi_m1_clock         : in  std_logic                     := '0';             --     m1_clock.clk
		avm_m1_address       : out std_logic_vector(24 downto 0);                    --           m1.address
		avm_m1_burstcount    : out std_logic_vector(2 downto 0);                     --             .burstcount
		avm_m1_read          : out std_logic;                                        --             .read
		avm_m1_readdata      : in  std_logic_vector(15 downto 0) := (others => '0'); --             .readdata
		avm_m1_readdatavalid : in  std_logic                     := '0';             --             .readdatavalid
		avm_m1_waitrequest   : in  std_logic                     := '0';             --             .waitrequest
		avs_s1_address       : in  std_logic_vector(8 downto 0)  := (others => '0'); --           s1.address
		avs_s1_chipselect    : in  std_logic                     := '0';             --             .chipselect
		avs_s1_read          : in  std_logic                     := '0';             --             .read
		avs_s1_write         : in  std_logic                     := '0';             --             .write
		avs_s1_byteenable    : in  std_logic_vector(3 downto 0)  := (others => '0'); --             .byteenable
		avs_s1_readdata      : out std_logic_vector(31 downto 0);                    --             .readdata
		avs_s1_writedata     : in  std_logic_vector(31 downto 0) := (others => '0'); --             .writedata
		avs_s1_waitrequest   : out std_logic;                                        --             .waitrequest
		avs_s1_irq           : out std_logic;                                        --       irq_s1.irq
		clk_128fs            : in  std_logic                     := '0';             --  conduit_end.export
		DAC_BCLK             : out std_logic;                                        --             .export
		DAC_LRCK             : out std_logic;                                        --             .export
		DAC_DATA             : out std_logic;                                        --             .export
		AUD_L                : out std_logic;                                        --             .export
		AUD_R                : out std_logic;                                        --             .export
		SPDIF                : out std_logic                                         --             .export
	);
end entity spu;

architecture rtl of spu is
	component avalonif_spu is
		port (
			csi_global_clock     : in  std_logic                     := 'X';             -- clk
			csi_global_reset     : in  std_logic                     := 'X';             -- reset
			csi_m1_clock         : in  std_logic                     := 'X';             -- clk
			avm_m1_address       : out std_logic_vector(24 downto 0);                    -- address
			avm_m1_burstcount    : out std_logic_vector(2 downto 0);                     -- burstcount
			avm_m1_read          : out std_logic;                                        -- read
			avm_m1_readdata      : in  std_logic_vector(15 downto 0) := (others => 'X'); -- readdata
			avm_m1_readdatavalid : in  std_logic                     := 'X';             -- readdatavalid
			avm_m1_waitrequest   : in  std_logic                     := 'X';             -- waitrequest
			avs_s1_address       : in  std_logic_vector(8 downto 0)  := (others => 'X'); -- address
			avs_s1_chipselect    : in  std_logic                     := 'X';             -- chipselect
			avs_s1_read          : in  std_logic                     := 'X';             -- read
			avs_s1_write         : in  std_logic                     := 'X';             -- write
			avs_s1_byteenable    : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- byteenable
			avs_s1_readdata      : out std_logic_vector(31 downto 0);                    -- readdata
			avs_s1_writedata     : in  std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
			avs_s1_waitrequest   : out std_logic;                                        -- waitrequest
			avs_s1_irq           : out std_logic;                                        -- irq
			clk_128fs            : in  std_logic                     := 'X';             -- export
			DAC_BCLK             : out std_logic;                                        -- export
			DAC_LRCK             : out std_logic;                                        -- export
			DAC_DATA             : out std_logic;                                        -- export
			AUD_L                : out std_logic;                                        -- export
			AUD_R                : out std_logic;                                        -- export
			SPDIF                : out std_logic                                         -- export
		);
	end component avalonif_spu;

begin

	spu : component avalonif_spu
		port map (
			csi_global_clock     => csi_global_clock,     --       global.clk
			csi_global_reset     => csi_global_reset,     -- global_reset.reset
			csi_m1_clock         => csi_m1_clock,         --     m1_clock.clk
			avm_m1_address       => avm_m1_address,       --           m1.address
			avm_m1_burstcount    => avm_m1_burstcount,    --             .burstcount
			avm_m1_read          => avm_m1_read,          --             .read
			avm_m1_readdata      => avm_m1_readdata,      --             .readdata
			avm_m1_readdatavalid => avm_m1_readdatavalid, --             .readdatavalid
			avm_m1_waitrequest   => avm_m1_waitrequest,   --             .waitrequest
			avs_s1_address       => avs_s1_address,       --           s1.address
			avs_s1_chipselect    => avs_s1_chipselect,    --             .chipselect
			avs_s1_read          => avs_s1_read,          --             .read
			avs_s1_write         => avs_s1_write,         --             .write
			avs_s1_byteenable    => avs_s1_byteenable,    --             .byteenable
			avs_s1_readdata      => avs_s1_readdata,      --             .readdata
			avs_s1_writedata     => avs_s1_writedata,     --             .writedata
			avs_s1_waitrequest   => avs_s1_waitrequest,   --             .waitrequest
			avs_s1_irq           => avs_s1_irq,           --       irq_s1.irq
			clk_128fs            => clk_128fs,            --  conduit_end.export
			DAC_BCLK             => DAC_BCLK,             --             .export
			DAC_LRCK             => DAC_LRCK,             --             .export
			DAC_DATA             => DAC_DATA,             --             .export
			AUD_L                => AUD_L,                --             .export
			AUD_R                => AUD_R,                --             .export
			SPDIF                => SPDIF                 --             .export
		);

end architecture rtl; -- of spu
