--------------------------------------------------------------------------------
-- @file   console_buf.vhd
-- @brief  Console Frame Buffer (for vga_component)
-- @author kimu_shu
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

entity console_buf is
generic (
  PIXDEPTH  : integer := 16;  -- Pixel depth
  HW        : integer := 7;   -- Horizontal character address width
  VW        : integer := 6    -- Vertical character address width
);
port (
  csi_s1_clk            : in  std_logic;
  csi_s1_reset          : in  std_logic;

  avs_s1_address        : in  std_logic_vector(1 downto 0);
  avs_s1_write          : in  std_logic;
  avs_s1_writedata      : in  std_logic_vector(31 downto 0);

  csi_s2_clk            : in  std_logic;
  csi_s2_reset          : in  std_logic;

  avs_s2_address        : in  std_logic_vector(20 downto 0);
  avs_s2_read           : in  std_logic;
  avs_s2_readdata       : out std_logic_vector(PIXDEPTH-1 downto 0);
  avs_s2_readdatavalid  : out std_logic
);
end console_buf;

architecture rtl of console_buf is

  component csbuf_text is
  port (
    data      : in  std_logic_vector (8 downto 0);
    rdaddress : in  std_logic_vector (12 downto 0);
    rdclock   : in  std_logic;
    wraddress : in  std_logic_vector (12 downto 0);
    wrclock   : in  std_logic := '1';
    wren      : in  std_logic := '0';
    q         : out std_logic_vector (8 downto 0)
  );
  end component;

  component csbuf_font is
  port (
    data      : in  std_logic_vector (7 downto 0);
    rdaddress : in  std_logic_vector (10 downto 0);
    rdclock   : in  std_logic;
    wraddress : in  std_logic_vector (10 downto 0);
    wrclock   : in  std_logic := '1';
    wren      : in  std_logic := '0';
    q         : out std_logic_vector (7 downto 0)
  );
  end component;

  component csbuf_color IS
  port (
    data      : in  std_logic_vector (15 downto 0);
    rdaddress : in  std_logic_vector (3 downto 0);
    rdclock   : in  std_logic;
    wraddress : in  std_logic_vector (3 downto 0);
    wrclock   : in  std_logic := '1';
    wren      : in  std_logic := '0';
    q         : out std_logic_vector (15 downto 0)
  );
  end component;

  component csbuf_hidx is
  port (
    data      : in  std_logic_vector (11 downto 0);
    rdaddress : in  std_logic_vector (9 downto 0);
    rdclock   : in  std_logic;
    wraddress : in  std_logic_vector (9 downto 0);
    wrclock   : in  std_logic := '1';
    wren      : in  std_logic := '0';
    q         : out std_logic_vector (11 downto 0)
  );
  end component;

  component csbuf_vidx is
  port (
    data      : in  std_logic_vector (11 downto 0);
    rdaddress : in  std_logic_vector (9 downto 0);
    rdclock   : in  std_logic;
    wraddress : in  std_logic_vector (9 downto 0);
    wrclock   : in  std_logic := '1';
    wren      : in  std_logic := '0';
    q         : out std_logic_vector (11 downto 0)
  );
  end component;

  -- Signals for s1
  signal hpos_r     : std_logic_vector(HW-1 downto 0);
  signal hlimit_r   : std_logic_vector(HW-1 downto 0);
  signal vpos_r     : std_logic_vector(VW-1 downto 0);
  signal vlimit_r   : std_logic_vector(VW-1 downto 0);
  signal vwbase_r   : std_logic_vector(VW-1 downto 0);  -- vertical window base
  signal vwlimit_r  : std_logic_vector(VW-1 downto 0);
  signal bufsel_r   : std_logic_vector(1 downto 0);
  signal bufaddr_r  : std_logic_vector(10 downto 0);

  signal hnext_w    : std_logic_vector(HW-1 downto 0);
  signal vnext_w    : std_logic_vector(VW-1 downto 0);
  signal textwr_w   : std_logic;
  signal textaddr1_w  : std_logic_vector(12 downto 0);
  signal textq_w    : std_logic_vector(8 downto 0);

  signal fontwr_w   : std_logic;
  signal clrwr_w    : std_logic;
  signal hidxwr_w   : std_logic;
  signal vidxwr_w   : std_logic;

  -- Signals for s2
  signal cxy1_valid_r : std_logic;
  signal cx2_r        : std_logic_vector(HW-1 downto 0);
  signal cy2_r        : std_logic_vector(VW downto 0);
  signal px2_r        : std_logic_vector(3 downto 0);
  signal py2_r        : std_logic_vector(4 downto 0);
  signal cxy2_valid_r : std_logic;
  signal cx3_r        : std_logic_vector(HW-1 downto 0);
  signal cy3_r        : std_logic_vector(VW-1 downto 0);
  signal px3_r        : std_logic_vector(3 downto 0);
  signal py3_r        : std_logic_vector(4 downto 0);
  signal cxy3_valid_r : std_logic;
  signal char_clr4_r  : std_logic_vector(1 downto 0);
  signal px4_r        : std_logic_vector(3 downto 0);
  signal py4_r        : std_logic_vector(4 downto 0);
  signal char_valid_r : std_logic;
  signal char_clr5_r  : std_logic_vector(1 downto 0);
  signal px5_r        : std_logic_vector(3 downto 0);
  signal font_valid_r : std_logic;
  signal clr_valid_r  : std_logic;

  signal hidxq_w      : std_logic_vector(11 downto 0);
  signal vidxq_w      : std_logic_vector(11 downto 0);
  signal fontq_w      : std_logic_vector(7 downto 0);
  signal cy2adj_w     : std_logic_vector(VW downto 0);
  signal bitsel_w     : std_logic;
  signal bkgnd_w      : std_logic;
  signal textaddr2_w  : std_logic_vector(12 downto 0);
  signal fontaddr2_w  : std_logic_vector(10 downto 0);
  signal clraddr2_w   : std_logic_vector(3 downto 0);

begin -- architecture rtl

-- Register map
--
-- 0: Character write register
--    [ 8: 7] Color
--    [ 6: 0] ASCII code
--
-- 1: Position register
--    [28:23] Vertical limit
--    [22:16] Horizontal limit
--    [12: 7] Vertical position
--    [ 6: 0] Horizontal position
--
-- 2: Buffer address register
--    [12:11] Buffer select (00:font, 01:color, 10:hidx, 11:vidx)
--    [10: 0] Address
--
-- 3: Buffer data window
--    [11: 0] Data write window
--

  ------------------------------------------------------------
  -- Control port (s1) side

  hnext_w <= hpos_r + "1";
  vnext_w <= vpos_r + "1";

  process (csi_s1_clk, csi_s1_reset) begin
    if (csi_s1_reset = '1') then
      hpos_r    <= (others => '0');
      hlimit_r  <= (others => '0');
      vwbase_r  <= (others => '0');
      vwlimit_r <= (others => '0');
      vpos_r    <= (others => '0');
      vlimit_r  <= (others => '0');
      bufsel_r  <= "00";
      bufaddr_r <= (others => '0');
    elsif (rising_edge(csi_s1_clk) and avs_s1_write = '1') then
      case (avs_s1_address) is
      when "00" =>
        -- Character write
        -- 001xxxxxxxx CR
        -- 010xxxxxxxx LF
        -- 100xxxxxxxx BS
        -- 000xaaaaaaa ASCII code
        if (avs_s1_writedata(8) = '1' or hpos_r = hlimit_r) then
          -- CR or wrap
          hpos_r <= (others => '0');
        elsif (avs_s1_writedata(10) = '1') then
          -- BS
          hpos_r <= hpos_r - '1';
        elsif (avs_s1_writedata(9) /= '1') then
          -- Other character
          hpos_r <= hpos_r + '1';
        end if;
        if (avs_s1_writedata(9) = '1' or hpos_r = hlimit_r) then
          -- LF or wrap
          if (vpos_r = vlimit_r) then
            vpos_r <= (others => '0');
          else
            vpos_r <= vpos_r + '1';
          end if;
          if (vpos_r = vwlimit_r) then
            if (vpos_r = vlimit_r) then
              vwlimit_r <= (others => '0');
            else
              vwlimit_r <= vpos_r + '1';
            end if;
            if (vwbase_r = vlimit_r) then
              vwbase_r <= (others => '0');
            else
              vwbase_r <= vwbase_r + '1';
            end if;
          end if;
        elsif (avs_s1_writedata(10) = '1' and or_reduce(hpos_r) = '0') then
          -- BS
          if (or_reduce(vpos_r) = '0') then
            vpos_r <= vlimit_r;
          else
            vpos_r <= vpos_r - '1';
          end if;
        end if;
      when "01" =>
        -- Position register
        vlimit_r <= avs_s1_writedata(28 downto 23);
        hlimit_r <= avs_s1_writedata(22 downto 16);
        vpos_r   <= avs_s1_writedata(12 downto 7);
        hpos_r   <= avs_s1_writedata(6 downto 0);
        null; -- TODO
      when "10" =>
        -- Buffer address register
        bufsel_r  <= avs_s1_writedata(12 downto 11);
        bufaddr_r <= avs_s1_writedata(10 downto 0);
      when others =>
        -- Buffer data window
        bufaddr_r <= bufaddr_r + "1";
      end case;
    end if;
  end process;

--  vpos増やすとき(改行or右隅で文字挿入)
--    vpos = (vpos == limit) ? 0 : vpos + 1;
--    if(vpos == limit) scroll = 1
--  vpos減らすとき(左端でBackspace)
--    vpos = (vpos == 0) ? limit : vpos - 1;
--    scroll = 0
--  0
--  1 vbase  | wbase
--  2        |
--  3        |
--  4 limit  |
--  0        | wlimit

  textwr_w <= '1'
    when (avs_s1_write = '1') and (avs_s1_address = "00") and
          (avs_s1_writedata(6 downto 4) /= "000")
    else '0';
  textaddr1_w <= vpos_r & hpos_r;

  fontwr_w <= '1'
    when (avs_s1_write = '1') and (avs_s1_address = "11") and (bufsel_r = "00")
    else '0';
  clrwr_w <= '1'
    when (avs_s1_write = '1') and (avs_s1_address = "11") and (bufsel_r = "01")
    else '0';
  hidxwr_w <= '1'
    when (avs_s1_write = '1') and (avs_s1_address = "11") and (bufsel_r = "10")
    else '0';
  vidxwr_w <= '1'
    when (avs_s1_write = '1') and (avs_s1_address = "11") and (bufsel_r = "11")
    else '0';

  ------------------------------------------------------------
  -- RAMs

  -- Address format
  -- YYYYYYXXXXXXX
  -- (X) X position
  -- (Y) Y position
  u_text : csbuf_text
  port map (
    data      => avs_s1_writedata(8 downto 0),
    wraddress => textaddr1_w,
    wrclock   => csi_s1_clk,
    wren      => textwr_w,
    rdaddress => (others => '0'),
    rdclock   => csi_s2_clk,
    q         => textq_w
  );

  -- Address format
  -- AAAAAAALLLL
  -- (A) ASCII code
  -- (L) Line number
  u_font : csbuf_font
  port map (
    data      => avs_s1_writedata(7 downto 0),
    wraddress => bufaddr_r(10 downto 0),
    wrclock   => csi_s1_clk,
    wren      => fontwr_w,
    rdaddress => fontaddr2_w,
    rdclock   => csi_s2_clk,
    q         => fontq_w
  );

  -- Address format
  -- 0III
  -- (I) Color number (0-4)
  u_color : csbuf_color
  port map (
    data      => avs_s1_writedata(15 downto 0),
    wraddress => bufaddr_r(3 downto 0),
    wrclock   => csi_s1_clk,
    wren      => clrwr_w,
    rdaddress => clraddr2_w,
    rdclock   => csi_s2_clk,
    q         => avs_s2_readdata
  );

  -- Address format
  -- 0CCCCCCCNPPP
  -- (C) Character position
  -- (N) Non character
  -- (P) Pixel position
  u_hidx : csbuf_hidx
  port map (
    data      => avs_s1_writedata(11 downto 0),
    wraddress => bufaddr_r(9 downto 0),
    wrclock   => csi_s1_clk,
    wren      => hidxwr_w,
    rdaddress => avs_s2_address(9 downto 0),
    rdclock   => csi_s2_clk,
    q         => hidxq_w
  );

  -- Address format
  -- 0CCCCCCNPPPP
  -- (C) Character position
  -- (N) Non character
  -- (P) Pixel position
  u_vidx : csbuf_vidx
  port map (
    data      => avs_s1_writedata(11 downto 0),
    wraddress => bufaddr_r(9 downto 0),
    wrclock   => csi_s1_clk,
    wren      => vidxwr_w,
    rdaddress => avs_s2_address(19 downto 10),
    rdclock   => csi_s2_clk,
    q         => vidxq_w
  );

  ------------------------------------------------------------
  -- Memory port (s2) side

  process (csi_s2_clk, csi_s2_reset) begin
    if (csi_s2_reset = '1') then
      cxy1_valid_r  <= '0';
      cx2_r         <= (others => '0');
      cy2_r         <= (others => '0');
      px2_r         <= (others => '0');
      py2_r         <= (others => '0');
      cxy2_valid_r  <= '0';
      cx3_r         <= (others => '0');
      cy3_r         <= (others => '0');
      px3_r         <= (others => '0');
      py3_r         <= (others => '0');
      cxy3_valid_r  <= '0';
      char_clr4_r   <= (others => '0');
      px4_r         <= (others => '0');
      py4_r         <= (others => '0');
      char_valid_r  <= '0';
      char_clr5_r   <= (others => '0');
      px5_r         <= (others => '0');
      font_valid_r  <= '0';
      clr_valid_r   <= '0';
    else
      cxy1_valid_r <= avs_s2_read;

      cx2_r <= hidxq_w(10 downto 4);
      cy2_r <= ('0' & vidxq_w(10 downto 5)) + vwbase_r;
      px2_r <= hidxq_w(3 downto 0);
      py2_r <= vidxq_w(4 downto 0);
      cxy2_valid_r <= cxy1_valid_r;

      cx3_r <= cx2_r;
      if (cy2adj_w(VW) = '1') then
        cy3_r <= cy2_r(VW-1 downto 0);
      else
        cy3_r <= cy2adj_w(VW-1 downto 0);
      end if;
      px3_r <= px2_r;
      py3_r <= py2_r;
      cxy3_valid_r <= cxy2_valid_r;

      px4_r <= px3_r;
      py4_r <= py3_r;
      char_clr4_r <= textq_w(8 downto 7);
      char_valid_r <= cxy3_valid_r;

      px5_r(2 downto 0) <= px4_r(2 downto 0);
      px5_r(3) <= px4_r(3) or py4_r(4);
      char_clr5_r <= char_clr4_r;
      font_valid_r <= char_valid_r;

      clr_valid_r <= font_valid_r;
    end if;
  end process;

  cy2adj_w <= cy2_r - vlimit_r - '1';
  textaddr2_w <= cy3_r & cx3_r;
  avs_s2_readdatavalid <= clr_valid_r;

  with px5_r(2 downto 0) select
    bitsel_w <= fontq_w(7) when "000",
                fontq_w(6) when "001",
                fontq_w(5) when "010",
                fontq_w(4) when "011",
                fontq_w(3) when "100",
                fontq_w(2) when "101",
                fontq_w(1) when "110",
                fontq_w(0) when others;

  bkgnd_w <= px5_r(3) or (not bitsel_w);

  fontaddr2_w <= textq_w(6 downto 0) & py4_r(3 downto 0);
  clraddr2_w <= '0' & bkgnd_w & char_clr5_r;

end rtl;

