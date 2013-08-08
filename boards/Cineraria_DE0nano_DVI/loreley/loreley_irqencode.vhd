----------------------------------------------------------------------
-- TITLE : Loreley IRQ flag register & Priority encoder
--
--     VERFASSER : S.OSAFUNE (J-7SYSTEM Works)
--     DATUM     : 2005/04/07 -> 2005/04/07 (HERSTELLUNG)
--               : 2005/04/07 (FESTSTELLUNG)
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity loreley_irqencode is
	generic(
		CLOCK_EDGE		: std_logic := '1';	-- Rise edge drive clock
		RESET_LEVEL		: std_logic := '1';	-- Positive logic reset

		SLOTNUM_WIDTH	: integer := 7		-- Slot Number width(7,6,5)
	);
	port(
		clk				: in  std_logic;	-- system clock
		reset			: in  std_logic :='0';	-- async reset

		irqslot_setaddr	: in  std_logic_vector(SLOTNUM_WIDTH-1 downto 0);
		irqslot_set		: in  std_logic;
		irqslot_clraddr	: in  std_logic_vector(SLOTNUM_WIDTH-1 downto 0);
		irqslot_clr		: in  std_logic;

		irqslot_req		: out std_logic;
		irqslot_num		: out std_logic_vector(6 downto 0)
	);
end loreley_irqencode;

architecture RTL of loreley_irqencode is
	type IRQ_STATE is (ENTRY,ENC0,ENC1,DET0,DET1,DET2,DET3, HALT);
	signal state : IRQ_STATE;
	signal irqslotreq_reg	: std_logic;
	signal irqslotnum_reg	: std_logic_vector(6 downto 0);

	signal irqsetaddr_reg	: std_logic_vector(SLOTNUM_WIDTH-1 downto 0);
	signal irqsetena_reg	: std_logic;
	signal irqclraddr_reg	: std_logic_vector(SLOTNUM_WIDTH-1 downto 0);
	signal irqclrena_reg	: std_logic;
	signal irqbit_reg		: std_logic_vector((2**SLOTNUM_WIDTH)-1 downto 0);
	signal irqbit_sig		: std_logic_vector(128 downto 0);


	component loreley_irqencode_32bitenc
	generic(
		CLOCK_EDGE		: std_logic;
		RESET_LEVEL		: std_logic
	);
	port(
		clk				: in  std_logic;
		reset			: in  std_logic;

		bit_in			: in  std_logic_vector(31 downto 0);
		bit_valid		: out std_logic;
		bit_num			: out std_logic_vector(4 downto 0)
	);
	end component;
	signal irq32bit_reg		: std_logic_vector(31 downto 0);
	signal irq32valid_sig	: std_logic;
	signal irq32num_sig		: std_logic_vector(4 downto 0);


begin

	-- 割り込みフラグレジスタのセット＆リセット 

	process (clk,reset) begin
		if (reset=RESET_LEVEL) then
			irqbit_reg    <= (others=>'0');
			irqsetena_reg <= '0';
			irqclrena_reg <= '0';

		elsif (clk'event and clk=CLOCK_EDGE) then
			irqsetaddr_reg <= irqslot_setaddr;
			irqsetena_reg  <= irqslot_set;

			if (irqsetena_reg='1') then
				irqbit_reg(CONV_INTEGER(irqsetaddr_reg)) <= '1';
			end if;

			irqclraddr_reg <= irqslot_clraddr;
			irqclrena_reg  <= irqslot_clr;

			if (irqclrena_reg='1') then
				irqbit_reg(CONV_INTEGER(irqclraddr_reg)) <= '0';
			end if;

		end if;
	end process;


	-- 32bit単位でプライオリティを判定 

	irqbit_sig(128 downto (2**SLOTNUM_WIDTH)) <= (others=>'0');
	irqbit_sig((2**SLOTNUM_WIDTH)-1 downto 1) <= irqbit_reg((2**SLOTNUM_WIDTH)-1 downto 1);
	irqbit_sig(0) <= '0';

	irqslot_req <= irqslotreq_reg;
	irqslot_num <= irqslotnum_reg;

	process (clk,reset) begin
		if (reset=RESET_LEVEL) then
			state <= HALT;
			irqslotreq_reg <= '0';
			irqslotnum_reg <= (others=>'0');

		elsif (clk'event and clk=CLOCK_EDGE) then

			if (irqsetena_reg='1' or irqclrena_reg='1') then
				state <= ENTRY;

			else
				case state is
				when ENTRY =>
					state <= ENC0;
					irq32bit_reg <= irqbit_sig(31 downto 0);

				when ENC0 =>
					state <= ENC1;
					irq32bit_reg <= irqbit_sig(63 downto 32);

				when ENC1 =>
					state <= DET0;
					irq32bit_reg <= irqbit_sig(95 downto 64);

				when DET0 =>
					if (irq32valid_sig='1') then
						state <= HALT;
						irqslotreq_reg <= '1';
						irqslotnum_reg <= "00" & irq32num_sig;
					else
						state <= DET1;
					end if;

					irq32bit_reg <= irqbit_sig(127 downto 96);

				when DET1 =>
					if (irq32valid_sig='1') then
						state <= HALT;
						irqslotreq_reg <= '1';
						irqslotnum_reg <= "01" & irq32num_sig;
					else
						state <= DET2;
					end if;

				when DET2 =>
					if (irq32valid_sig='1') then
						state <= HALT;
						irqslotreq_reg <= '1';
						irqslotnum_reg <= "10" & irq32num_sig;
					else
						state <= DET3;
					end if;

				when DET3 =>
					state <= HALT;
					if (irq32valid_sig='1') then
						irqslotreq_reg <= '1';
						irqslotnum_reg <= "11" & irq32num_sig;
					else
						irqslotreq_reg <= '0';
						irqslotnum_reg <= (others=>'0');
					end if;

				when HALT =>
					state <= HALT;
				when others=>
					state <= HALT;
				end case;
			end if;

		end if;
	end process;


	U : loreley_irqencode_32bitenc
	generic map (
		CLOCK_EDGE		=> CLOCK_EDGE,
		RESET_LEVEL		=> RESET_LEVEL
	)
	port map (
		clk			=> clk,
		reset		=> reset,

		bit_in		=> irq32bit_reg,
		bit_valid	=> irq32valid_sig,
		bit_num		=> irq32num_sig
	);



end RTL;



----------------------------------------------------------------------
--  32bit Priority encoder
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity loreley_irqencode_32bitenc is
	generic(
		CLOCK_EDGE		: std_logic := '1';	-- Rise edge drive clock
		RESET_LEVEL		: std_logic := '1'	-- Positive logic reset
	);
	port(
		clk				: in  std_logic;	-- system clock
		reset			: in  std_logic :='0';	-- async reset

		bit_in			: in  std_logic_vector(31 downto 0);

		bit_valid		: out std_logic;
		bit_num			: out std_logic_vector(4 downto 0)
	);
end loreley_irqencode_32bitenc;

architecture RTL of loreley_irqencode_32bitenc is
	signal valid_reg	: std_logic;
	signal num_reg		: std_logic_vector(4 downto 0);


	component loreley_irqencode_8bitenc
	generic(
		CLOCK_EDGE		: std_logic;
		RESET_LEVEL		: std_logic
	);
	port(
		clk				: in  std_logic;
		reset			: in  std_logic;

		bit_in			: in  std_logic_vector(7 downto 0);
		bit_valid		: out std_logic;
		bit_num			: out std_logic_vector(2 downto 0)
	);
	end component;
	signal bitvalid_sig	: std_logic_vector(3 downto 0);
	signal bit32num_sig	: std_logic_vector(11 downto 0);


begin

	-- プライオリティ出力(優先度：低 bit31 ←→ bit0 高) 

	bit_valid <= valid_reg;
	bit_num   <= num_reg;


	-- ２段目：4bitプライオリティエンコーダ 

	process (clk,reset) begin
		if (reset=RESET_LEVEL) then
			valid_reg <= '0';
			num_reg   <= (others=>'X');

		elsif (clk'event and clk=CLOCK_EDGE) then

			if (bitvalid_sig(0)='1') then
				num_reg(4 downto 3) <= "00";
				num_reg(2 downto 0) <= bit32num_sig(2 downto 0);

			elsif (bitvalid_sig(1)='1') then
				num_reg(4 downto 3) <= "01";
				num_reg(2 downto 0) <= bit32num_sig(5 downto 3);

			elsif (bitvalid_sig(2)='1') then
				num_reg(4 downto 3) <= "10";
				num_reg(2 downto 0) <= bit32num_sig(8 downto 6);

			elsif (bitvalid_sig(3)='1') then
				num_reg(4 downto 3) <= "11";
				num_reg(2 downto 0) <= bit32num_sig(11 downto 9);

			else
				num_reg <= (others=>'X');

			end if;

			if (bitvalid_sig/="0000") then
				valid_reg <= '1';
			else
				valid_reg <= '0';
			end if;

		end if;
	end process;


	-- １段目：8bitプライオリティエンコーダ×４個 

	U0 : loreley_irqencode_8bitenc
	generic map (
		CLOCK_EDGE		=> CLOCK_EDGE,
		RESET_LEVEL		=> RESET_LEVEL
	)
	port map (
		clk			=> clk,
		reset		=> reset,
		bit_in		=> bit_in(7 downto 0),
		bit_valid	=> bitvalid_sig(0),
		bit_num		=> bit32num_sig(2 downto 0)
	);
	U1 : loreley_irqencode_8bitenc
	generic map (
		CLOCK_EDGE		=> CLOCK_EDGE,
		RESET_LEVEL		=> RESET_LEVEL
	)
	port map (
		clk			=> clk,
		reset		=> reset,
		bit_in		=> bit_in(15 downto 8),
		bit_valid	=> bitvalid_sig(1),
		bit_num		=> bit32num_sig(5 downto 3)
	);
	U2 : loreley_irqencode_8bitenc
	generic map (
		CLOCK_EDGE		=> CLOCK_EDGE,
		RESET_LEVEL		=> RESET_LEVEL
	)
	port map (
		clk			=> clk,
		reset		=> reset,
		bit_in		=> bit_in(23 downto 16),
		bit_valid	=> bitvalid_sig(2),
		bit_num		=> bit32num_sig(8 downto 6)
	);
	U3 : loreley_irqencode_8bitenc
	generic map (
		CLOCK_EDGE		=> CLOCK_EDGE,
		RESET_LEVEL		=> RESET_LEVEL
	)
	port map (
		clk			=> clk,
		reset		=> reset,
		bit_in		=> bit_in(31 downto 24),
		bit_valid	=> bitvalid_sig(3),
		bit_num		=> bit32num_sig(11 downto 9)
	);



end RTL;



----------------------------------------------------------------------
--  8bit Priority encoder
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity loreley_irqencode_8bitenc is
	generic(
		CLOCK_EDGE		: std_logic := '1';	-- Rise edge drive clock
		RESET_LEVEL		: std_logic := '1'	-- Positive logic reset
	);
	port(
		clk				: in  std_logic;	-- system clock
		reset			: in  std_logic :='0';	-- async reset

		bit_in			: in  std_logic_vector(7 downto 0);
		bit_valid		: out std_logic;
		bit_num			: out std_logic_vector(2 downto 0)
	);
end loreley_irqencode_8bitenc;

architecture RTL of loreley_irqencode_8bitenc is
	signal bitnum_reg	: std_logic_vector(2 downto 0);
	signal bitvalid_reg	: std_logic;


begin

	-- プライオリティ出力(優先度：低 bit7 ←→ bit0 高) 

	bit_num   <= bitnum_reg;
	bit_valid <= bitvalid_reg;

	process (clk,reset) begin
		if (reset=RESET_LEVEL) then
			bitvalid_reg <= '0';
			bitnum_reg   <= "XXX";

		elsif (clk'event and clk=CLOCK_EDGE) then
			if (bit_in(0)='1') then
				bitnum_reg <= "000";
			elsif (bit_in(1)='1') then
				bitnum_reg <= "001";
			elsif (bit_in(2)='1') then
				bitnum_reg <= "010";
			elsif (bit_in(3)='1') then
				bitnum_reg <= "011";
			elsif (bit_in(4)='1') then
				bitnum_reg <= "100";
			elsif (bit_in(5)='1') then
				bitnum_reg <= "101";
			elsif (bit_in(6)='1') then
				bitnum_reg <= "110";
			elsif (bit_in(7)='1') then
				bitnum_reg <= "111";
			else
				bitnum_reg <= "XXX";
			end if;

			if (bit_in/="00000000") then
				bitvalid_reg <= '1';
			else
				bitvalid_reg <= '0';
			end if;

		end if;
	end process;



end RTL;



----------------------------------------------------------------------
--   (C)2005,2006 Copyright J-7SYSTEM Works.  All rights Reserved.  --
----------------------------------------------------------------------
