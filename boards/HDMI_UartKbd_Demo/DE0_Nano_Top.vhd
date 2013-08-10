-- Terasic DE0-Nano Top Module Template

library ieee;
use ieee.std_logic_1164.all;

entity DE0_Nano_Top is
port (
  -- Clock
  CLOCK_50      : in    std_logic;

  -- LED
  LED           : out   std_logic_vector(7 downto 0);

  -- Push switch
  KEY           : in    std_logic_vector(1 downto 0);

  -- DIP switch
  SW            : in    std_logic_vector(3 downto 0);

  -- SDR-SDRAM
  DRAM_ADDR     : out   std_logic_vector(12 downto 0);
  DRAM_BA       : out   std_logic_vector(1 downto 0);
  DRAM_CAS_N    : out   std_logic;
  DRAM_CKE      : out   std_logic;
  DRAM_CLK      : out   std_logic;
  DRAM_CS_N     : out   std_logic;
  DRAM_DQ       : inout std_logic_vector(15 downto 0);
  DRAM_DQM      : out   std_logic_vector(1 downto 0);
  DRAM_RAS_N    : out   std_logic;
  DRAM_WE_N     : out   std_logic;

  -- EPCS Flash
  EPCS_ASDO     : out   std_logic;
  EPCS_DATA0    : in    std_logic;
  EPCS_DCLK     : out   std_logic;
  EPCS_NCSO     : out   std_logic;

  -- Accelerometer and EEPROM
  G_SENSOR_CS_N : out   std_logic;
  G_SENSOR_INT  : in    std_logic;
  I2C_SCLK      : out   std_logic;
  I2C_SDAT      : inout std_logic;

  -- ADC
  ADC_CS_N      : out   std_logic;
  ADC_SADDR     : out   std_logic;
  ADC_SCLK      : out   std_logic;
  ADC_SDAT      : in    std_logic;

  -- 2x13 GPIO Header
  GPIO_2        : inout std_logic_vector(12 downto 0);
  GPIO_2_IN     : in    std_logic_vector(2 downto 0);

  -- GPIO_0
  GPIO_0        : inout std_logic_vector(33 downto 0);
  GPIO_0_IN     : in    std_logic_vector(1 downto 0);

  -- GPIO_1
  GPIO_1        : inout std_logic_vector(33 downto 0);
  GPIO_1_IN     : in    std_logic_vector(1 downto 0)
);
end entity;

architecture rtl of DE0_Nano_Top is

    component hdmi_uartkbd is
        port (
            core_clk_clk       : in    std_logic                     := 'X';             -- clk
            core_reset_reset_n : in    std_logic                     := 'X';             -- reset_n
            peri_clk_clk       : in    std_logic                     := 'X';             -- clk
            peri_reset_reset_n : in    std_logic                     := 'X';             -- reset_n
            epcs_dclk          : out   std_logic;                                        -- dclk
            epcs_sce           : out   std_logic;                                        -- sce
            epcs_sdo           : out   std_logic;                                        -- sdo
            epcs_data0         : in    std_logic                     := 'X';             -- data0
            sdram_addr         : out   std_logic_vector(12 downto 0);                    -- addr
            sdram_ba           : out   std_logic_vector(1 downto 0);                     -- ba
            sdram_cas_n        : out   std_logic;                                        -- cas_n
            sdram_cke          : out   std_logic;                                        -- cke
            sdram_cs_n         : out   std_logic;                                        -- cs_n
            sdram_dq           : inout std_logic_vector(15 downto 0) := (others => 'X'); -- dq
            sdram_dqm          : out   std_logic_vector(1 downto 0);                     -- dqm
            sdram_ras_n        : out   std_logic;                                        -- ras_n
            sdram_we_n         : out   std_logic;                                        -- we_n
            led_export         : out   std_logic_vector(7 downto 0);                     -- export
            uartkbd_rxd        : in    std_logic                     := 'X';             -- rxd
            uartkbd_txd        : out   std_logic;                                        -- txd
            dipsw_export       : in    std_logic_vector(3 downto 0)  := (others => 'X'); -- export
            vga_clk            : in    std_logic                     := 'X';             -- clk
            vga_rout           : out   std_logic_vector(4 downto 0);                     -- rout
            vga_gout           : out   std_logic_vector(4 downto 0);                     -- gout
            vga_bout           : out   std_logic_vector(4 downto 0);                     -- bout
            vga_hsync_n        : out   std_logic;                                        -- hsync_n
            vga_vsync_n        : out   std_logic;                                        -- vsync_n
            vga_enable         : out   std_logic                                         -- enable
        );
    end component hdmi_uartkbd;

component syspll is
    port
    (
        inclk0      : in std_logic  := '0';
        c0      : out std_logic ;
        c1      : out std_logic ;
        c2      : out std_logic ;
        locked      : out std_logic 
    );
end component syspll;

component vgapll is
    port
    (
        inclk0      : in std_logic  := '0';
        c0      : out std_logic ;
        locked      : out std_logic 
    );
end component vgapll;

component dvi_tx_pdiff is
    generic(
        RESET_LEVEL     : std_logic := '1'; -- Positive logic reset
        RESOLUTION      : string := "VGA"   -- 25.175MHz
--      RESOLUTION      : string := "SVGA"  -- 40.000MHz
--      RESOLUTION      : string := "XGA"   -- 65.000MHz
--      RESOLUTION      : string := "ERRORTEST"
    );
    port(
        reset       : in  std_logic;
        clk         : in  std_logic;        -- Rise edge drive clock

        dvi_de      : in  std_logic;
        dvi_blu     : in  std_logic_vector(4 downto 0);
        dvi_grn     : in  std_logic_vector(4 downto 0);
        dvi_red     : in  std_logic_vector(4 downto 0);
        dvi_hsync   : in  std_logic;
        dvi_vsync   : in  std_logic;
        dvi_ctl     : in  std_logic_vector(3 downto 0) :="0000";

        data0_p     : out std_logic;
        data0_n     : out std_logic;
        data1_p     : out std_logic;
        data1_n     : out std_logic;
        data2_p     : out std_logic;
        data2_n     : out std_logic;
        clock_p     : out std_logic;
        clock_n     : out std_logic
    );
end component dvi_tx_pdiff;

-- Signal declarations here

signal sysreset_n_w : std_logic;
signal sysreset_w   : std_logic;
signal core_clk_w   : std_logic;
signal peri_clk_w   : std_logic;
signal vga_clk_w    : std_logic;
signal vga_enable_w : std_logic;
signal vga_hsync_w  : std_logic;
signal vga_vsync_w  : std_logic;
signal vga_rdata_w  : std_logic_vector(4 downto 0);
signal vga_gdata_w  : std_logic_vector(4 downto 0);
signal vga_bdata_w  : std_logic_vector(4 downto 0);
signal kbd_rx_w     : std_logic;
signal kbd_tx_w     : std_logic;

begin -- rtl

-- Structural coding
  kbd_rx_w <= GPIO_0(32);
  GPIO_0(33) <= kbd_tx_w;

    u0 : component hdmi_uartkbd
        port map (
            core_clk_clk       => core_clk_w,                      --   core_clk.clk
            core_reset_reset_n => sysreset_n_w,                    -- core_reset.reset_n
            peri_clk_clk       => peri_clk_w,                      --   peri_clk.clk
            peri_reset_reset_n => '1',                             -- peri_reset.reset_n
            epcs_dclk          => EPCS_DCLK,                       --       epcs.dclk
            epcs_sce           => EPCS_NCSO,                       --           .sce
            epcs_sdo           => EPCS_ASDO,                       --           .sdo
            epcs_data0         => EPCS_DATA0,                      --           .data0
            sdram_addr         => DRAM_ADDR,                       --      sdram.addr
            sdram_ba           => DRAM_BA,                         --           .ba
            sdram_cas_n        => DRAM_CAS_N,                      --           .cas_n
            sdram_cke          => DRAM_CKE,                        --           .cke
            sdram_cs_n         => DRAM_CS_N,                       --           .cs_n
            sdram_dq           => DRAM_DQ,                         --           .dq
            sdram_dqm          => DRAM_DQM,                        --           .dqm
            sdram_ras_n        => DRAM_RAS_N,                      --           .ras_n
            sdram_we_n         => DRAM_WE_N,                       --           .we_n
            led_export         => LED,                             --        led.export
            uartkbd_rxd        => kbd_rx_w,                        --    uartkbd.rxd
            uartkbd_txd        => kbd_tx_w,                        --           .txd
            dipsw_export       => SW,                              --      dipsw.export
            vga_clk            => vga_clk_w,                       --        vga.clk
            vga_rout           => vga_rdata_w,                     --           .rout
            vga_gout           => vga_gdata_w,                     --           .gout
            vga_bout           => vga_bdata_w,                     --           .bout
            vga_hsync_n        => vga_hsync_w,                     --           .hsync_n
            vga_vsync_n        => vga_vsync_w,                     --           .vsync_n
            vga_enable         => vga_enable_w                     --           .enable
        );
  u_syspll : syspll
    port map
    (
        inclk0  => CLOCK_50,
        c0      => core_clk_w,
        c1      => DRAM_CLK,
        c2      => peri_clk_w,
        locked  => sysreset_n_w
    );

  u_vgapll : vgapll
    port map
    (
        inclk0  => CLOCK_50,
        c0      => vga_clk_w
--      locked  => 
    );

  u_dvi : dvi_tx_pdiff
    generic map (
        RESOLUTION  => "XGA"
    )
    port map (
        reset       => sysreset_w,
        clk         => vga_clk_w,

        dvi_de      => vga_enable_w,
        dvi_blu     => vga_bdata_w,
        dvi_grn     => vga_gdata_w,
        dvi_red     => vga_rdata_w,
        dvi_hsync   => vga_hsync_w,
        dvi_vsync   => vga_vsync_w,
        dvi_ctl     => (others => '0'),

        data0_p     => GPIO_1(12),
        data0_n     => GPIO_1(13),
        data1_p     => GPIO_1(19),
        data1_n     => GPIO_1(18),
        data2_p     => GPIO_1(23),
        data2_n     => GPIO_1(22),
        clock_p     => GPIO_1(8),
        clock_n     => GPIO_1(9)
    );

end architecture;
