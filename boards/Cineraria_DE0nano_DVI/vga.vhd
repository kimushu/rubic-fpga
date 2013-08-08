-- vga.vhd

-- This file was auto-generated as part of a generation operation.
-- If you edit it your changes will probably be lost.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity vga is
	port (
		csi_m1_clk           : in  std_logic                     := '0';             --       master_clock.clk
		csi_m1_reset         : in  std_logic                     := '0';             -- master_clock_reset.reset
		csi_s1_clk           : in  std_logic                     := '0';             --        slave_clock.clk
		video_clk            : in  std_logic                     := '0';             --                ext.export
		video_rout           : out std_logic_vector(4 downto 0);                     --                   .export
		video_gout           : out std_logic_vector(4 downto 0);                     --                   .export
		video_bout           : out std_logic_vector(4 downto 0);                     --                   .export
		video_hsync_n        : out std_logic;                                        --                   .export
		video_vsync_n        : out std_logic;                                        --                   .export
		video_enable         : out std_logic;                                        --                   .export
		avm_m1_address       : out std_logic_vector(31 downto 0);                    --                 m1.address
		avm_m1_waitrequest   : in  std_logic                     := '0';             --                   .waitrequest
		avm_m1_burstcount    : out std_logic_vector(9 downto 0);                     --                   .burstcount
		avm_m1_read          : out std_logic;                                        --                   .read
		avm_m1_readdata      : in  std_logic_vector(31 downto 0) := (others => '0'); --                   .readdata
		avm_m1_readdatavalid : in  std_logic                     := '0';             --                   .readdatavalid
		avs_s1_address       : in  std_logic_vector(1 downto 0)  := (others => '0'); --                 s1.address
		avs_s1_read          : in  std_logic                     := '0';             --                   .read
		avs_s1_readdata      : out std_logic_vector(31 downto 0);                    --                   .readdata
		avs_s1_write         : in  std_logic                     := '0';             --                   .write
		avs_s1_writedata     : in  std_logic_vector(31 downto 0) := (others => '0'); --                   .writedata
		irq_s1               : out std_logic                                         --                irq.irq
	);
end entity vga;

architecture rtl of vga is
	component vga_component is
		generic (
			LINEOFFSETBYTES : integer := 2048;
			H_TOTAL         : integer := 800;
			H_SYNC          : integer := 96;
			H_BACKP         : integer := 48;
			H_ACTIVE        : integer := 640;
			V_TOTAL         : integer := 525;
			V_SYNC          : integer := 2;
			V_BACKP         : integer := 33;
			V_ACTIVE        : integer := 480
		);
		port (
			csi_m1_clk           : in  std_logic                     := 'X';             -- clk
			csi_m1_reset         : in  std_logic                     := 'X';             -- reset
			csi_s1_clk           : in  std_logic                     := 'X';             -- clk
			video_clk            : in  std_logic                     := 'X';             -- export
			video_rout           : out std_logic_vector(4 downto 0);                     -- export
			video_gout           : out std_logic_vector(4 downto 0);                     -- export
			video_bout           : out std_logic_vector(4 downto 0);                     -- export
			video_hsync_n        : out std_logic;                                        -- export
			video_vsync_n        : out std_logic;                                        -- export
			video_enable         : out std_logic;                                        -- export
			avm_m1_address       : out std_logic_vector(31 downto 0);                    -- address
			avm_m1_waitrequest   : in  std_logic                     := 'X';             -- waitrequest
			avm_m1_burstcount    : out std_logic_vector(9 downto 0);                     -- burstcount
			avm_m1_read          : out std_logic;                                        -- read
			avm_m1_readdata      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- readdata
			avm_m1_readdatavalid : in  std_logic                     := 'X';             -- readdatavalid
			avs_s1_address       : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- address
			avs_s1_read          : in  std_logic                     := 'X';             -- read
			avs_s1_readdata      : out std_logic_vector(31 downto 0);                    -- readdata
			avs_s1_write         : in  std_logic                     := 'X';             -- write
			avs_s1_writedata     : in  std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
			irq_s1               : out std_logic                                         -- irq
		);
	end component vga_component;

begin

	vga : component vga_component
		generic map (
			LINEOFFSETBYTES => 2048,
			H_TOTAL         => 1344,
			H_SYNC          => 17,
			H_BACKP         => 20,
			H_ACTIVE        => 1024,
			V_TOTAL         => 806,
			V_SYNC          => 6,
			V_BACKP         => 29,
			V_ACTIVE        => 768
		)
		port map (
			csi_m1_clk           => csi_m1_clk,           --       master_clock.clk
			csi_m1_reset         => csi_m1_reset,         -- master_clock_reset.reset
			csi_s1_clk           => csi_s1_clk,           --        slave_clock.clk
			video_clk            => video_clk,            --                ext.export
			video_rout           => video_rout,           --                   .export
			video_gout           => video_gout,           --                   .export
			video_bout           => video_bout,           --                   .export
			video_hsync_n        => video_hsync_n,        --                   .export
			video_vsync_n        => video_vsync_n,        --                   .export
			video_enable         => video_enable,         --                   .export
			avm_m1_address       => avm_m1_address,       --                 m1.address
			avm_m1_waitrequest   => avm_m1_waitrequest,   --                   .waitrequest
			avm_m1_burstcount    => avm_m1_burstcount,    --                   .burstcount
			avm_m1_read          => avm_m1_read,          --                   .read
			avm_m1_readdata      => avm_m1_readdata,      --                   .readdata
			avm_m1_readdatavalid => avm_m1_readdatavalid, --                   .readdatavalid
			avs_s1_address       => avs_s1_address,       --                 s1.address
			avs_s1_read          => avs_s1_read,          --                   .read
			avs_s1_readdata      => avs_s1_readdata,      --                   .readdata
			avs_s1_write         => avs_s1_write,         --                   .write
			avs_s1_writedata     => avs_s1_writedata,     --                   .writedata
			irq_s1               => irq_s1                --                irq.irq
		);

end architecture rtl; -- of vga
