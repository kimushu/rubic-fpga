----------------------------------------------------------------------
-- TITLE : Loreley Wave data adder
--
--     VERFASSER : S.OSAFUNE (J-7SYSTEM Works)
--     DATUM     : 2005/03/28 -> 2005/03/29 (HERSTELLUNG)
--               : 2005/03/31 (FESTSTELLUNG)
--
--               : 2006/11/30 出力部の生成オプションを追加
--               : 2006/12/01 乗算器を変更 (NEUBEARBEITUNG)
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_signed.all;
use IEEE.std_logic_arith.all;

entity loreley_waveadder is
	generic(
		CLOCK_EDGE		: std_logic := '1';	-- Rise edge drive clock
		RESET_LEVEL		: std_logic := '1';	-- Positive logic reset
		DEVICE_MAKER	: string := "ALTERA";
--		DEVICE_MAKER	: string := "";

		PCM_FL_OUT		: string := "ON";
		PCM_FR_OUT		: string := "ON";
		PCM_RL_OUT		: string := "ON";
		PCM_RR_OUT		: string := "ON";
		PCM_AUX0_OUT	: string := "ON";
		PCM_AUX1_OUT	: string := "ON"
	);
	port(
		clk				: in  std_logic;	-- system clock
		reset			: in  std_logic;	-- async reset

		fs_sync			: in  std_logic;	-- Fs sync signal (1clock width)
		start			: in  std_logic;	-- Start Slot-data add (1clock width)
		state_busy		: out std_logic;	-- State machine busy signal

		pcmdata			: in  std_logic_vector(15 downto 0);
											-- PCM data in (Signed 16bit integer)
		volume_fl		: in  std_logic_vector(7 downto 0);
		volume_fr		: in  std_logic_vector(7 downto 0);
		volume_rl		: in  std_logic_vector(7 downto 0);
		volume_rr		: in  std_logic_vector(7 downto 0);
		volume_aux0		: in  std_logic_vector(7 downto 0) := (others=>'0');
		volume_aux1		: in  std_logic_vector(7 downto 0) := (others=>'0');
											-- Ch Volume data in (Unsigned 8bit integer)

		pcmout_fl		: out std_logic_vector(15 downto 0);
		pcmout_fr		: out std_logic_vector(15 downto 0);
		pcmout_rl		: out std_logic_vector(15 downto 0);
		pcmout_rr		: out std_logic_vector(15 downto 0);
		pcmout_aux0		: out std_logic_vector(15 downto 0);
		pcmout_aux1		: out std_logic_vector(15 downto 0)
											-- Ch PCM data out (Signed 16bit integer)
	);
end loreley_waveadder;

architecture RTL of loreley_waveadder is
	type WADDER_STATE is (IDLE,VOL_FL,VOL_FR,VOL_RL,VOL_RR,VOL_AUX0,VOL_AUX1,DATAOUT);
	signal state : WADDER_STATE;
	signal statebusy_reg	: std_logic;

	signal multmp_reg		: std_logic_vector(16 downto 0);
	signal sadd24p16_q_sig	: std_logic_vector(23 downto 0);
	signal sadd24p16_a_sig	: std_logic_vector(23 downto 0);
	signal sadd24p16_b_sig	: std_logic_vector(23 downto 0);

	signal pcmdata_reg		: std_logic_vector(15 downto 0);
	signal voltmp_reg		: std_logic_vector(8 downto 0);
	signal volfr_reg		: std_logic_vector(7 downto 0);
	signal volrl_reg		: std_logic_vector(7 downto 0);
	signal volrr_reg		: std_logic_vector(7 downto 0);
	signal volaux0_reg		: std_logic_vector(7 downto 0);
	signal volaux1_reg		: std_logic_vector(7 downto 0);

	signal addtmp_reg		: std_logic_vector(23 downto 0);
	signal addfl_reg		: std_logic_vector(23 downto 0);
	signal addfr_reg		: std_logic_vector(23 downto 0);
	signal addrl_reg		: std_logic_vector(23 downto 0);
	signal addrr_reg		: std_logic_vector(23 downto 0);
	signal addaux0_reg		: std_logic_vector(23 downto 0);
	signal addaux1_reg		: std_logic_vector(23 downto 0);


	component multiple_16x9
	port(
		dataa		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		datab		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (24 DOWNTO 0)
	);
	end component;
	signal smul16x9_q_sig	: std_logic_vector(24 downto 0);

	component loreley_waveadder_sats16reg
	generic(
		CLOCK_EDGE		: std_logic;
		RESET_LEVEL		: std_logic
	);
	port(
		clk				: in  std_logic;
		reset			: in  std_logic;
		latch			: in  std_logic;

		s24data_in		: in  std_logic_vector(23 downto 0);
		s16data_out		: out std_logic_vector(15 downto 0)
	);
	end component;

begin

--==== 波形合成ステートマシン ========================================

	state_busy <= statebusy_reg;

	process (clk,reset) begin
		if (reset=RESET_LEVEL) then
			state <= IDLE;
			statebusy_reg<= '0';
			pcmdata_reg  <= (others=>'0');
			volfr_reg    <= (others=>'0');
			volrl_reg    <= (others=>'0');
			volrr_reg    <= (others=>'0');
			volaux0_reg  <= (others=>'0');
			volaux1_reg  <= (others=>'0');
			addfl_reg    <= (others=>'0');
			addfr_reg    <= (others=>'0');
			addrl_reg    <= (others=>'0');
			addrr_reg    <= (others=>'0');
			addaux0_reg  <= (others=>'0');
			addaux1_reg  <= (others=>'0');

		elsif (clk'event and clk=CLOCK_EDGE) then
			if (state=IDLE) then
				statebusy_reg <= '0';
			else
				statebusy_reg <= '1';
			end if;


			if (fs_sync='1') then
				state <= IDLE;
				addfl_reg   <= (others=>'0');
				addfr_reg   <= (others=>'0');
				addrl_reg   <= (others=>'0');
				addrr_reg   <= (others=>'0');
				addaux0_reg <= (others=>'0');
				addaux1_reg <= (others=>'0');

			else
				case state is
				when IDLE =>
					if (start='1') then
						state <= VOL_FL;
						voltmp_reg  <= '0' & volume_fl;
						pcmdata_reg <= pcmdata;
						volfr_reg   <= volume_fr;
						volrl_reg   <= volume_rl;
						volrr_reg   <= volume_rr;
						volaux0_reg <= volume_aux0;
						volaux1_reg <= volume_aux1;
					end if;

				when VOL_FL =>
					state <= VOL_FR;
					voltmp_reg <= '0' & volfr_reg;
					addtmp_reg <= addfl_reg;

				when VOL_FR =>
					state <= VOL_RL;
					voltmp_reg <= '0' & volrl_reg;
					addtmp_reg <= addfr_reg;
					addfl_reg  <= sadd24p16_q_sig;

				when VOL_RL =>
					state <= VOL_RR;
					voltmp_reg <= '0' & volrr_reg;
					addtmp_reg <= addrl_reg;
					addfr_reg  <= sadd24p16_q_sig;

				when VOL_RR =>
					state <= VOL_AUX0;
					voltmp_reg <= '0' & volaux0_reg;
					addtmp_reg <= addrr_reg;
					addrl_reg  <= sadd24p16_q_sig;

				when VOL_AUX0 =>
					state <= VOL_AUX1;
					voltmp_reg <= '0' & volaux1_reg;
					addtmp_reg <= addaux0_reg;
					addrr_reg  <= sadd24p16_q_sig;

				when VOL_AUX1 =>
					state <= DATAOUT;
					addtmp_reg <= addaux1_reg;
					addaux0_reg<= sadd24p16_q_sig;

				when DATAOUT =>
					state <= IDLE;
					addaux1_reg<= sadd24p16_q_sig;

				when others =>
					state <= IDLE;
				end case;
			end if;

		end if;
	end process;



--==== 算術演算ブロック ==============================================

	-- 符号付き16ビット×符号付き9ビット乗算器 

GEN_USE_MF : if (DEVICE_MAKER="ALTERA") generate

	MU : multiple_16x9
	port map(
		dataa		=> pcmdata_reg,
		datab		=> voltmp_reg,
		result		=> smul16x9_q_sig
	);

	end generate;
GEN_UNUSE_MF : if (DEVICE_MAKER/="ALTERA") generate

	MU : smul16x9_q_sig <= pcmdata_reg * voltmp_reg;

	end generate;

	process (clk) begin
		if (clk'event and clk=CLOCK_EDGE) then
			multmp_reg <= smul16x9_q_sig(24 downto 8);
		end if;
	end process;

	-- 符号付き24ビット＋符号付き16ビット加算器 
	sadd24p16_a_sig <= addtmp_reg;
	sadd24p16_b_sig(23 downto 16)<= (others=>multmp_reg(16));
	sadd24p16_b_sig(15 downto 0) <= multmp_reg(15 downto 0);
	sadd24p16_q_sig <= sadd24p16_a_sig + sadd24p16_b_sig;



--==== 合成チャネルデータの出力 ======================================

	-- 出力レジスタのインスタンス 
GEN_FL : if (PCM_FL_OUT="ON") generate

	U_fl : loreley_waveadder_sats16reg
	generic map(
		CLOCK_EDGE	=> CLOCK_EDGE,
		RESET_LEVEL	=> RESET_LEVEL
	)
	port map(
		clk			=> clk,
		reset		=> reset,
		latch		=> fs_sync,
		s24data_in	=> addfl_reg,
		s16data_out => pcmout_fl
	);

	end generate;
GEN_FL_UNUSE : if (PCM_FL_OUT/="ON") generate

	pcmout_fl <= (others=>'X');

	end generate;


GEN_FR : if (PCM_FR_OUT="ON") generate

	U_fr : loreley_waveadder_sats16reg
	generic map(
		CLOCK_EDGE	=> CLOCK_EDGE,
		RESET_LEVEL	=> RESET_LEVEL
	)
	port map(
		clk			=> clk,
		reset		=> reset,
		latch		=> fs_sync,
		s24data_in	=> addfr_reg,
		s16data_out => pcmout_fr
	);

	end generate;
GEN_FR_UNUSE : if (PCM_FR_OUT/="ON") generate

	pcmout_fr <= (others=>'X');

	end generate;


GEN_RL : if (PCM_RL_OUT="ON") generate

	U_rl : loreley_waveadder_sats16reg
	generic map(
		CLOCK_EDGE	=> CLOCK_EDGE,
		RESET_LEVEL	=> RESET_LEVEL
	)
	port map(
		clk			=> clk,
		reset		=> reset,
		latch		=> fs_sync,
		s24data_in	=> addrl_reg,
		s16data_out => pcmout_rl
	);

	end generate;
GEN_RL_UNUSE : if (PCM_RL_OUT/="ON") generate

	pcmout_rl <= (others=>'X');

	end generate;


GEN_RR : if (PCM_RR_OUT="ON") generate

	U_rr : loreley_waveadder_sats16reg
	generic map(
		CLOCK_EDGE	=> CLOCK_EDGE,
		RESET_LEVEL	=> RESET_LEVEL
	)
	port map(
		clk			=> clk,
		reset		=> reset,
		latch		=> fs_sync,
		s24data_in	=> addrr_reg,
		s16data_out => pcmout_rr
	);

	end generate;
GEN_RR_UNUSE : if (PCM_RR_OUT/="ON") generate

	pcmout_rr <= (others=>'X');

	end generate;


GEN_AUX0 : if (PCM_AUX0_OUT="ON") generate

	U_aux0 : loreley_waveadder_sats16reg
	generic map(
		CLOCK_EDGE	=> CLOCK_EDGE,
		RESET_LEVEL	=> RESET_LEVEL
	)
	port map(
		clk			=> clk,
		reset		=> reset,
		latch		=> fs_sync,
		s24data_in	=> addaux0_reg,
		s16data_out => pcmout_aux0
	);

	end generate;
GEN_AUX0_UNUSE : if (PCM_AUX0_OUT/="ON") generate

	pcmout_aux0 <= (others=>'X');

	end generate;


GEN_AUX1 : if (PCM_AUX1_OUT="ON") generate

	U_aux1 : loreley_waveadder_sats16reg
	generic map(
		CLOCK_EDGE	=> CLOCK_EDGE,
		RESET_LEVEL	=> RESET_LEVEL
	)
	port map(
		clk			=> clk,
		reset		=> reset,
		latch		=> fs_sync,
		s24data_in	=> addaux1_reg,
		s16data_out => pcmout_aux1
	);

	end generate;
GEN_AUX1_UNUSE : if (PCM_AUX1_OUT/="ON") generate

	pcmout_aux1 <= (others=>'X');

	end generate;


end RTL;



----------------------------------------------------------------------
-- 符号付き24bit→符号付き16ビット飽和ロードレジスタ
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_signed.all;
use IEEE.std_logic_arith.all;

entity loreley_waveadder_sats16reg is
	generic(
		CLOCK_EDGE		: std_logic := '1';	-- Rise edge drive clock
		RESET_LEVEL		: std_logic := '1'	-- Positive logic reset
	);
	port(
		clk				: in  std_logic;	-- system clock
		reset			: in  std_logic;	-- async reset

		latch			: in  std_logic;	-- latch signal (1clock width)

		s24data_in		: in  std_logic_vector(23 downto 0);
		s16data_out		: out std_logic_vector(15 downto 0)
	);
end loreley_waveadder_sats16reg;

architecture RTL of loreley_waveadder_sats16reg is
	signal output_reg	: std_logic_vector(15 downto 0);

begin

	s16data_out <= output_reg;

	process (clk,reset) begin
		if (reset=RESET_LEVEL) then
			output_reg <= (others=>'0');

		elsif (clk'event and clk=CLOCK_EDGE) then
			if (latch='1') then
				if (s24data_in(23 downto 15)="000000000" or s24data_in(23 downto 15)="111111111") then
					output_reg <= s24data_in(15 downto 0);
				else
					if (s24data_in(23)='1') then
						output_reg <= (15=>'1',others=>'0');
					else
						output_reg <= (15=>'0',others=>'1');
					end if;
				end if;
			end if;

		end if;
	end process;


end RTL;



----------------------------------------------------------------------
--   (C)2005,2006 Copyright J-7SYSTEM Works.  All rights Reserved.  --
----------------------------------------------------------------------
