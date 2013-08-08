----------------------------------------------------------------------
-- TITLE : Loreley Dual-Port Memory
--
--     VERFASSER : S.OSAFUNE (J-7SYSTEM Works)
--     DATUM     : 2005/03/31 -> 2005/04/02 (HERSTELLUNG)
--               : 2005/04/02 (FESTSTELLUNG)
--
--               : 2005/12/23 true_dpram‚ðsimple_dpram~2‚Å\¬
--               : 2006/10/15 •W€VHDL‹Lq‚ðC³ (NEUBEARBEITUNG)
----------------------------------------------------------------------

----------------------------------------------------------------------
--  Simple Dualport Ram
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity loreley_simpledpram is
	generic(
		CLOCK_EDGE		: std_logic := '1';	-- Rise edge drive clock
		RESET_LEVEL		: std_logic := '1';	-- Positive logic reset

		ADDRESS_WIDTH	: integer := 7;		-- Address bit width
		DATA_WIDTH		: integer := 32;		-- Data bit width
		DEVICE_MAKER	: string := "ALTERA"
	);
	port(
		clk				: in  std_logic;	-- system clock
		reset			: in  std_logic :='0';	-- async reset

		rdaddress		: in  std_logic_vector(ADDRESS_WIDTH-1 downto 0);
		rddata			: out std_logic_vector(DATA_WIDTH-1 downto 0);
		wraddress		: in  std_logic_vector(ADDRESS_WIDTH-1 downto 0);
		wrdata			: in  std_logic_vector(DATA_WIDTH-1 downto 0);
		wrenable		: in  std_logic := '1'
	);
end loreley_simpledpram;

architecture RTL of loreley_simpledpram is
	type RAM_WORD is array (0 to (2**ADDRESS_WIDTH)-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
	signal spram : RAM_WORD;
	signal rdclk_sig	: std_logic;
	signal wrclk_sig	: std_logic;
	signal rdaddr_reg	: std_logic_vector(ADDRESS_WIDTH-1 downto 0);
	signal wraddr_reg	: std_logic_vector(ADDRESS_WIDTH-1 downto 0);
	signal wrdata_reg	: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal wrena_reg	: std_logic;

	COMPONENT altsyncram
	GENERIC (
		intended_device_family		: STRING;
		operation_mode		: STRING;
		width_a		: NATURAL;
		widthad_a		: NATURAL;
		numwords_a		: NATURAL;
		width_b		: NATURAL;
		widthad_b		: NATURAL;
		numwords_b		: NATURAL;
		lpm_type		: STRING;
		width_byteena_a		: NATURAL;
		outdata_reg_b		: STRING;
		indata_aclr_a		: STRING;
		wrcontrol_aclr_a		: STRING;
		address_aclr_a		: STRING;
		address_reg_b		: STRING;
		address_aclr_b		: STRING;
		outdata_aclr_b		: STRING;
		read_during_write_mode_mixed_ports		: STRING
	);
	PORT (
			wren_a	: IN STD_LOGIC ;
			aclr0	: IN STD_LOGIC ;
			clock0	: IN STD_LOGIC ;
			address_a	: IN STD_LOGIC_VECTOR (ADDRESS_WIDTH-1 DOWNTO 0);
			address_b	: IN STD_LOGIC_VECTOR (ADDRESS_WIDTH-1 DOWNTO 0);
			q_b	: OUT STD_LOGIC_VECTOR (DATA_WIDTH-1 DOWNTO 0);
			data_a	: IN STD_LOGIC_VECTOR (DATA_WIDTH-1 DOWNTO 0)
	);
	END COMPONENT;


begin

GEN_ALTERA : if (DEVICE_MAKER = "ALTERA") generate

	altsyncram_component : altsyncram
	GENERIC MAP (
		intended_device_family => "Cyclone",
		operation_mode => "DUAL_PORT",
		width_a => DATA_WIDTH,
		widthad_a => ADDRESS_WIDTH,
		numwords_a => (2**ADDRESS_WIDTH),
		width_b => DATA_WIDTH,
		widthad_b => ADDRESS_WIDTH,
		numwords_b => (2**ADDRESS_WIDTH),
		lpm_type => "altsyncram",
		width_byteena_a => 1,
		outdata_reg_b => "UNREGISTERED",
		indata_aclr_a => "NONE",
		wrcontrol_aclr_a => "CLEAR0",
		address_aclr_a => "NONE",
		address_reg_b => "CLOCK0",
		address_aclr_b => "NONE",
		outdata_aclr_b => "NONE",
		read_during_write_mode_mixed_ports => "DONT_CARE"
	)
	PORT MAP (
		wren_a => wrenable,
		aclr0 => reset,
		clock0 => clk,
		address_a => wraddress,
		address_b => rdaddress,
		data_a => wrdata,
		q_b => rddata
	);

end generate;
GEN_VHDL : if (DEVICE_MAKER = "") generate

	rdclk_sig <= clk;
	rddata <= spram(CONV_INTEGER(rdaddr_reg));

	process (rdclk_sig) begin
		if (rdclk_sig'event and rdclk_sig=CLOCK_EDGE) then
			rdaddr_reg <= rdaddress;
		end if;
	end process;

	wrclk_sig <= clk;

	process (wrclk_sig,reset) begin
		if (reset=RESET_LEVEL) then
			wrena_reg <= '0';

		elsif (wrclk_sig'event and wrclk_sig=CLOCK_EDGE) then
			wraddr_reg <= wraddress;
			wrdata_reg <= wrdata;
			wrena_reg  <= wrenable;

			if (wrena_reg='1') then
				spram(CONV_INTEGER(wraddr_reg)) <= wrdata_reg;
			end if;

		end if;
	end process;

end generate;


end RTL;



----------------------------------------------------------------------
--  Ture Dualport Ram
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity loreley_turedpram is
	generic(
		CLOCK_EDGE		: std_logic := '1';	-- Rise edge drive clock
		RESET_LEVEL		: std_logic := '1';	-- Positive logic reset
		ADDRESS_WIDTH	: integer := 9;		-- Address bit width
		DATA_WIDTH		: integer := 32;	-- Data bit width

		DEVICE_MAKER	: string := "ALTERA"
	);
	port(
		clk				: in  std_logic;	-- system clock
		reset			: in  std_logic := '0';	-- async reset

		address_a		: in  std_logic_vector(ADDRESS_WIDTH-1 downto 0);
		readdata_a		: out std_logic_vector(DATA_WIDTH-1 downto 0);
		writedata_a		: in  std_logic_vector(DATA_WIDTH-1 downto 0);
		writeena_a		: in  std_logic := '1';

		address_b		: in  std_logic_vector(ADDRESS_WIDTH-1 downto 0);
		readdata_b		: out std_logic_vector(DATA_WIDTH-1 downto 0);
		writedata_b		: in  std_logic_vector(DATA_WIDTH-1 downto 0);
		writeena_b		: in  std_logic := '1'
	);
end loreley_turedpram;

architecture RTL of loreley_turedpram is

	component loreley_simpledpram
	generic(
		CLOCK_EDGE		: std_logic;
		RESET_LEVEL		: std_logic;

		ADDRESS_WIDTH	: integer;
		DATA_WIDTH		: integer;
		DEVICE_MAKER	: string
	);
	port(
		clk				: in  std_logic;
		reset			: in  std_logic;

		rdaddress		: in  std_logic_vector(ADDRESS_WIDTH-1 downto 0);
		rddata			: out std_logic_vector(DATA_WIDTH-1 downto 0);
		wraddress		: in  std_logic_vector(ADDRESS_WIDTH-1 downto 0);
		wrdata			: in  std_logic_vector(DATA_WIDTH-1 downto 0);
		wrenable		: in  std_logic := '1'
	);
	end component;
	signal wraddr_sig	: std_logic_vector(ADDRESS_WIDTH-1 downto 0);
	signal wrdata_sig	: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal wrena_sig	: std_logic;


	COMPONENT altsyncram
	GENERIC (
		intended_device_family		: STRING;
		operation_mode		: STRING;
		width_a		: NATURAL;
		widthad_a		: NATURAL;
		numwords_a		: NATURAL;
		width_b		: NATURAL;
		widthad_b		: NATURAL;
		numwords_b		: NATURAL;
		lpm_type		: STRING;
		width_byteena_a		: NATURAL;
		width_byteena_b		: NATURAL;
		outdata_reg_a		: STRING;
		outdata_aclr_a		: STRING;
		outdata_reg_b		: STRING;
		indata_aclr_a		: STRING;
		wrcontrol_aclr_a		: STRING;
		address_aclr_a		: STRING;
		indata_reg_b		: STRING;
		address_reg_b		: STRING;
		wrcontrol_wraddress_reg_b		: STRING;
		indata_aclr_b		: STRING;
		wrcontrol_aclr_b		: STRING;
		address_aclr_b		: STRING;
		outdata_aclr_b		: STRING;
		read_during_write_mode_mixed_ports		: STRING
	);
	PORT (
			wren_a	: IN STD_LOGIC ;
			aclr0	: IN STD_LOGIC ;
			clock0	: IN STD_LOGIC ;
			wren_b	: IN STD_LOGIC ;
			address_a	: IN STD_LOGIC_VECTOR (ADDRESS_WIDTH-1 DOWNTO 0);
			address_b	: IN STD_LOGIC_VECTOR (ADDRESS_WIDTH-1 DOWNTO 0);
			q_a	: OUT STD_LOGIC_VECTOR (DATA_WIDTH-1 DOWNTO 0);
			q_b	: OUT STD_LOGIC_VECTOR (DATA_WIDTH-1 DOWNTO 0);
			data_a	: IN STD_LOGIC_VECTOR (DATA_WIDTH-1 DOWNTO 0);
			data_b	: IN STD_LOGIC_VECTOR (DATA_WIDTH-1 DOWNTO 0)
	);
	END COMPONENT;

begin

GEN_ALTERA : if (DEVICE_MAKER = "ALTERA") generate

	altsyncram_component : altsyncram
	GENERIC MAP (
		intended_device_family => "Cyclone",
		operation_mode => "BIDIR_DUAL_PORT",
		width_a => DATA_WIDTH,
		widthad_a => ADDRESS_WIDTH,
		numwords_a => (2**ADDRESS_WIDTH),
		width_b => DATA_WIDTH,
		widthad_b => ADDRESS_WIDTH,
		numwords_b => (2**ADDRESS_WIDTH),
		lpm_type => "altsyncram",
		width_byteena_a => 1,
		width_byteena_b => 1,
		outdata_reg_a => "UNREGISTERED",
		outdata_aclr_a => "NONE",
		outdata_reg_b => "UNREGISTERED",
		indata_aclr_a => "NONE",
		wrcontrol_aclr_a => "CLEAR0",
		address_aclr_a => "NONE",
		indata_reg_b => "CLOCK0",
		address_reg_b => "CLOCK0",
		wrcontrol_wraddress_reg_b => "CLOCK0",
		indata_aclr_b => "NONE",
		wrcontrol_aclr_b => "CLEAR0",
		address_aclr_b => "NONE",
		outdata_aclr_b => "NONE",
		read_during_write_mode_mixed_ports => "DONT_CARE"
	)
	PORT MAP (
		wren_a => writeena_a,
		aclr0 => reset,
		clock0 => clk,
		wren_b => writeena_b,
		address_a => address_a,
		address_b => address_b,
		data_a => writedata_a,
		data_b => writedata_b,
		q_a => readdata_a,
		q_b => readdata_b
	);

end generate;
GEN_VHDL : if (DEVICE_MAKER = "") generate

	wrena_sig  <= '1' when(writeena_a='1' or writeena_b='1') else '0';

	wraddr_sig <= address_a when writeena_a='1' else
				  address_b when writeena_b='1' else
				  (others=>'X');

	wrdata_sig <= writedata_a when writeena_a='1' else
				  writedata_b when writeena_b='1' else
				  (others=>'X');

	ram_a_component : loreley_simpledpram
	generic map (
		CLOCK_EDGE		=> CLOCK_EDGE,
		RESET_LEVEL		=> RESET_LEVEL,
		ADDRESS_WIDTH	=> ADDRESS_WIDTH,
		DATA_WIDTH		=> DATA_WIDTH,
		DEVICE_MAKER	=> DEVICE_MAKER
	)
	port map (
		clk				=> clk,
		reset			=> reset,
		rdaddress		=> address_a,
		rddata			=> readdata_a,
		wraddress		=> wraddr_sig,
		wrdata			=> wrdata_sig,
		wrenable		=> wrena_sig
	);

	ram_b_component : loreley_simpledpram
	generic map (
		CLOCK_EDGE		=> CLOCK_EDGE,
		RESET_LEVEL		=> RESET_LEVEL,
		ADDRESS_WIDTH	=> ADDRESS_WIDTH,
		DATA_WIDTH		=> DATA_WIDTH,
		DEVICE_MAKER	=> DEVICE_MAKER
	)
	port map (
		clk				=> clk,
		reset			=> reset,
		rdaddress		=> address_b,
		rddata			=> readdata_b,
		wraddress		=> wraddr_sig,
		wrdata			=> wrdata_sig,
		wrenable		=> wrena_sig
	);


end generate;


end RTL;



----------------------------------------------------------------------
--   (C)2005,2006 Copyright J-7SYSTEM Works.  All rights Reserved.  --
----------------------------------------------------------------------
