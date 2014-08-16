-- Terasic DE0 Top Module for DE0_ULEXITE

library ieee;
use ieee.std_logic_1164.all;

entity DE0_top is
port (
  -- Clock
  CLOCK_50_0    : in    std_logic;
  CLOCK_50_1    : in    std_logic;

  -- LED
  LED           : out   std_logic_vector(9 downto 0);

  -- 7-segment LED
  HEX0_D        : out   std_logic_vector(6 downto 0) := (others => '0');
  HEX0_DP       : out   std_logic := '0';
  HEX1_D        : out   std_logic_vector(6 downto 0) := (others => '0');
  HEX1_DP       : out   std_logic := '0';
  HEX2_D        : out   std_logic_vector(6 downto 0) := (others => '0');
  HEX2_DP       : out   std_logic := '0';
  HEX3_D        : out   std_logic_vector(6 downto 0) := (others => '0');
  HEX3_DP       : out   std_logic := '0';

  -- LCD
  LCD_BLON      : out   std_logic := '0';
  LCD_RW        : out   std_logic := '0';
  LCD_EN        : out   std_logic := '0';
  LCD_RS        : out   std_logic;
  LCD_D         : inout std_logic_vector(7 downto 0);

  -- Push switch
  SW            : in    std_logic_vector(9 downto 0);

  -- DIP switch
  BUTTON        : in    std_logic_vector(2 downto 0);

  -- SDR-SDRAM
  DRAM_A        : out   std_logic_vector(12 downto 0);
  DRAM_BA       : out   std_logic_vector(1 downto 0);
  DRAM_CAS_N    : out   std_logic := '1';
  DRAM_CKE      : out   std_logic;
  DRAM_CLK      : out   std_logic;
  DRAM_CS_N     : out   std_logic := '1';
  DRAM_D        : inout std_logic_vector(15 downto 0);
  DRAM_DQM      : out   std_logic_vector(1 downto 0);
  DRAM_RAS_N    : out   std_logic := '1';
  DRAM_WE_N     : out   std_logic := '1';

  -- Parallel Flash
  FLASH_D       : inout std_logic_vector(14 downto 0);
  FLASH_D15_AM1 : inout std_logic;
  FLASH_A       : out   std_logic_vector(21 downto 0);
  FLASH_WE_N    : out   std_logic := '1';
  FLASH_RESET_N : out   std_logic := '1';
  FLASH_WP_N    : out   std_logic := '1';
  FLASH_CE_N    : out   std_logic := '1';
  FLASH_OE_N    : out   std_logic := '1';
  FLASH_RY      : in    std_logic;
  FLASH_BYTE_N  : out   std_logic := '1';

  -- EPCS Flash
  EPCS_ASDO     : out   std_logic;
  EPCS_DATA0    : in    std_logic;
  EPCS_DCLK     : out   std_logic;
  EPCS_NCSO     : out   std_logic;

  -- VGA
  VGA_HS        : out   std_logic := '0';
  VGA_VS        : out   std_logic := '0';
  VGA_R         : out   std_logic_vector(3 downto 0);
  VGA_G         : out   std_logic_vector(3 downto 0);
  VGA_B         : out   std_logic_vector(3 downto 0);

  -- UART
  UART_RXD      : in    std_logic;
  UART_TXD      : out   std_logic := '0';
  UART_RTS      : in    std_logic;
  UART_CTS      : out   std_logic := '1';

  -- SD Card
  SD_CLK        : out   std_logic;
  SD_CMD        : inout std_logic;
  SD_DAT        : inout std_logic_vector(3 downto 0);
  SD_WP_N       : in    std_logic;

  -- PS/2
  PS2_KBDAT     : inout std_logic;
  PS2_KBCLK     : inout std_logic;
  PS2_MSDAT     : inout std_logic;
  PS2_MSCLK     : inout std_logic;

  -- GPIO 0
  GPIO0_D       : inout std_logic_vector(31 downto 0);
  GPIO0_CLKIN   : in    std_logic_vector(1 downto 0);
  GPIO0_CLKOUT  : out   std_logic_vector(1 downto 0);

  -- GPIO 1
  GPIO1_D       : inout std_logic_vector(31 downto 0);
  GPIO1_CLKIN   : in    std_logic_vector(1 downto 0);
  GPIO1_CLKOUT  : out   std_logic_vector(1 downto 0)
);
end entity DE0_top;

architecture rtl of DE0_top is

-- Signal declarations here

  component sys_pll is
    port (
      areset  : in std_logic  := '0';
      inclk0  : in std_logic  := '0';
      c0      : out std_logic;
      c1      : out std_logic;
      c2      : out std_logic;
      c3      : out std_logic;
      c4      : out std_logic;
      locked  : out std_logic
    );
  end component sys_pll;

  component DE0_sys is
    port (
      clk_core_clk           : in    std_logic                     := 'X';             -- clk
      reset_core_reset_n     : in    std_logic                     := 'X';             -- reset_n
      clk_peri_clk           : in    std_logic                     := 'X';             -- clk
      reset_peri_reset_n     : in    std_logic                     := 'X';             -- reset_n
      epcs_dclk              : out   std_logic;                                        -- dclk
      epcs_sce               : out   std_logic;                                        -- sce
      epcs_sdo               : out   std_logic;                                        -- sdo
      epcs_data0             : in    std_logic                     := 'X';             -- data0
      sdram_addr             : out   std_logic_vector(11 downto 0);                    -- addr
      sdram_ba               : out   std_logic_vector(1 downto 0);                     -- ba
      sdram_cas_n            : out   std_logic;                                        -- cas_n
      sdram_cke              : out   std_logic;                                        -- cke
      sdram_cs_n             : out   std_logic;                                        -- cs_n
      sdram_dq               : inout std_logic_vector(15 downto 0) := (others => 'X'); -- dq
      sdram_dqm              : out   std_logic_vector(1 downto 0);                     -- dqm
      sdram_ras_n            : out   std_logic;                                        -- ras_n
      sdram_we_n             : out   std_logic;                                        -- we_n
      lcd_lcd_disp           : out   std_logic;                                        -- lcd_disp
      lcd_bl_on              : out   std_logic;                                        -- bl_on
      lcd_lcd_clk            : in    std_logic                     := 'X';             -- lcd_clk
      lcd_lcd_de             : out   std_logic;                                        -- lcd_de
      lcd_lcd_r              : out   std_logic_vector(7 downto 0);                     -- lcd_r
      lcd_lcd_g              : out   std_logic_vector(7 downto 0);                     -- lcd_g
      lcd_lcd_b              : out   std_logic_vector(7 downto 0);                     -- lcd_b
      lcd_bl_pwm             : out   std_logic;                                        -- bl_pwm
      usb_usbClk             : in    std_logic                     := 'X';             -- usbClk
      usb_USBWireDataIn      : in    std_logic_vector(1 downto 0)  := (others => 'X'); -- USBWireDataIn
      usb_USBWireDataInTick  : out   std_logic;                                        -- USBWireDataInTick
      usb_USBWireDataOut     : out   std_logic_vector(1 downto 0);                     -- USBWireDataOut
      usb_USBWireDataOutTick : out   std_logic;                                        -- USBWireDataOutTick
      usb_USBWireCtrlOut     : out   std_logic;                                        -- USBWireCtrlOut
      usb_USBFullSpeed       : out   std_logic;                                        -- USBFullSpeed
      hexled_export          : out   std_logic_vector(31 downto 0);                    -- export
      mmc_nCS                : out   std_logic;                                        -- nCS
      mmc_SCK                : out   std_logic;                                        -- SCK
      mmc_SDO                : out   std_logic;                                        -- SDO
      mmc_SDI                : in    std_logic                     := 'X';             -- SDI
      mmc_CD                 : in    std_logic                     := 'X';             -- CD
      mmc_WP                 : in    std_logic                     := 'X';             -- WP
      led_export             : out   std_logic_vector(9 downto 0);                     -- export
      sw_export              : in    std_logic_vector(9 downto 0)  := (others => 'X'); -- export
      button_export          : in    std_logic_vector(1 downto 0)  := (others => 'X')  -- export
    );
  end component DE0_sys;

  signal reset_r    : std_logic_vector(1 downto 0);

  signal clk_core_w : std_logic;
  signal clk_sdr_w  : std_logic;
  signal clk_peri_w : std_logic;
  signal clk_lcd_w  : std_logic;
  signal clk_usb_w  : std_logic;
  signal locked_w   : std_logic;

  -- signal flash_a_w        : std_logic_vector(21 downto 0);
  -- signal flash_ry_w       : std_logic_vector(0 downto 0);
  -- signal flash_oe_n_w     : std_logic_vector(0 downto 0);
  -- signal flash_reset_n_w  : std_logic_vector(0 downto 0);
  -- signal flash_we_n_w     : std_logic_vector(0 downto 0);
  -- signal flash_d_w        : std_logic_vector(15 downto 0);
  -- signal flash_ce_n_w     : std_logic_vector(0 downto 0);

  signal rout_w     : std_logic_vector(7 downto 0);
  signal gout_w     : std_logic_vector(7 downto 0);
  signal bout_w     : std_logic_vector(7 downto 0);

  signal usb_din_w  : std_logic_vector(1 downto 0);
  signal usb_dout_w : std_logic_vector(1 downto 0);
  signal usb_oe_w   : std_logic;

  signal hexled_w   : std_logic_vector(31 downto 0);

  signal sd_cd_w    : std_logic;

begin -- rtl

-- Structural coding

  process (CLOCK_50_0) begin
    if (rising_edge(CLOCK_50_0)) then
      reset_r <= reset_r(reset_r'left - 1 downto 0) & (not BUTTON(0));
    end if;
  end process;

  u_pll : component sys_pll
    port map (
      areset  => reset_r(reset_r'left),
      inclk0  => CLOCK_50_0,
      c0      => clk_core_w,
      c1      => clk_sdr_w,
      c2      => clk_peri_w,
      c3      => clk_lcd_w,
      c4      => clk_usb_w,
      locked  => locked_w
    );

  u_sys : component DE0_sys
    port map (
      clk_core_clk           => clk_core_w,          --   clk_core.clk
      reset_core_reset_n     => locked_w,            -- reset_core.reset_n
      clk_peri_clk           => clk_peri_w,          --   clk_peri.clk
      reset_peri_reset_n     => locked_w,            -- reset_peri.reset_n
      epcs_dclk              => EPCS_DCLK,           --       epcs.dclk
      epcs_sce               => EPCS_NCSO,           --           .sce
      epcs_sdo               => EPCS_ASDO,           --           .sdo
      epcs_data0             => EPCS_DATA0,          --           .data0
      sdram_addr             => DRAM_A(11 downto 0), --      sdram.addr
      sdram_ba               => DRAM_BA,             --           .ba
      sdram_cas_n            => DRAM_CAS_N,          --           .cas_n
      sdram_cke              => DRAM_CKE,            --           .cke
      sdram_cs_n             => DRAM_CS_N,           --           .cs_n
      sdram_dq               => DRAM_D,              --           .dq
      sdram_dqm              => DRAM_DQM,            --           .dqm
      sdram_ras_n            => DRAM_RAS_N,          --           .ras_n
      sdram_we_n             => DRAM_WE_N,           --           .we_n
      lcd_lcd_disp           => GPIO0_D(29),         --        lcd.lcd_disp
      lcd_bl_on              => GPIO0_D(31),         --           .bl_on
      lcd_lcd_clk            => clk_lcd_w,           --           .lcd_clk
      lcd_lcd_de             => GPIO0_D(0),          --           .lcd_de
      lcd_lcd_r              => rout_w,              --           .lcd_r
      lcd_lcd_g              => gout_w,              --           .lcd_g
      lcd_lcd_b              => bout_w,              --           .lcd_b
      lcd_bl_pwm             => GPIO0_D(30),         --           .bl_pwm
      usb_usbClk             => clk_usb_w,           --        usb.usbClk
      usb_USBWireDataIn      => usb_din_w,           --           .USBWireDataIn
  --  usb_USBWireDataInTick  => null,                --           .USBWireDataInTick
      usb_USBWireDataOut     => usb_dout_w,          --           .USBWireDataOut
  --  usb_USBWireDataOutTick => null,                --           .USBWireDataOutTick
      usb_USBWireCtrlOut     => usb_oe_w,            --           .USBWireCtrlOut
  --  usb_USBFullSpeed       => null,                --           .USBFullSpeed
      hexled_export          => hexled_w,            --     hexled.export
      mmc_nCS                => GPIO1_D(22),         --        mmc.nCS
      mmc_SCK                => GPIO1_D(24),         --           .SCK
      mmc_SDO                => GPIO1_D(25),         --           .SDO
      mmc_SDI                => GPIO1_D(27),         --           .SDI
      mmc_CD                 => sd_cd_w,             --           .CD
      mmc_WP                 => '0',                 --           .WP
      led_export             => LED,                 --        led.export
      sw_export              => SW,                  --         sw.export
      button_export          => BUTTON(2 downto 1)   --     button.export
    );

  DRAM_CLK    <= clk_sdr_w;
  DRAM_A(12)  <= '0';

  -- FLASH_D       <= flash_d_w(14 downto 0);
  -- FLASH_D15_AM1 <= flash_d_w(15);
  -- FLASH_A       <= '0' & flash_a_w(21 downto 1);
  -- FLASH_WE_N    <= flash_we_n_w(0);
  -- FLASH_RESET_N <= flash_reset_n_w(0);
  -- FLASH_WP_N    <= '1';
  -- FLASH_CE_N    <= flash_ce_n_w(0);
  -- FLASH_OE_N    <= flash_oe_n_w(0);
  -- flash_ry_w(0) <= FLASH_RY;
  -- FLASH_BYTE_N  <= '1';

  GPIO0_CLKOUT(0) <= clk_lcd_w;

  GPIO0_D(20) <= rout_w(0);
  GPIO0_D(22) <= rout_w(1);
  GPIO0_D(25) <= rout_w(2);
  GPIO0_D(18) <= rout_w(3);
  GPIO0_D(23) <= rout_w(4);
  GPIO0_D(21) <= rout_w(5);
  GPIO0_D(16) <= rout_w(6);
  GPIO0_D(19) <= rout_w(7);

  GPIO0_D(17) <= gout_w(0);
  GPIO0_D(15) <= gout_w(1);
  GPIO0_D(14) <= gout_w(2);
  GPIO0_D(13) <= gout_w(3);
  GPIO0_D(12) <= gout_w(4);
  GPIO0_D(11) <= gout_w(5);
  GPIO0_D(10) <= gout_w(6);
  GPIO0_D(9)  <= gout_w(7);

  GPIO0_D(8)  <= bout_w(0);
  GPIO0_D(7)  <= bout_w(1);
  GPIO0_D(6)  <= bout_w(2);
  GPIO0_D(5)  <= bout_w(3);
  GPIO0_D(4)  <= bout_w(4);
  GPIO0_D(3)  <= bout_w(5);
  GPIO0_D(2)  <= bout_w(6);
  GPIO0_D(1)  <= bout_w(7);

  usb_din_w   <= GPIO1_D(29 downto 28);
  GPIO1_D(29 downto 28) <= usb_dout_w when usb_oe_w = '1' else "ZZ";

  HEX0_D      <= hexled_w( 6 downto  0);
  HEX0_DP     <= hexled_w( 7);
  HEX1_D      <= hexled_w(14 downto  8);
  HEX1_DP     <= hexled_w(15);
  HEX2_D      <= hexled_w(22 downto 16);
  HEX2_DP     <= hexled_w(23);
  HEX3_D      <= hexled_w(30 downto 24);
  HEX3_DP     <= hexled_w(31);

  sd_cd_w     <= not GPIO1_D(19);

end architecture rtl;
