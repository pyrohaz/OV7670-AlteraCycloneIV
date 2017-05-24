library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity sdramctrl is
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
end entity;

architecture rtl of sdramctrl is
    type states is (
        INITWAIT,
        INITPRE, INITREFR, INITMODE,
        AUTOREFRESH, ARPRECHARGE,
        IDLE, ACTIVATE, SWRITE, SREAD,
        PRECHARGE, PRECHARGEACT
    );
    
    constant CAS_LATENCY: integer := 3;
    
    signal st, nst: states;
   
    signal cnt, refcnt, opencnt: unsigned(15 downto 0);
    signal ctrlcnt, ctrlrefcnt, ctrlopencnt: std_logic;
    
    signal idi: std_logic_vector(15 downto 0);
    signal iaddr: std_logic_vector(23 downto 0);
    signal iwr: std_logic;
    
    signal latsd: std_logic;
    
    signal bank, ibank, ibankl: std_logic_vector(1 downto 0);
    signal row, irow, irowl: std_logic_vector(12 downto 0);
    signal icol: std_logic_vector(8 downto 0);
    
    signal lataddrs: std_logic;
    
    signal rowopen: std_logic;
    signal setrowopen, clrrowopen: std_logic;
begin
    ibank <= iaddr(23 downto 22);
    irow <= iaddr(21 downto 9);
    icol <= iaddr(8 downto 0);
    
    bank <= addr(23 downto 22);
    row <= addr(21 downto 9);

    process(clk, nrst)
    begin
        if(nrst = '0') then
            cnt <= (others => '0');
            refcnt <= (others => '0');
            
            idi <= (others => '0');
            iaddr <= (others => '0');
            iwr <= '0';
            
            st <= INITWAIT;
            do <= (others => '0');
            
            ibankl <= (others => '0');
            irowl <= (others => '0');
            
            opencnt <= (others => '0');
            rowopen <= '0';
        elsif(rising_edge(clk)) then
            st <= nst;
            
            if(ctrlcnt = '0') then
                cnt <= (others => '0');
            else
                cnt <= cnt + 1;
            end if;
            
            if(ctrlrefcnt = '0') then
                refcnt <= to_unsigned(700, 16);
            elsif(refcnt /= 0) then
                refcnt <= refcnt - 1;
            end if;
            
            if(ctrlopencnt = '0') then
                --100us in ticks at 100MHz clock
                opencnt <= to_unsigned(10000, 16);
            elsif(opencnt /= 0) then
                opencnt <= opencnt - 1;
            end if;
            
            if(en = '1') then
                idi <= di;
                iaddr <= addr;
                iwr <= wr;
            end if;
            
            if(latsd = '1') then
                do <= s_d;
            end if;
            
            if(lataddrs = '1') then
                ibankl <= ibank;
                irowl <= irow;
            end if;
            
            if(setrowopen = '1') then
                rowopen <= '1';
            elsif(clrrowopen = '1') then
                rowopen <= '0';
            end if;
        end if;
    end process;
    
    s_clk <= clk;
    process(st, cnt, refcnt, idi, iaddr, iwr, en,rowopen, opencnt, bank, ibank, ibankl, row, irowl, wr, irow, icol)
    begin
        s_cke <= '1';
        s_cs <= '0';
        s_ras <= '1';
        s_cas <= '1';
        s_we <= '1';
        s_addr <= (others => '0');
        s_d <= (others => 'Z');
        s_dq <= "00";
        s_ba <= "00";
        
        ctrlcnt <= '0';
        ctrlrefcnt <= '1';
        
        latsd <= '0';
        bsy <= '1';
        
        setrowopen <= '0';
        clrrowopen <= '0';
        
        ctrlopencnt <= rowopen;
        
        lataddrs <= '0';
        
        case st is
        when INITWAIT =>
            nst <= INITWAIT;
            s_dq <= "11";
            ctrlcnt <= '1';
            if(cnt = 25000) then
                nst <= INITPRE;
                ctrlcnt <= '0';
            end if;
            
        when INITPRE =>
            nst <= INITPRE;
            ctrlcnt <= '1';
            if(cnt = 2) then
                nst <= INITREFR;
                ctrlcnt <= '0';
            elsif(cnt = 0) then
                s_cs <= '0';
                s_ras <= '0';
                s_cas <= '1';
                s_we <= '0';
                s_addr(10) <= '1';
            end if;
            
        when INITREFR =>
            nst <= INITREFR;
            ctrlcnt <= '1';
            if(cnt = 8*2) then
                nst <= INITMODE;
                ctrlcnt <= '0';
            elsif(cnt(2 downto 0) = 0) then
                s_cs <= '0';
                s_ras <= '0';
                s_cas <= '0';
                s_we <= '1';
            end if;
            
        when INITMODE =>
            nst <= INITMODE;
            ctrlcnt <= '1';
            if(cnt = 2) then
                nst <= IDLE;
                ctrlcnt <= '0';
            elsif(cnt = 0) then
                s_cs <= '0';
                s_ras <= '0';
                s_cas <= '0';
                s_we <= '0';
                s_addr <= "000"&"1"&"00"&std_logic_vector(to_unsigned(CAS_LATENCY, 3))&"0"&"000";
            end if;
            
        when ARPRECHARGE =>
            nst <= ARPRECHARGE;
            bsy <= '0';
            ctrlcnt <= '1';
            clrrowopen <= '1';
            if(cnt = 1) then
                nst <= AUTOREFRESH;
                ctrlcnt <= '0';
            elsif(cnt = 0) then
                s_cs <= '0';
                s_ras <= '0';
                s_cas <= '1';
                s_we <= '0';
                s_addr(10) <= '1';
            end if;
        
        when AUTOREFRESH =>
            nst <= AUTOREFRESH;
            ctrlcnt <= '1';
            bsy <= '0';
            if(cnt = 7) then
                nst <= IDLE;
                ctrlrefcnt <= '0';
            elsif(cnt(2 downto 0) = 0) then
                s_cs <= '0';
                s_ras <= '0';
                s_cas <= '0';
                s_we <= '1';
            end if;
            
        when IDLE =>
            nst <= IDLE;
            bsy <= '0';
            if(refcnt = 0) then
                if(rowopen = '1') then
                    --Precharge all rows before refresh
                    nst <= ARPRECHARGE;
                else
                    nst <= AUTOREFRESH;
                end if;
            elsif(opencnt = 0) then
                nst <= PRECHARGE;
            elsif(en = '1') then
                if(rowopen = '1') then
                    if(bank = ibankl and row = irowl) then
                        --Go straight to read/write
                        if(wr = '1') then
                            nst <= SWRITE;
                        else
                            nst <= SREAD;
                        end if;
                    else
                        --Precharge then activate
                        nst <= PRECHARGEACT;
                    end if;
                else
                    --Activate
                    nst <= ACTIVATE;
                end if;
            end if;
            
        when ACTIVATE =>
            nst <= ACTIVATE;
            ctrlcnt <= '1';
            setrowopen <= '1';
            if(cnt = 2) then
                ctrlcnt <= '0';
                if(iwr = '1') then
                    nst <= SWRITE;
                else
                    nst <= SREAD;
                end if;
            elsif(cnt = 0) then
                s_cs <= '0';
                s_ras <= '0';
                s_cas <= '1';
                s_we <= '1';
                s_ba <= ibank;
                s_addr <= irow;
            end if;
            
        when SWRITE =>
            nst <= IDLE;
            lataddrs <= '1';
            
            s_cs <= '0';
            s_ras <= '1';
            s_cas <= '0';
            s_we <= '0';
            s_ba <= ibank;
            s_addr(8 downto 0) <= icol;
            
            s_d <= idi;
            
        when SREAD =>
            nst <= SREAD;
            s_ba <= ibank;
            
            ctrlcnt <= '1';
            if(cnt = 0) then
                s_cs <= '0';
                s_ras <= '1';
                s_cas <= '0';
                s_we <= '1';
                s_addr(8 downto 0) <= icol;
                
                lataddrs <= '1';
            elsif(cnt = CAS_LATENCY) then
                nst <= IDLE;
                latsd <= '1';
            end if;
            
        when PRECHARGE =>
            nst <= PRECHARGE;
            ctrlcnt <= '1';
            clrrowopen <= '1';
            if(cnt = 1) then
                nst <= IDLE;
            elsif(cnt = 0) then
                s_cs <= '0';
                s_ras <= '0';
                s_cas <= '1';
                s_we <= '0';
                s_addr(10) <= '1';
            end if;
            
        when PRECHARGEACT =>
            nst <= PRECHARGEACT;
            ctrlcnt <= '1';
            clrrowopen <= '1';
            if(cnt = 3) then
                ctrlcnt <= '0'; 
                --Precharge to activate delay
                nst <= ACTIVATE;
            elsif(cnt = 0) then
                s_cs <= '0';
                s_ras <= '0';
                s_cas <= '1';
                s_we <= '0';
                s_addr(10) <= '1';
            end if;
        end case;  
    end process;
    
end rtl;