-- mmcdma.vhd

-- This file was auto-generated as part of a generation operation.
-- If you edit it your changes will probably be lost.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mmcdma is
	port (
		clk        : in  std_logic                     := '0';             --       clock_reset.clk
		reset      : in  std_logic                     := '0';             -- clock_reset_reset.reset
		chipselect : in  std_logic                     := '0';             --                s1.chipselect
		address    : in  std_logic_vector(7 downto 0)  := (others => '0'); --                  .address
		read       : in  std_logic                     := '0';             --                  .read
		readdata   : out std_logic_vector(31 downto 0);                    --                  .readdata
		write      : in  std_logic                     := '0';             --                  .write
		writedata  : in  std_logic_vector(31 downto 0) := (others => '0'); --                  .writedata
		MMC_nCS    : out std_logic;                                        --       conduit_end.export
		MMC_SCK    : out std_logic;                                        --                  .export
		MMC_SDO    : out std_logic;                                        --                  .export
		MMC_SDI    : in  std_logic                     := '0';             --                  .export
		MMC_CD     : in  std_logic                     := '0';             --                  .export
		MMC_WP     : in  std_logic                     := '0';             --                  .export
		irq        : out std_logic                                         --  interrupt_sender.irq
	);
end entity mmcdma;

architecture rtl of mmcdma is
	component avalonif_mmcdma is
		port (
			clk        : in  std_logic                     := 'X';             -- clk
			reset      : in  std_logic                     := 'X';             -- reset
			chipselect : in  std_logic                     := 'X';             -- chipselect
			address    : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- address
			read       : in  std_logic                     := 'X';             -- read
			readdata   : out std_logic_vector(31 downto 0);                    -- readdata
			write      : in  std_logic                     := 'X';             -- write
			writedata  : in  std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
			MMC_nCS    : out std_logic;                                        -- export
			MMC_SCK    : out std_logic;                                        -- export
			MMC_SDO    : out std_logic;                                        -- export
			MMC_SDI    : in  std_logic                     := 'X';             -- export
			MMC_CD     : in  std_logic                     := 'X';             -- export
			MMC_WP     : in  std_logic                     := 'X';             -- export
			irq        : out std_logic                                         -- irq
		);
	end component avalonif_mmcdma;

begin

	mmcdma : component avalonif_mmcdma
		port map (
			clk        => clk,        --       clock_reset.clk
			reset      => reset,      -- clock_reset_reset.reset
			chipselect => chipselect, --                s1.chipselect
			address    => address,    --                  .address
			read       => read,       --                  .read
			readdata   => readdata,   --                  .readdata
			write      => write,      --                  .write
			writedata  => writedata,  --                  .writedata
			MMC_nCS    => MMC_nCS,    --       conduit_end.export
			MMC_SCK    => MMC_SCK,    --                  .export
			MMC_SDO    => MMC_SDO,    --                  .export
			MMC_SDI    => MMC_SDI,    --                  .export
			MMC_CD     => MMC_CD,     --                  .export
			MMC_WP     => MMC_WP,     --                  .export
			irq        => irq         --  interrupt_sender.irq
		);

end architecture rtl; -- of mmcdma
