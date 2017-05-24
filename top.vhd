library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity top is
port(
    clk, nrst:  in std_logic;
    
    s_cke, s_clk: out std_logic;
    s_cs, s_we, s_cas, s_ras: out std_logic;
    s_addr: out std_logic_vector(12 downto 0);
    s_ba: out std_logic_vector(1 downto 0);
    s_d: inout std_logic_vector(15 downto 0);
    s_dq: out std_logic_vector(1 downto 0);
    
    utx:    out std_logic;
    urx:    in std_logic;
    
    --Camera interface
    cdi:            in std_logic_vector(7 downto 0);
    cxclk:          out std_logic;
    cpclk:          in std_logic;
    cscl, csda:     inout std_logic;
    chs, cvs:       in std_logic;
    cnrst:          out std_logic;
    
    done:           out std_logic;
    
    seg7en:		out std_logic_vector(3 downto 0);
    seg7c:		out std_logic_vector(6 downto 0)
);
end entity;

architecture rtl of top is
    component sdramctrl is
    port(
        clk, nrst:  in std_logic;
        
        --SDRAM IF
        s_cke, s_clk: out std_logic;
        s_cs, s_we, s_cas, s_ras: out std_logic;
        s_addr: out std_logic_vector(12 downto 0);
        s_ba: out std_logic_vector(1 downto 0);
        s_d: inout std_logic_vector(15 downto 0);
        s_dq: out std_logic_vector(1 downto 0);
        
        --Memory IF
        addr:   in std_logic_vector(23 downto 0);
        di:     in std_logic_vector(15 downto 0);
        do:     out std_logic_vector(15 downto 0);
        wr, en: in std_logic;
        bsy:    out std_logic
    );
    end component;
    
    component pixfifo IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (34 DOWNTO 0);
		rdreq		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		empty		: OUT STD_LOGIC ;
		full		: OUT STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (34 DOWNTO 0);
		usedw		: OUT STD_LOGIC_VECTOR (9 DOWNTO 0)
	);
    END component;

    component pll IS
        PORT
        (
            inclk0		: IN STD_LOGIC  := '0';
            c0		: OUT STD_LOGIC 
        );
    END component;    
    
    component fifohandler is
    port(
        clk, nrst:  in std_logic;
        
        --Pixel FIFO
        fifodi:     in std_logic_vector(34 downto 0);
        fiford:     out std_logic;
        fifoused:   in std_logic_vector(9 downto 0);
        fifoempty:  in std_logic;
        
        --UART IF
        uaddr:      in std_logic_vector(23 downto 0);
        udo:        out std_logic_vector(15 downto 0);
        uen:        in std_logic;
        ubsy:       out std_logic;
        
        --Memory IF
        addr:       out std_logic_vector(23 downto 0);
        di:         in std_logic_vector(15 downto 0);
        do:         out std_logic_vector(15 downto 0);
        wr, en:     out std_logic;
        bsy:        in std_logic
    );
    end component;
    
    component uarthandler is
    port(
        clk, nrst:  in std_logic;
        --UART IF
        uaddr:      out std_logic_vector(23 downto 0);
        udi:        in std_logic_vector(15 downto 0);
        uen:        out std_logic;
        ubsy:       in std_logic;
        
        urx:        in std_logic;
        utx:        out std_logic
    );
    end component;
    
    component pixwriter is
    port(
        clk, nrst:  in std_logic;
        
        fifodo:     out std_logic_vector(34 downto 0);
        fifowr:     out std_logic;
        fifofull:   in std_logic
    );
    end component;
    
    component ovcapture is
    port(
        clk:        in std_logic;
        nrst:       in std_logic;
            
        pclk:       in std_logic;
        hs, vs:     in std_logic;
        di:         in std_logic_vector(7 downto 0);
        
        fifodo:     out std_logic_vector(34 downto 0);
        fifowr:     out std_logic;
        fifofull:   in std_logic
    );
    end component;
    
    component scbctrl is
    generic(
        F640X480: std_logic := '1'
    );
    port(
        clk, nrst:  in std_logic;
        
        scl, sda:   inout std_logic;
        
        done:       out std_logic
    );
    end component;
    
    component rsthandler is
    port(
        clk, nrsti: in std_logic;
        nrsto:      out std_logic
    );
    end component;

    component scbmodule is
    port(
        clk, nrst:  in std_logic;
        
        done:       out std_logic;
        
        scl, sda:   inout std_logic
    );
    end component;
    
    component seg7 is
        port(
            clk, nrst:  in std_logic;
        
            rseg1:      in std_logic_vector(15 downto 0);
            seg7en:		out std_logic_vector(3 downto 0);
            seg7c:		out std_logic_vector(6 downto 0)
        );
    end component;
    
    signal pllclk: std_logic;
    signal nrsti: std_logic;
    
    signal pixfdi, pixfdo: std_logic_vector(34 downto 0);
    signal pixfwr, pixfrd, pixffull, pixfempty: std_logic;
    signal pixfused: std_logic_vector(9 downto 0);
    
    signal ubsy, uen: std_logic;
    signal udo: std_logic_vector(15 downto 0);
    signal uaddr: std_logic_vector(23 downto 0);
    
    signal addr: std_logic_vector(23 downto 0);
    signal do, di: std_logic_vector(15 downto 0);
    signal wr, en, bsy: std_logic;
    
    signal camrdy: std_logic;
    
    signal psc: unsigned(1 downto 0);
    signal rseg: std_logic_vector(15 downto 0);
begin
    cxclk <= psc(1);
    
    done <= '0';
    
    irh: rsthandler
    port map(
        clk => clk,
        nrsti => nrst,
        nrsto => nrsti
    );
    
    --cnrst <= '0' when nrsti = '0' else 'Z';
    cnrst <= nrsti;
    
    process(clk, nrsti)
    begin
        if(nrsti = '0') then
            psc <= "00";
        elsif(rising_edge(clk)) then
            psc <= psc + 1;
        end if;
    end process;

    ipll: pll
    port map(
        inclk0 => clk,
        c0 => pllclk
    );
    
    isc: sdramctrl
    port map(
        clk => pllclk,
        nrst => nrsti,
        
        s_cke => s_cke,
        s_clk => s_clk,
        s_cs => s_cs,
        s_we => s_we,
        s_cas => s_cas,
        s_ras => s_ras,
        
        s_addr => s_addr,
        s_ba => s_ba,
        s_d => s_d,
        s_dq => s_dq,
        
        addr => addr,
        di => di,
        do => do,
        wr => wr,
        en => en,
        bsy => bsy
    );
    
    ifh: fifohandler
    port map(
        clk => pllclk,
        nrst => nrsti,
        
        fifodi => pixfdo,
        fiford => pixfrd,
        fifoused => pixfused,
        fifoempty => pixfempty,
        
        uaddr => uaddr,
        udo => udo,
        uen => uen,
        ubsy => ubsy,
        
        addr => addr,
        di => do,
        do => di,
        wr => wr,
        en => en,
        bsy => bsy
    );
    
    ipf: pixfifo
    port map(
        clock => pllclk,
        data => pixfdi,
        rdreq => pixfrd,
        wrreq => pixfwr,
        empty => pixfempty,
        full => pixffull,
        q => pixfdo,
        usedw => pixfused
    );
    --port map(
    --    data => pixfdi,
    --    rdclk => pllclk,
    --    rdreq => pixfrd,
    --    wrclk => pllclk,
    --    wrreq => pixfwr,
    --    q => pixfdo,
    --    rdempty => pixfempty,
    --    rdusedw => pixfused,
    --    wrfull => pixffull
    --);
    
    --pixfused <= (others => '0');
    
    iuh: uarthandler
    port map(
        clk => pllclk,
        nrst => nrsti,
        
        uaddr => uaddr,
        udi => udo,
        uen => uen,
        ubsy => ubsy,
        
        utx => utx,
        urx => urx
    );
    
    --ipw: pixwriter
    --port map(
    --    clk => pllclk,
    --    nrst => nrst,
    --    
    --    fifodo => pixfdi,
    --    fifowr => pixfwr,
    --    fifofull => pixffull
    --);
    
    ioc: ovcapture
    port map(
        clk => pllclk,
        nrst => nrsti,
        
        di => cdi,
        pclk => cpclk,
        vs => cvs,
        hs => chs,
        
        fifodo => pixfdi,
        fifowr => pixfwr,
        fifofull => pixffull
    );
    
    --iscb: scbctrl
    --port map(
    --    clk => clk,
    --    nrst => nrsti,
    --    scl => cscl,
    --    sda => csda,
    --    done => camrdy
    --);
    
    iscb: scbmodule
    port map(
        clk => clk,
        nrst => nrsti,
        scl => cscl,
        sda => csda,
        done => camrdy
    );
    
    iseg7: seg7
    port map(
        clk => clk,
        nrst => nrst,
        
        rseg1 => rseg,
        seg7en => seg7en,
        seg7c => seg7c
    );
    
    rseg <= "000000"&pixfused;
    --rseg <= x"1234";
    
end rtl;