--------------------------------------------------------------------------------
-- Project Rubic
-- RiteVM to NiosII instruction converter
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rubic_r2n_converter is
  generic (
    RITE_MEM_WIDTH  : integer range 4 to 25 := 25 -- 32MiB max
  );
  port (
    -- Common signals
    clk             : in  std_logic;
    reset           : in  std_logic;

    -- RiteVM input port (2GiB space)
    r_address       : out std_logic_vector(30 downto 2);
    r_read          : out std_logic;
    r_readdata      : in  std_logic_vector(31 downto 0);
    r_waitrequest   : in  std_logic;

    -- NiosII output port (128MiB space max)
    n_address       : in  std_logic_vector(RITE_MEM_WIDTH+2-1 downto 2);
    n_read          : in  std_logic;
    n_readdata      : out std_logic_vector(31 downto 0);
    n_waitrequest   : out std_logic;

    -- Control port
    c_address       : in  std_logic_vector(6 downto 0);
    c_write         : in  std_logic;
    c_writedata     : in  std_logic_vector(31 downto 0);
    c_read          : in  std_logic;
    c_readdata      : out std_logic_vector(31 downto 0) := (others => '0')
  );
end entity rubic_r2n_converter;

architecture rtl of rubic_r2n_converter is

  --------------------------------------------------------------------------------
  -- RiteVM opcode
  -- {{{
  constant ROP_NOP        : integer := 0;   --         no operation
  constant ROP_MOVE       : integer := 1;   -- A B     R(A) := R(B)
  constant ROP_LOADL      : integer := 2;   -- A Bx    R(A) := Lit(Bx)
  constant ROP_LOADI      : integer := 3;   -- A sBx   R(A) := sBx
  constant ROP_LOADSYM    : integer := 4;   -- A Bx    R(A) := Sym(Bx)
  constant ROP_LOADNIL    : integer := 5;   -- A       R(A) := nil
  constant ROP_LOADSELF   : integer := 6;   -- A       R(A) := self
  constant ROP_LOADT      : integer := 7;   -- A       R(A) := true
  constant ROP_LOADF      : integer := 8;   -- A       R(A) := false
  constant ROP_GETGLOBAL  : integer := 9;   -- A Bx    R(A) := getglobal(Sym(Bx))
  constant ROP_SETGLOBAL  : integer := 10;  -- A Bx    setglobal(Sym(Bx), R(A))
  constant ROP_GETSPECIAL : integer := 11;  -- A Bx    R(A) := Special[Bx]
  constant ROP_SETSPECIAL : integer := 12;  -- A Bx    Special[Bx] := R(A)
  constant ROP_GETIV      : integer := 13;  -- A Bx    R(A) := ivget(Sym(Bx))
  constant ROP_SETIV      : integer := 14;  -- A Bx    ivset(Sym(Bx),R(A))
  constant ROP_GETCV      : integer := 15;  -- A Bx    R(A) := cvget(Sym(Bx))
  constant ROP_SETCV      : integer := 16;  -- A Bx    cvset(Sym(Bx),R(A))
  constant ROP_GETCONST   : integer := 17;  -- A Bx    R(A) := constget(Sym(Bx))
  constant ROP_SETCONST   : integer := 18;  -- A Bx    constset(Sym(Bx),R(A))
  constant ROP_GETMCNST   : integer := 19;  -- A Bx    R(A) := R(A)::Sym(Bx)
  constant ROP_SETMCNST   : integer := 20;  -- A Bx    R(A+1)::Sym(Bx) := R(A)
  constant ROP_GETUPVAR   : integer := 21;  -- A B C   R(A) := uvget(B,C)
  constant ROP_SETUPVAR   : integer := 22;  -- A B C   uvset(B,C,R(A))
  constant ROP_JMP        : integer := 23;  -- sBx     pc+=sBx
  constant ROP_JMPIF      : integer := 24;  -- A sBx   if R(A) pc+=sBx
  constant ROP_JMPNOT     : integer := 25;  -- A sBx   if !R(A) pc+=sBx
  constant ROP_ONERR      : integer := 26;  -- sBx     rescue_push(pc+sBx)
  constant ROP_RESCUE     : integer := 27;  -- A       clear(exc); R(A) := exception (ignore when A=0)
  constant ROP_POPERR     : integer := 28;  -- A       A.times{rescue_pop()}
  constant ROP_RAISE      : integer := 29;  -- A       raise(R(A))
  constant ROP_EPUSH      : integer := 30;  -- Bx      ensure_push(SEQ[Bx])
  constant ROP_EPOP       : integer := 31;  -- A       A.times{ensure_pop().call}
  constant ROP_SEND       : integer := 32;  -- A B C   R(A) := call(R(A),mSym(B),R(A+1),...,R(A+C))
  constant ROP_SENDB      : integer := 33;  -- A B C   R(A) := call(R(A),mSym(B),R(A+1),...,R(A+C),&R(A+C+1))
  constant ROP_FSEND      : integer := 34;  -- A B C   R(A) := fcall(R(A),mSym(B),R(A+1),...,R(A+C-1))
  constant ROP_CALL       : integer := 35;  -- A B C   R(A) := self.call(R(A),.., R(A+C))
  constant ROP_SUPER      : integer := 36;  -- A B C   R(A) := super(R(A+1),... ,R(A+C-1))
  constant ROP_ARGARY     : integer := 37;  -- A Bx    R(A) := argument array (16=6:1:5:4)
  constant ROP_ENTER      : integer := 38;  -- Ax      arg setup according to flags (23=5:5:1:5:5:1:1)
  constant ROP_KARG       : integer := 39;  -- A B C   R(A) := kdict[mSym(B)]; if C kdict.rm(mSym(B))
  constant ROP_KDICT      : integer := 40;  -- A C     R(A) := kdict
  constant ROP_RETURN     : integer := 41;  -- A B     return R(A) (B=normal,in-block return/break)
  constant ROP_TAILCALL   : integer := 42;  -- A B C   return call(R(A),mSym(B),*R(C))
  constant ROP_BLKPUSH    : integer := 43;  -- A Bx    R(A) := block (16=6:1:5:4)
  constant ROP_ADD        : integer := 44;  -- A B C   R(A) := R(A)+R(A+1) (mSyms[B]=:+,C=1)
  constant ROP_ADDI       : integer := 45;  -- A B C   R(A) := R(A)+C (mSyms[B]=:+)
  constant ROP_SUB        : integer := 46;  -- A B C   R(A) := R(A)-R(A+1) (mSyms[B]=:-,C=1)
  constant ROP_SUBI       : integer := 47;  -- A B C   R(A) := R(A)-C (mSyms[B]=:-)
  constant ROP_MUL        : integer := 48;  -- A B C   R(A) := R(A)*R(A+1) (mSyms[B]=:*,C=1)
  constant ROP_DIV        : integer := 49;  -- A B C   R(A) := R(A)/R(A+1) (mSyms[B]=:/,C=1)
  constant ROP_EQ         : integer := 50;  -- A B C   R(A) := R(A)==R(A+1) (mSyms[B]=:==,C=1)
  constant ROP_LT         : integer := 51;  -- A B C   R(A) := R(A)<R(A+1)  (mSyms[B]=:<,C=1)
  constant ROP_LE         : integer := 52;  -- A B C   R(A) := R(A)<=R(A+1) (mSyms[B]=:<=,C=1)
  constant ROP_GT         : integer := 53;  -- A B C   R(A) := R(A)>R(A+1)  (mSyms[B]=:>,C=1)
  constant ROP_GE         : integer := 54;  -- A B C   R(A) := R(A)>=R(A+1) (mSyms[B]=:>=,C=1)
  constant ROP_ARRAY      : integer := 55;  -- A B C   R(A) := ary_new(R(B),R(B+1)..R(B+C))
  constant ROP_ARYCAT     : integer := 56;  -- A B     ary_cat(R(A),R(B))
  constant ROP_ARYPUSH    : integer := 57;  -- A B     ary_push(R(A),R(B))
  constant ROP_AREF       : integer := 58;  -- A B C   R(A) := R(B)[C]
  constant ROP_ASET       : integer := 59;  -- A B C   R(B)[C] := R(A)
  constant ROP_APOST      : integer := 60;  -- A B C   *R(A),R(A+1)..R(A+C) := R(A)
  constant ROP_STRING     : integer := 61;  -- A Bx    R(A) := str_dup(Lit(Bx))
  constant ROP_STRCAT     : integer := 62;  -- A B     str_cat(R(A),R(B))
  constant ROP_HASH       : integer := 63;  -- A B C   R(A) := hash_new(R(B),R(B+1)..R(B+C))
  constant ROP_LAMBDA     : integer := 64;  -- A Bz Cz R(A) := lambda(SEQ[Bz],Cz)
  constant ROP_RANGE      : integer := 65;  -- A B C   R(A) := range_new(R(B),R(B+1),C)
  constant ROP_OCLASS     : integer := 66;  -- A       R(A) := ::Object
  constant ROP_CLASS      : integer := 67;  -- A B     R(A) := newclass(R(A),mSym(B),R(A+1))
  constant ROP_MODULE     : integer := 68;  -- A B     R(A) := newmodule(R(A),mSym(B))
  constant ROP_EXEC       : integer := 69;  -- A Bx    R(A) := blockexec(R(A),SEQ[Bx])
  constant ROP_METHOD     : integer := 70;  -- A B     R(A).newmethod(mSym(B),R(A+1))
  constant ROP_SCLASS     : integer := 71;  -- A B     R(A) := R(B).singleton_class
  constant ROP_TCLASS     : integer := 72;  -- A       R(A) := target_class
  constant ROP_DEBUG      : integer := 73;  -- A       print R(A)
  constant ROP_STOP       : integer := 74;  --         stop VM
  constant ROP_ERR        : integer := 75;  -- Bx      raise RuntimeError with message Lit(Bx)
  constant ROP_RSVD1      : integer := 76;  --         reserved instruction #1
  constant ROP_RSVD2      : integer := 77;  --         reserved instruction #2
  constant ROP_RSVD3      : integer := 78;  --         reserved instruction #3
  constant ROP_RSVD4      : integer := 79;  --         reserved instruction #4
  constant ROP_RSVD5      : integer := 80;  --         reserved instruction #5
  -- }}}

  constant MRB_FIXNUM_SHIFT   : integer := 1;
  constant MRB_FIXNUM_FLAG    : integer := 1;
  constant MRB_SYMBOL_FLAG    : integer := 16#0e#;
  constant MRB_SPECIAL_SHIFT  : integer := 8;
  constant MRB_QFALSE         : integer := 2;
  constant MRB_QTRUE          : integer := 4;

  --------------------------------------------------------------------------------
  -- NiosII opcode
  -- {{{
  constant NOP_ADD        : integer := 16#1883a#; -- Type R
  constant NOP_ADDI       : integer := 16#04#;    -- Type I
  constant NOP_BEQ        : integer := 16#26#;    -- Type I
  constant NOP_BNE        : integer := 16#1e#;    -- Type I
  constant NOP_BR         : integer := 16#06#;    -- Type I
  constant NOP_CALL       : integer := 16#00#;    -- Type J
  constant NOP_JMPI       : integer := 16#01#;    -- Type J
  constant NOP_LDHU       : integer := 16#0b#;    -- Type I
  constant NOP_LDW        : integer := 16#17#;    -- Type I
  constant NOP_NEXTPC     : integer := 16#0e03a#; -- Type R
  constant NOP_ORHI       : integer := 16#34#;    -- Type I
  constant NOP_ORI        : integer := 16#14#;    -- Type I
--constant NOP_RET        : integer := 16#0283a#; -- Type R (rA=31)
  constant NOP_SLLI       : integer := 16#0903a#; -- Type R
  constant NOP_STW        : integer := 16#15#;    -- Type I
  -- }}}

  subtype r_inst_t  is std_logic_vector(31 downto 0);
  subtype n_inst_t  is std_logic_vector(31 downto 0);
  subtype funcptr_t is std_logic_vector(27 downto 2);
  subtype regnum_t  is integer range 0 to 31;
  subtype regitem_t is std_logic_vector(30 downto 0);
  type regarray_t is array (2**7-1 downto 0) of regitem_t;

  function NOP_TYPE_I(op, a, b, imm16: integer) return n_inst_t is
    variable i : n_inst_t;
  begin
    i(31 downto 27) := std_logic_vector(to_unsigned(a, 5));
    i(26 downto 22) := std_logic_vector(to_unsigned(b, 5));
    i(21 downto  6) := std_logic_vector(to_signed(imm16, 16));
    i( 5 downto  0) := std_logic_vector(to_unsigned(op, 6));
    return i;
  end function NOP_TYPE_I;

  function NOP_TYPE_R(op, a, b, c: integer) return n_inst_t is
    variable i : n_inst_t;
  begin
    i(31 downto 27) := std_logic_vector(to_unsigned(a, 5));
    i(26 downto 22) := std_logic_vector(to_unsigned(b, 5));
    i(21 downto 17) := std_logic_vector(to_unsigned(c, 5));
    i(16 downto  0) := std_logic_vector(to_unsigned(op, 17));
    return i;
  end function NOP_TYPE_R;

  function NOP_TYPE_J(op: integer; imm26: std_logic_vector) return n_inst_t is
    variable i : n_inst_t;
  begin
    i(31 downto  6) := imm26;
    i( 5 downto  0) := std_logic_vector(to_unsigned(op, 6));
    return i;
  end function NOP_TYPE_J;

  constant NOP_FILLER : n_inst_t := NOP_TYPE_R(NOP_ADD, 0, 0, 0);

  --------------------------------------------------------------------------------
  -- Control register
  constant CADDR_RBASE  : integer := ROP_NOP;
  constant CADDR_REGSTK : integer := ROP_MOVE;
  constant CADDR_REGLIT : integer := ROP_LOADL;
  constant CADDR_REGSYM : integer := ROP_LOADSYM;
  constant CADDR_LEAVE  : integer := ROP_STOP;

  signal r_faddr_w  : std_logic_vector(RITE_MEM_WIDTH-1 downto 2); -- Address to fetch
  signal r_faddr_r  : std_logic_vector(RITE_MEM_WIDTH-1 downto 2); -- Fetched address
  signal r_read_r   : std_logic;  -- Read signal
  signal r_inst_r   : r_inst_t;   -- Fetched RiteVM instruction
  signal r_valid_r  : std_logic;  -- Valid of r_inst_r

  signal n_inst_r   : n_inst_t;   -- Output Nios II instruction
  signal n_wait_r   : std_logic;  -- Output Nios II wait request
  signal n_insts_w  : std_logic_vector(n_inst_t'length*4-1 downto 0);

  shared variable c_regmem : regarray_t;
  signal c_addra_w  : integer range 0 to 2**7-1;
  signal c_reada_r  : regitem_t;
  signal c_addrb_w  : integer range 0 to 2**7-1;
  signal c_rbase_r  : std_logic_vector(30 downto RITE_MEM_WIDTH); -- RiteVM memory base
  signal c_regstk_r : regnum_t;   -- Register number for stack
  signal c_reglit_r : regnum_t;   -- Register number for literals
  signal c_regsym_r : regnum_t;   -- Register number for symbols
  signal c_deleg_r  : funcptr_t;  -- Delegate function pointer
  signal c_leave_r  : funcptr_t;  -- Rubic leave routine pointer

  --------------------------------------------------------------------------------
  -- Rite -> NiosII instruction convertion map
  impure function INST_RITE_TO_NIOS2(r_inst: r_inst_t) return std_logic_vector is
  -- {{{
    variable r_op   : integer range 0 to 2**7-1;
    variable r_a    : integer range 0 to 2**9-1;
    variable r_b    : integer range 0 to 2**9-1;
    variable r_c    : integer range 0 to 2**7-1;
    variable r_bx   : integer range 0 to 2**16-1;
    variable r_sbxs : std_logic;                          -- sign of (sBx-1)
    variable r_sbx1 : integer range -(2**15) to 2**15-1;  -- (sBx-1)
    variable r_sbxv : integer range 0 to 2**15-1;
    variable r_ax   : integer range 0 to 2**26-1;
    variable r_bz   : integer range 0 to 2**14-1;
    variable r_cz   : integer range 0 to 2**2-1;
    variable n_1    : n_inst_t := NOP_FILLER;
    variable n_2    : n_inst_t := NOP_FILLER;
    variable n_3    : n_inst_t := NOP_FILLER;
    variable n_4    : n_inst_t := NOP_FILLER;
    variable giveup : boolean := false;
  begin
    -- Analyze fields of rite instruction
    r_op    := to_integer(unsigned(r_inst(6 downto 0)));
    r_a     := to_integer(unsigned(r_inst(31 downto 23)));
    r_b     := to_integer(unsigned(r_inst(22 downto 14)));
    r_c     := to_integer(unsigned(r_inst(13 downto 7)));
    r_bx    := to_integer(unsigned(r_inst(22 downto 7)));
    r_sbxs  := not r_inst(22);
    r_sbx1  := to_integer(signed(r_sbxs & r_inst(21 downto 7)));
    r_sbxv  := to_integer(unsigned(r_inst(21 downto 7)));
    r_ax    := to_integer(unsigned(r_inst(31 downto 7)));
    r_bz    := to_integer(unsigned(r_inst(22 downto 9)));
    r_cz    := to_integer(unsigned(r_inst(8 downto 7)));

    -- Convert
    case (r_op) is
    when ROP_NOP =>
      null;

    when ROP_MOVE =>
      -- ldw    r2, B*4(rSTK)
      -- stw    r2, A*4(rSTK)
      n_1 := NOP_TYPE_I(NOP_LDW, c_regstk_r, 2, r_b * 4);
      n_4 := NOP_TYPE_I(NOP_STW, c_regstk_r, 2, r_a * 4);

    when ROP_LOADL =>
      if (r_bx < 2**13) then
        -- ldw    r2, Bx*4(rLIT)
        -- stw    r2, A*4(rSTK)
        n_1 := NOP_TYPE_I(NOP_LDW, c_reglit_r, 2, r_bx * 4);
        n_4 := NOP_TYPE_I(NOP_STW, c_regstk_r, 2, r_a * 4);
      else
        giveup := true;
      end if;

    when ROP_LOADI =>
      -- movi   r2, (sBx-1)
      -- slli   r2, r2, 1
      -- addi   r2, r2, 3
      -- stw    r2, A*4(rSTK)
      n_1 := NOP_TYPE_I(NOP_ADDI, 0, 2, r_sbx1);
      n_2 := NOP_TYPE_R(NOP_SLLI + (1 * 2**6), 2, 0, 2);
      n_3 := NOP_TYPE_I(NOP_ADDI, 2, 2, 3);
      n_4 := NOP_TYPE_I(NOP_STW, c_regstk_r, 2, r_a * 4);

    when ROP_LOADSYM =>
      if (r_bx < 2**14) then
        -- ldhu   r2, Bx*2(rSYM)
        -- slli   r2, r2, MRB_SPECIAL_SHIFT
        -- ori    r2, r2, MRB_SYMBOL_FLAG
        -- stw    r2, A*4(rSTK)
        n_1 := NOP_TYPE_I(NOP_LDHU, c_regsym_r, 2, r_bx * 2);
        n_2 := NOP_TYPE_R(NOP_SLLI + (MRB_SPECIAL_SHIFT * 2**6), 2, 0, 2);
        n_3 := NOP_TYPE_I(NOP_ORI, 2, 2, MRB_SYMBOL_FLAG);
        n_4 := NOP_TYPE_I(NOP_STW, c_regstk_r, 2, r_a * 4);
      else
        giveup := true;
      end if;

    when ROP_LOADNIL =>
      -- stw    r0(==Qnil), A*4(rSTK)
      n_4 := NOP_TYPE_I(NOP_STW, c_regstk_r, 0, r_a * 4);

    when ROP_LOADSELF =>
      -- ldw    r2, 0(rSTK)
      -- stw    r2, A*4(rSTK)
      n_1 := NOP_TYPE_I(NOP_LDW, c_regstk_r, 2, 0);
      n_4 := NOP_TYPE_I(NOP_STW, c_regstk_r, 2, r_a * 4);

    when ROP_LOADT =>
      -- movi   r2, Qtrue
      -- stw    r2, A*4(rSTK)
      n_1 := NOP_TYPE_I(NOP_ADDI, 0, 2, MRB_QTRUE);
      n_4 := NOP_TYPE_I(NOP_STW, c_regstk_r, 2, r_a * 4);

    when ROP_LOADF =>
      -- movi   r2, Qfalse
      -- stw    r2, A*4(rSTK)
      n_1 := NOP_TYPE_I(NOP_ADDI, 0, 2, MRB_QFALSE);
      n_4 := NOP_TYPE_I(NOP_STW, c_regstk_r, 2, r_a * 4);

    when ROP_GETGLOBAL | ROP_GETIV | ROP_GETCV | ROP_GETCONST =>
      if (r_bx < 2**14) then
        -- ldhu   r5, Bx*2(rSYM)
        -- call   fptr
        -- stw    r2, A*4(rSTK)
        n_1 := NOP_TYPE_I(NOP_LDHU, c_regsym_r, 5, r_bx * 2);
        n_3 := NOP_TYPE_J(NOP_CALL, c_deleg_r);
        n_4 := NOP_TYPE_I(NOP_STW, c_regstk_r, 2, r_a * 4);
      else
        giveup := true;
      end if;

    when ROP_SETGLOBAL | ROP_SETIV | ROP_SETCV | ROP_SETCONST =>
      if (r_bx < 2**14) then
        -- ldhu   r5, Bx*2(rSYM)
        -- ldw    r6, A*4(rSTK)
        -- call   fptr
        n_1 := NOP_TYPE_I(NOP_LDHU, c_regsym_r, 5, r_bx * 2);
        n_2 := NOP_TYPE_I(NOP_LDW, c_regstk_r, 6, r_a * 4);
        n_3 := NOP_TYPE_J(NOP_CALL, c_deleg_r);
      else
        giveup := true;
      end if;

    when ROP_GETSPECIAL =>
      -- movui  r5, Bx
      -- call   fptr
      -- stw    r2, A*4(rSTK)
      n_1 := NOP_TYPE_I(NOP_ORI, 0, 5, r_bx);
      n_3 := NOP_TYPE_J(NOP_CALL, c_deleg_r);
      n_4 := NOP_TYPE_I(NOP_STW, c_regstk_r, 2, r_a * 4);

    when ROP_SETSPECIAL =>
      -- movui  r5, Bx
      -- ldw    r6, A*4(rSTK)
      -- call   fptr
      n_1 := NOP_TYPE_I(NOP_ORI, 0, 5, r_bx);
      n_2 := NOP_TYPE_I(NOP_LDW, c_regstk_r, 6, r_a * 4);
      n_3 := NOP_TYPE_J(NOP_CALL, c_deleg_r);

    when ROP_GETMCNST =>
      if (r_bx < 2**14) then
        -- ldw    r5, A*4(rSTK)
        -- ldhu   r6, Bx*2(rSYM)
        -- call   fptr
        -- stw    r2, A*4(rSTK)
        n_1 := NOP_TYPE_I(NOP_LDW, c_regstk_r, 5, r_a * 4);
        n_2 := NOP_TYPE_I(NOP_LDHU, c_regsym_r, 6, r_bx * 2);
        n_3 := NOP_TYPE_J(NOP_CALL, c_deleg_r);
        n_4 := NOP_TYPE_I(NOP_STW, c_regstk_r, 2, r_a * 4);
      else
        giveup := true;
      end if;

    when ROP_SETMCNST =>
      if (r_bx < 2**14) then
        -- ldw    r5, (A+1)*4(rSTK)
        -- ldhu   r6, Bx*2(rSYM)
        -- stw    r7, A*4(rSTK)
        -- call   fptr
        n_1 := NOP_TYPE_I(NOP_LDW, c_regstk_r, 5, (r_a + 1) * 4);
        n_2 := NOP_TYPE_I(NOP_LDHU, c_regsym_r, 6, r_bx * 2);
        n_3 := NOP_TYPE_I(NOP_LDW, c_regstk_r, 7, r_a * 4);
        n_4 := NOP_TYPE_J(NOP_CALL, c_deleg_r);
      else
        giveup := true;
      end if;

    when ROP_GETUPVAR =>
      -- movi   r5, C
      -- movi   r6, B*4
      -- call   fptr
      -- stw    r2, A*4(rSTK)
      n_1 := NOP_TYPE_I(NOP_ADDI, 0, 5, r_c);
      n_2 := NOP_TYPE_I(NOP_ADDI, 0, 6, r_b * 4);
      n_3 := NOP_TYPE_J(NOP_CALL, c_deleg_r);
      n_4 := NOP_TYPE_I(NOP_STW, c_regstk_r, 2, r_a * 4);

    when ROP_SETUPVAR =>
      -- movi   r5, C
      -- movi   r6, B*4
      -- ldw    r7, A*4(rSTK)
      -- call   fptr
      n_1 := NOP_TYPE_I(NOP_ADDI, 0, 5, r_c);
      n_2 := NOP_TYPE_I(NOP_ADDI, 0, 6, r_b * 4);
      n_3 := NOP_TYPE_I(NOP_LDW, c_regstk_r, 7, r_a * 4);
      n_4 := NOP_TYPE_J(NOP_CALL, c_deleg_r);

    when ROP_JMP =>
      -- if ((-2**11-12 <= r_sbx1) and (r_sbx1 < 2**11-12)) then
      if ((-2**10 <= r_sbx1) and (r_sbx1 < 2**10)) then
        -- br     4+12+(sBx-1)*16
        n_1 := NOP_TYPE_I(NOP_BR, 0, 0, 12 + (r_sbx1 * 16));
      else
        giveup := true;
      end if;

    when ROP_JMPIF | ROP_JMPNOT =>
      if ((-2**11 <= r_sbx1) and (r_sbx1 < 2**11)) then
        -- ldw    r2, A*4(rSTK)
        -- ori    r2, r2, Qfalse
        -- addi   r2, r2, -Qfalse
        -- bne    r2, r0, 4+(sBx-1)*16  (for JMPIF)
        -- beq    r2, r0, 4+(sBx-1)*16  (for JMPNOT)
        n_1 := NOP_TYPE_I(NOP_LDW, c_regstk_r, 2, r_a * 4);
        n_2 := NOP_TYPE_I(NOP_ORI, 2, 2, MRB_QFALSE);
        n_3 := NOP_TYPE_I(NOP_ADDI, 2, 2, -MRB_QFALSE);
        if (r_op = ROP_JMPIF) then
          n_4 := NOP_TYPE_I(NOP_BNE, 2, 0, (r_sbx1 * 16));
        else
          n_4 := NOP_TYPE_I(NOP_BEQ, 2, 0, (r_sbx1 * 16));
        end if;
      else
        giveup := true;
      end if;

    when ROP_ONERR =>
      -- if ((-2**11-12 <= r_sbx) and (r_sbx < 2**11-12)) then
      if ((-2**10 <= r_sbx1) and (r_sbx1 < 2**10)) then
        -- nextpc r5
        -- addi   r5, r5, 12+(sBx-1)*16
        -- call   fptr
        n_1 := NOP_TYPE_R(NOP_NEXTPC, 0, 0, 5);
        n_2 := NOP_TYPE_I(NOP_ADDI, 5, 5, 12 + (r_sbx1 * 16));
        n_3 := NOP_TYPE_J(NOP_CALL, c_deleg_r);
      else
        giveup := true;
      end if;

    when ROP_RESCUE =>
      -- call   fptr
      -- stw    r2, A*4(rSTK)
      n_3 := NOP_TYPE_J(NOP_CALL, c_deleg_r);
      n_4 := NOP_TYPE_I(NOP_STW, c_regstk_r, 2, r_a * 4);

    when ROP_POPERR | ROP_EPOP =>
      -- movi   r5, A
      -- call   fptr
      n_1 := NOP_TYPE_I(NOP_ADDI, 0, 5, r_a);
      n_3 := NOP_TYPE_J(NOP_CALL, c_deleg_r);

    when ROP_RAISE =>
      giveup := true; -- TODO
      -- ldw    r5, A*4(rSTK)
      -- call   fptr
      n_1 := NOP_TYPE_I(NOP_LDW, c_regstk_r, 5, r_a * 4);
      n_3 := NOP_TYPE_J(NOP_CALL, c_deleg_r);

    when ROP_EPUSH =>
      giveup := true; -- TODO
      -- movui  r5, Bx
      -- call   fptr
      n_1 := NOP_TYPE_I(NOP_ORI, 0, 5, r_bx);
      n_3 := NOP_TYPE_J(NOP_CALL, c_deleg_r);

    when ROP_SEND | ROP_SENDB | ROP_TAILCALL =>
      giveup := true; -- TODO
      -- addi   r5, rSTK, A*4
      -- ldhu   r6, B*2(rSYM)
      -- movi   r7, C
      -- call   fptr
      n_1 := NOP_TYPE_I(NOP_ADDI, c_regstk_r, 5, r_a * 4);
      n_2 := NOP_TYPE_I(NOP_LDHU, c_regsym_r, 6, r_b * 2);
      n_3 := NOP_TYPE_I(NOP_ADDI, 0, 7, r_c);
      n_4 := NOP_TYPE_J(NOP_CALL, c_deleg_r);

    when ROP_CALL | ROP_SUPER =>
      giveup := true; -- TODO
      -- addi   r5, rSTK, A*4
      -- movi   r6, C
      -- call   fptr
      n_1 := NOP_TYPE_I(NOP_ADDI, c_regstk_r, 5, r_a * 4);
      n_3 := NOP_TYPE_I(NOP_ADDI, 0, 6, r_c);
      n_4 := NOP_TYPE_J(NOP_CALL, c_deleg_r);

    when ROP_ARGARY =>
      giveup := true; -- TODO
      -- movui  r5, Bx
      -- call   fptr
      -- stw    r2, A*4(rSTK)
      n_1 := NOP_TYPE_I(NOP_ORI, 0, 5, r_bx);
      n_3 := NOP_TYPE_J(NOP_CALL, c_deleg_r);
      n_4 := NOP_TYPE_I(NOP_STW, c_regstk_r, 2, r_a * 4);

    when ROP_ENTER =>
      giveup := true; -- TODO
      -- movhi  r5, %hi(Ax)
      -- ori    r5, r5, %lo(Ax)
      -- call   fptr
      n_1 := NOP_TYPE_I(NOP_ORHI, 0, 5, r_ax / (2**16));
      n_2 := NOP_TYPE_I(NOP_ORI, 5, 5, r_ax mod (2**16));
      n_3 := NOP_TYPE_J(NOP_CALL, c_deleg_r);

    when ROP_RETURN =>
      giveup := true; -- TODO
      -- ldw    r5, A*4(rSTK)
      -- movi   r6, B
      -- jmpi   fptr
      n_1 := NOP_TYPE_I(NOP_LDW, c_regstk_r, 5, r_a * 4);
      n_2 := NOP_TYPE_I(NOP_ADDI, 0, 6, r_b);
      n_3 := NOP_TYPE_J(NOP_JMPI, c_deleg_r);

    when ROP_BLKPUSH =>
      giveup := true; -- TODO
      -- movui  r5, Bx
      -- call   fptr
      -- stw    r2, A*4(rSTK)
      n_1 := NOP_TYPE_I(NOP_ORI, 0, 5, r_bx);
      n_3 := NOP_TYPE_J(NOP_CALL, c_deleg_r);
      n_4 := NOP_TYPE_I(NOP_STW, c_regstk_r, 2, r_a * 4);

    when ROP_ADD | ROP_SUB | ROP_MUL | ROP_DIV |
         ROP_EQ | ROP_LT | ROP_LE | ROP_GT | ROP_GE =>
      -- ldw    r5, A*4(rSTK)
      -- ldw    r6, (A+1)*4(rSTK)
      -- call   fptr
      -- stw    r2, A*4(rSTK)
      n_1 := NOP_TYPE_I(NOP_LDW, c_regstk_r, 5, r_a * 4);
      n_2 := NOP_TYPE_I(NOP_LDW, c_regstk_r, 6, (r_a + 1) * 4);
      n_3 := NOP_TYPE_J(NOP_CALL, c_deleg_r);
      n_4 := NOP_TYPE_I(NOP_STW, c_regstk_r, 2, r_a * 4);

    when ROP_ADDI | ROP_SUBI =>
      -- ldw    r5, A*4(rSTK)
      -- movui  r6, (C<<MRB_FIXNUM_SHIFT) + MRB_FIXNUM_FLAG
      -- call   fptr
      -- stw    r2, A*4(rSTK)
      n_1 := NOP_TYPE_I(NOP_LDW, c_regstk_r, 5, r_a * 4);
      n_2 := NOP_TYPE_I(NOP_ORI, 0, 6, (r_c * 2**MRB_FIXNUM_SHIFT) + MRB_FIXNUM_FLAG);
      n_3 := NOP_TYPE_J(NOP_CALL, c_deleg_r);
      n_4 := NOP_TYPE_I(NOP_STW, c_regstk_r, 2, r_a * 4);

    when others =>
      giveup := true;
    end case;

    if (giveup) then
      -- nextpc r2
      -- movhi  r3, %hi(r_inst)
      -- ori    r3, %lo(r_inst)
      -- jmpi   gptr
      n_1 := NOP_TYPE_R(NOP_NEXTPC, 0, 0, 2);
      n_2 := NOP_TYPE_I(NOP_ORHI, 0, 3, to_integer(unsigned(r_inst(31 downto 16))));
      n_3 := NOP_TYPE_I(NOP_ORI, 3, 3, to_integer(unsigned(r_inst(15 downto 0))));
      n_4 := NOP_TYPE_J(NOP_JMPI, c_leave_r);
    end if;

    return n_4 & n_3 & n_2 & n_1;
  end function INST_RITE_TO_NIOS2;  -- }}}

begin -- rtl

  -- RiteVM instruction fetch
  r_faddr_w <= n_address(RITE_MEM_WIDTH+2-1 downto 4);
  r_address <= c_rbase_r & r_faddr_r;
  r_read    <= r_read_r;
  process (clk) begin
    if (rising_edge(clk)) then
      if (reset = '1') then
        r_faddr_r <= (others => '0');
      elsif (n_read = '1') then
        r_faddr_r <= r_faddr_w;
      end if;
    end if;
  end process;
  process (clk) begin
    if (rising_edge(clk)) then
      if (reset = '1') then
        r_read_r  <= '0';
        r_inst_r  <= (others => '1');
        r_valid_r <= '0';
      elsif ((r_read_r = '1') and (r_waitrequest = '0')) then
        r_read_r  <= '0';
        r_inst_r  <= r_readdata;
        r_valid_r <= '1';
      elsif ((n_read = '1') and
             ((r_faddr_w /= r_faddr_r) or (r_valid_r = '0'))) then
        r_read_r  <= '1';
        r_valid_r <= '0';
      end if;
    end if;
  end process;

  -- NiosII convertion
  n_readdata    <= n_inst_r;
  n_waitrequest <= n_wait_r;
  n_insts_w     <= INST_RITE_TO_NIOS2(r_inst_r);
  process (clk) begin
    if (rising_edge(clk)) then
      if (reset = '1') then
        n_wait_r  <= '1';
      elsif (n_wait_r = '0') then
        n_wait_r  <= '1';
      elsif ((n_read = '1') and
             ((r_faddr_w = r_faddr_r) and (r_valid_r /= '0'))) then
        n_wait_r  <= '0';
      end if;
    end if;
  end process;
  process (clk) begin
    if (rising_edge(clk)) then
      if (reset = '1') then
        n_inst_r  <= NOP_FILLER;
      else
        case n_address(3 downto 2) is
          when "00" =>
            n_inst_r <= n_insts_w(n_inst_t'length*1-1 downto n_inst_t'length*0);
          when "01" =>
            n_inst_r <= n_insts_w(n_inst_t'length*2-1 downto n_inst_t'length*1);
          when "10" =>
            n_inst_r <= n_insts_w(n_inst_t'length*3-1 downto n_inst_t'length*2);
          when others =>
            n_inst_r <= n_insts_w(n_inst_t'length*4-1 downto n_inst_t'length*3);
        end case;
      end if;
    end if;
  end process;

  -- Control/cache registers
  c_readdata(regitem_t'range) <= c_reada_r;
  c_addra_w   <= to_integer(unsigned(c_address));
  c_addrb_w   <= to_integer(unsigned(r_readdata(c_address'length-1 downto 0)));
  process (clk) begin
    -- Port A (read/write through avm)
    if (rising_edge(clk)) then
      if (c_write = '1') then
        c_regmem(c_addra_w) := c_writedata(regitem_t'range);
      end if;
      c_reada_r <= c_regmem(c_addra_w);
    end if;
  end process;
  process (clk) begin
    -- Port B (read from internal logic)
    if (rising_edge(clk)) then
      if ((r_read_r = '1') and (r_waitrequest = '0')) then
        c_deleg_r <= c_regmem(c_addrb_w)(c_deleg_r'range);
      end if;
    end if;
  end process;
  process (clk) begin
    if (rising_edge(clk)) then
      if (reset = '1') then
        c_rbase_r   <= (others => '0');
        c_regstk_r  <= 0;
        c_reglit_r  <= 0;
        c_regsym_r  <= 0;
        c_leave_r   <= (others => '0');
      elsif (c_write = '1') then
        case (to_integer(unsigned(c_address))) is
          when CADDR_RBASE =>
            c_rbase_r   <= c_writedata(c_rbase_r'range);
          when CADDR_REGSTK =>
            c_regstk_r  <= to_integer(unsigned(c_writedata(4 downto 0)));
          when CADDR_REGLIT =>
            c_reglit_r  <= to_integer(unsigned(c_writedata(4 downto 0)));
          when CADDR_REGSYM =>
            c_regsym_r  <= to_integer(unsigned(c_writedata(4 downto 0)));
          when CADDR_LEAVE =>
            c_leave_r   <= c_writedata(c_leave_r'range);
          when others =>
            null;
        end case;
      end if;
    end if;
  end process;

end architecture rtl;
-- vim: foldmethod=marker
