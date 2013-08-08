----------------------------------------------------------------------
-- TITLE : Loreley-WSG Delta-Sigma DAC output module
--
--     VERFASSER : S.OSAFUNE (J-7SYSTEM Works)
--     DATUM     : 2007/02/18 -> 2007/02/18 (HERSTELLUNG)
--               : 2007/02/21 (FESTSTELLUNG)
--
--               : 2009/01/03 1bit出力改造
--               : 2009/01/14 パラメータ化修正
--               : 2011/08/22 移動平均フィルタ段を修正 (NEUBEARBEITUNG)
----------------------------------------------------------------------

-- ●移動平均フィルタステージ 
--   M=1の移動平均ＬＰＦを構成する。 

-- ●線形補間ステージ 
--   線形補間のため、原信号f(t)に対して、1/(2n-1)^2 * f((2n-1)*t)の 
--   高次ノイズが重畳する。 
--
--    原信号  ３次  ５次  ７次  ９次  11次  13次  ‥‥ 
--      0dB  -19dB -27dB -33dB -38dB -41dB -44dB 

-- ●出力⊿∑変調ステージ 
--   フルスピードで動作する１ビット１次⊿∑変調ブロック。 

-- ●出力ＬＰＦ
--   fo=19kHz(R=820Ω,C=0.01μF)のCR１次LPFを出力ピン近傍に接続。 
--   この場合、Nq=LSB点でのリジェクションは-19dBで、SNRは-55dB。また 
--   ノイズピークの4fs(192kHz)点では-38dB、リサンプリング周波数の8fs 
--   (352kHz)点では-50dBとなる。 
--   Nq=LSBとなる8/6fsからノイズピークの4fsにかけて、SNRが低下するため 
--   LPFにヒステリシス特性を持つ素子を使用すると音質の悪化を招く。 
--   抵抗は金属薄膜、コンデンサはマイラコンデンサを推奨。 
--
--   音質を重視する場合は、さらにOPAMPによる２次アクティブフィルタを 
--   後段に接続して３次構成にするとよい。 

-- ●ポップノイズ
--   ⊿∑変調の構造上、電源投入時のポップノイズは回避不可（できなくは 
--   ないが、ロジックリソースとのトレードオフ）。 
--   ポップノイズが不都合になる場合、ACカップリングコンデンサの後段に 
--   ミュートトランジスタを配置することで改善可能。 


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity wsg_dsdac is
	generic(
		CLOCK_EDGE		: std_logic := '1';	-- Rise edge drive clock
		RESET_LEVEL		: std_logic := '1';	-- Positive logic reset
		MUTE_LEVEL		: std_logic := '1';
		PCMBITWIDTH		: integer := 12;
		MLFP_STAGE		: string := "ON"	-- 移動平均LFPステージのON/OFF
	);
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;
		mute_in		: in  std_logic;
		fs_timing	: in  std_logic;
		fs8_timing	: in  std_logic;
		fs128_timing: in  std_logic;		-- 未使用 

		pcmdata_in	: in  std_logic_vector(PCMBITWIDTH-1 downto 0);
		dac_out		: out std_logic
	);
end wsg_dsdac;

architecture RTL of wsg_dsdac is
	signal pcma_reg		: std_logic_vector(PCMBITWIDTH-1 downto 0);
	signal pcmb_reg		: std_logic_vector(PCMBITWIDTH-1 downto 0);
	signal pcmq_sig		: std_logic_vector(PCMBITWIDTH downto 0);

	signal pcmin_reg	: std_logic_vector(PCMBITWIDTH-1 downto 0);
	signal delta_reg	: std_logic_vector(PCMBITWIDTH downto 0);
	signal osvpcm_reg	: std_logic_vector(PCMBITWIDTH+2 downto 0);

	signal pcm_sig		: std_logic_vector(PCMBITWIDTH-1 downto 0);
	signal add_sig		: std_logic_vector(PCMBITWIDTH downto 0);
	signal dse_reg		: std_logic_vector(PCMBITWIDTH-1 downto 0);
	signal dacout_reg	: std_logic;

begin

-- 移動平均フィルタステージ -----

	process(clk,reset)begin
		if (reset=RESET_LEVEL) then
			pcma_reg <= (others=>'0');
			pcmb_reg <= (others=>'0');

		elsif (clk'event and clk=CLOCK_EDGE) then
			if (mute_in = MUTE_LEVEL) then
				pcma_reg <= (others=>'0');
				pcmb_reg <= (others=>'0');

			elsif (fs_timing='1') then
				pcma_reg <= pcmdata_in;
				pcmb_reg <= pcma_reg;

			end if;

		end if;
	end process;

GEN_MLFPON : if (MLFP_STAGE = "ON") generate

	pcmq_sig <= (pcma_reg(pcma_reg'left) & pcma_reg) + (pcmb_reg(pcmb_reg'left) & pcmb_reg);

	end generate;
GEN_MLFPOFF : if (MLFP_STAGE /= "ON") generate

	pcmq_sig <= pcma_reg & '0';

	end generate;


-- 線形８倍オーバーサンプリングステージ -----

	process(clk,reset)begin
		if (reset=RESET_LEVEL) then
			pcmin_reg  <= (others=>'0');
			delta_reg  <= (others=>'0');
			osvpcm_reg <= (others=>'0');

		elsif (clk'event and clk=CLOCK_EDGE) then
			if (fs_timing='1') then
				pcmin_reg  <= pcmq_sig(pcmq_sig'left downto 1);
				delta_reg  <=(pcmq_sig(pcmq_sig'left)& pcmq_sig(pcmq_sig'left downto 1)) - (pcmin_reg(pcmin_reg'left) & pcmin_reg);
				osvpcm_reg <= pcmin_reg & "000";

			elsif (fs8_timing='1') then
				osvpcm_reg <= osvpcm_reg + (delta_reg(delta_reg'left) & delta_reg(delta_reg'left) & delta_reg);

			end if;

		end if;
	end process;


-- ⊿∑変調ステージ -----

	pcm_sig(pcm_sig'left) <= not osvpcm_reg(osvpcm_reg'left);
	pcm_sig(pcm_sig'left-1 downto 0) <= osvpcm_reg(osvpcm_reg'left-1 downto 3);

	add_sig <= ('0' & pcm_sig) + ('0' & dse_reg);

	process(clk,reset)begin
		if (reset=RESET_LEVEL) then
			dse_reg    <= (others=>'0');
			dacout_reg <= '0';

		elsif (clk'event and clk=CLOCK_EDGE) then
			dse_reg    <= add_sig(add_sig'left-1 downto 0);
			dacout_reg <= add_sig(add_sig'left);

		end if;
	end process;


	-- DAC出力 

	dac_out <= dacout_reg;


end RTL;



----------------------------------------------------------------------
--   (C)2007,2009 Copyright J-7SYSTEM Works.  All rights Reserved.  --
----------------------------------------------------------------------
