----------------------------------------------------------------------
-- TITLE : Loreley LFSR random code generator
--
--     VERFASSER : S.OSAFUNE (J-7SYSTEM Works)
--     DATUM     : 2006/01/04 -> 2006/01/04 (HERSTELLUNG)
--               : 2006/01/04 (FESTSTELLUNG)
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity loreley_lfsr is
	generic(
		RESET_LEVEL		: std_logic := '1';	-- Positive logic reset
		CLOCK_EDGE		: std_logic := '1';	-- Rise edge drive clock

		LFSR1_SIZE		: integer := 17;	-- LFSR1 bit length
		FIBREG1_NUM		: integer := 14;	-- Fibonacci implementation reg1 number
		LFSR2_SIZE		: integer := 18;	-- LFSR2 bit length
		FIBREG2_NUM		: integer := 11;	-- Fibonacci implementation reg2 number

		OUTPUT_BITWIDTH	: integer := 16		-- Output bit-width
	);
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;

		lfsr_out	: out std_logic_vector(OUTPUT_BITWIDTH-1 downto 0)
	);
end loreley_lfsr;

architecture RTL of loreley_lfsr is
	signal lfsr1_reg	: std_logic_vector(LFSR1_SIZE-1 downto 0);
	signal lfsr2_reg	: std_logic_vector(LFSR2_SIZE-1 downto 0);

begin

	process(clk,reset)begin
		if (reset=RESET_LEVEL) then
			lfsr1_reg <= (others=>'1');
			lfsr2_reg <= (others=>'1');

		elsif (clk'event and clk=CLOCK_EDGE) then
			lfsr1_reg((LFSR1_SIZE-1) downto 1) <= lfsr1_reg((LFSR1_SIZE-2) downto 0);
			lfsr1_reg(0) <= lfsr1_reg(LFSR1_SIZE-1) xor lfsr1_reg(FIBREG1_NUM-1);

			lfsr2_reg((LFSR2_SIZE-1) downto 1) <= lfsr2_reg((LFSR2_SIZE-2) downto 0);
			lfsr2_reg(0) <= lfsr2_reg(LFSR2_SIZE-1) xor lfsr2_reg(FIBREG2_NUM-1);

		end if;
	end process;

	lfsr_out <= lfsr1_reg((OUTPUT_BITWIDTH-1) downto 0) xor
				lfsr2_reg((OUTPUT_BITWIDTH-1) downto 0);

end RTL;


-- Appendix : LFSR parameters exsample
--
--  LFSR_SIZE FIBREG  Sequence Length
--       7       6               127
--       9       5               511
--      10       7              1023
--      11       9              2047
--      15      14             32767
--      17      14            131071
--      18      11            262143
--      20      17           1048575
--      21      19           2097151
--      22      21           4194303
--      23      18           8388607
--      25      22          33554431
--      28      25         268435455
--      29      27         536870911
--      31      28        2147483647
--      33      20        8589934591
--      35      33       34359738367
--      36      25       68719476735
--      39      35       5.49756E+11
--      41      38       2.19902E+12
--      47      42       1.40737E+14
--      49      40       5.6295E+14
--      52      49       4.5036E+15
--      55      31       3.60288E+16
--      57      50       1.44115E+17
--      58      39       2.8823E+17
--      60      59       1.15292E+18
--      63      62       9.22337E+18

----------------------------------------------------------------------
--   (C)2005,2006 Copyright J-7SYSTEM Works.  All rights Reserved.  --
----------------------------------------------------------------------
