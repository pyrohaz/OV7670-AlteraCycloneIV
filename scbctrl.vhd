library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity scbctrl is
    generic(
        F640X480: std_logic := '1'
    );
    port(
        clk, nrst:  in std_logic;
        
        scl, sda:   inout std_logic;
        
        done:       out std_logic
    );
end entity;

architecture rtl of scbctrl is
    component scb is
    port(
        clk, nrst:  in std_logic;
        scl:        inout std_logic;
        sda:        inout std_logic;
        
        mode:       in std_logic_vector(2 downto 0);
        en:         in std_logic;
        di:         in std_logic_vector(7 downto 0);
        do:         out std_logic_vector(7 downto 0);
        bsy:        out std_logic
    );
    end component; 
    constant NREG: integer := 165+1;
    type regar is array (0 to NREG) of std_logic_vector(7 downto 0);

    constant REGS: regar := ( x"00",
        x"3a", x"40", x"12", x"32", x"17", x"18", x"19", x"1a", x"03", x"0c", x"3e", x"70", x"71", x"72", x"73", x"a2", 
        x"11", x"7a", x"7b", x"7c", x"7d", x"7e", x"7f", x"80", x"81", x"82", x"83", x"84", x"85", x"86", x"87", x"88", 
        x"89", x"13", x"00", x"10", x"0d", x"14", x"a5", x"ab", x"24", x"25", x"26", x"9f", x"a0", x"a1", x"a6", x"a7", 
        x"a8", x"a9", x"aa", x"13", x"0e", x"0f", x"16", x"1e", x"21", x"22", x"29", x"33", x"35", x"37", x"38", x"39", 
        x"3c", x"4d", x"4e", x"69", x"6b", x"74", x"8d", x"8e", x"8f", x"90", x"91", x"92", x"96", x"9a", x"b0", x"b1", 
        x"b2", x"b3", x"b8", x"43", x"44", x"45", x"46", x"47", x"48", x"59", x"5a", x"5b", x"5c", x"5d", x"5e", x"64", 
        x"65", x"66", x"94", x"95", x"6c", x"6d", x"6e", x"6f", x"6a", x"13", x"15", x"4f", x"50", x"51", x"52", x"53", 
        x"54", x"55", x"56", x"57", x"58", x"41", x"3f", x"75", x"76", x"4c", x"77", x"3d", x"4b", x"c9", x"41", x"34", 
        x"3b", x"a4", x"96", x"97", x"98", x"99", x"9a", x"9b", x"9c", x"9d", x"9e", x"78", x"79", x"c8", x"79", x"c8", 
        x"79", x"c8", x"79", x"c8", x"79", x"c8", x"79", x"c8", x"79", x"c8", x"79", x"c8", x"79", x"c8", x"79", x"c8", 
        x"79", x"c8", x"69", x"09", x"3b", x"2d");

    --constant VALS: regar := ( x"00",
    --    x"04", x"10", x"04", x"80", x"17", x"05", x"02", x"7b", x"0a", x"0c", x"00", x"00", x"01", x"11", x"09", x"02", 
    --    x"01", x"20", x"1c", x"28", x"3c", x"55", x"68", x"76", x"80", x"88", x"8f", x"96", x"a3", x"af", x"c4", x"d7", 
    --    x"e8", x"e0", x"00", x"00", x"00", x"10", x"05", x"07", x"75", x"63", x"A5", x"78", x"68", x"03", x"df", x"df", 
    --    x"f0", x"90", x"94", x"e5", x"61", x"4b", x"02", x"07", x"02", x"91", x"07", x"0b", x"0b", x"1d", x"71", x"2a", 
    --    x"78", x"40", x"20", x"5d", x"40", x"19", x"4f", x"00", x"00", x"00", x"00", x"00", x"00", x"80", x"84", x"0c", 
    --    x"0e", x"82", x"0a", x"14", x"f0", x"34", x"58", x"28", x"3a", x"88", x"88", x"44", x"67", x"49", x"0e", x"04", 
    --    x"20", x"05", x"04", x"08", x"0a", x"55", x"11", x"9f", x"40", x"e7", x"00", x"80", x"80", x"00", x"22", x"5e", 
    --    x"80", x"00", x"70", x"90", x"9e", x"08", x"05", x"05", x"e1", x"0F", x"0a", x"c2", x"09", x"28", x"38", x"11", 
    --    x"02", x"89", x"00", x"30", x"20", x"30", x"84", x"29", x"03", x"4c", x"3f", x"04", x"01", x"f0", x"0f", x"00", 
    --    x"10", x"7e", x"0a", x"80", x"0b", x"01", x"0c", x"0f", x"0d", x"20", x"09", x"80", x"02", x"c0", x"03", x"40", 
    --    x"05", x"30", x"aa", x"00", x"42", x"01");
    
    constant VALS: regar := ( x"00",
        x"04", x"10", x"04", x"b6", x"13", x"01", x"02", x"7a", x"0a", x"00", x"00", x"3a", x"35", x"11", x"f0", x"02", 
        x"01", x"20", x"1c", x"28", x"3c", x"55", x"68", x"76", x"80", x"88", x"8f", x"96", x"a3", x"af", x"c4", x"d7", 
        x"e8", x"e0", x"00", x"00", x"00", x"10", x"05", x"07", x"75", x"63", x"A5", x"78", x"68", x"03", x"df", x"df", 
        x"f0", x"90", x"94", x"e5", x"61", x"4b", x"02", x"07", x"02", x"91", x"07", x"0b", x"0b", x"1d", x"71", x"2a", 
        x"78", x"40", x"20", x"5d", x"40", x"19", x"4f", x"00", x"00", x"00", x"00", x"00", x"00", x"80", x"84", x"0c", 
        x"0e", x"82", x"0a", x"14", x"f0", x"34", x"58", x"28", x"3a", x"88", x"88", x"44", x"67", x"49", x"0e", x"04", 
        x"20", x"05", x"04", x"08", x"0a", x"55", x"11", x"9f", x"40", x"e7", x"00", x"80", x"80", x"00", x"22", x"5e", 
        x"80", x"00", x"70", x"90", x"9e", x"08", x"05", x"05", x"e1", x"0F", x"0a", x"c2", x"09", x"28", x"38", x"11", 
        x"02", x"89", x"00", x"30", x"20", x"30", x"84", x"29", x"03", x"4c", x"3f", x"04", x"01", x"f0", x"0f", x"00", 
        x"10", x"7e", x"0a", x"80", x"0b", x"01", x"0c", x"0f", x"0d", x"20", x"09", x"80", x"02", x"c0", x"03", x"40", 
        x"05", x"30", x"aa", x"00", x"42", x"01");
        
    constant OVADDR: std_logic_vector(7 downto 0) := x"42";
    type gstates is (INIT, IDLE);
    type txstates is(START, TXB1, TXB2, TXB3, ACK1, ACK2, ACK3, STOP, DLY, ERR);
    
    constant DELAYL: unsigned(11 downto 0) := x"300";
    constant DELAYS: unsigned(11 downto 0) := '0'&DELAYL(10 downto 0);
    constant DELAYSL: unsigned(11 downto 0) := DELAYL+DELAYS;
    constant DELAYPB: unsigned(11 downto 0) := x"F00";
    
    signal gst: gstates;
    signal st, nst: txstates;
    signal bsyo: std_logic;
    signal rcnt: unsigned(7 downto 0);
    signal dcnt: unsigned(11 downto 0);
    signal wcnt: unsigned(6 downto 0);
    signal errf: std_logic;
    
    signal mode: std_logic_vector(2 downto 0);
    signal en, bsy: std_logic;
    signal di, do: std_logic_vector(7 downto 0);
begin
    iscb: scb
    port map(
        clk => clk,
        nrst => nrst,
        
        scl => scl,
        sda => sda,
        
        mode => mode,
        en => en,
        di => do,
        do => di,
        bsy => bsy
    );

    process(nrst, clk)
    begin
        if(nrst = '0') then
            mode <= "000";
            en <= '0';
            gst <= INIT;
            st <= START;
            bsyo <= '0';
            done <= '0';
            errf <= '0';
            wcnt <= (others => '1');
            rcnt <= (others => '0');
        elsif(rising_edge(clk)) then
            if(wcnt = 0) then
                bsyo <= bsy;
                
                case gst is
                when INIT =>
                    case st is
                    when START =>
                        if(bsyo = '0' and bsy = '0') then
                            if(rcnt /= NREG) then
                                mode <= "000";
                                en <= '1';
                            else
                                gst <= IDLE;
                            end if;
                        elsif(bsyo = '0' and bsy = '1') then
                            st <= TXB1;
                            en <= '0';
                        end if;
                    
                    when TXB1 =>
                        if(bsyo = '0' and bsy = '0') then
                            mode <= "100";
                            en <= '1';
                            do <= OVADDR;
                        elsif(bsyo = '0' and bsy = '1') then
                            st <= ACK1;
                            en <= '0';
                        end if;
                        
                    when ACK1 =>
                        if(bsyo = '0' and bsy = '0') then
                            if(di(0) = '0') then
                                errf <= '1';
                                st <= STOP;
                            else
                                dcnt <= DELAYS;
                                st <= DLY;
                                nst <= TXB2;
                            end if;
                        end if;
                        
                    when TXB2 => 
                        if(bsyo = '0' and bsy = '0') then
                            mode <= "100";
                            en <= '1';
                            do <= REGS(to_integer(rcnt));
                        elsif(bsyo = '0' and bsy = '1') then
                            st <= ACK2;
                            en <= '0';
                        end if;
                        
                    when ACK2 =>
                        if(bsyo = '0' and bsy = '0') then
                            if(di(0) = '0') then
                                errf <= '1';
                                st <= STOP;
                            else
                                dcnt <= DELAYS;
                                st <= DLY;
                                nst <= TXB3;
                            end if;
                        end if;
                        
                    when TXB3 => 
                        if(bsyo = '0' and bsy = '0') then
                            mode <= "100";
                            en <= '1';
                            do <= VALS(to_integer(rcnt));
                        elsif(bsyo = '0' and bsy = '1') then
                            st <= ACK3;
                            en <= '0';
                        end if;
                        
                    when ACK3 =>
                        if(bsyo = '0' and bsy = '0') then
                            if(di(0) = '0') then
                                errf <= '1';
                                st <= STOP;
                            else
                                st <= STOP;
                            end if;
                        end if;
                        
                    when STOP =>
                        if(bsyo = '0' and bsy = '0') then
                            mode <= "001";
                            en <= '1';
                        elsif(bsyo = '0' and bsy = '1') then
                            en <= '0';
                            if(errf = '1') then 
                                st <= ERR;
                            else
                                st <= DLY;
                                nst <= START;
                                dcnt <= DELAYPB;
                                rcnt <= rcnt + 1;
                            end if;
                            
                        end if;
                        
                    when DLY =>
                        if(dcnt = 0) then
                            st <= nst;
                        else
                            dcnt <= dcnt - 1;
                        end if;
                    
                    when ERR =>
                        errf <= '0';
                        nst <= START;
                        --nst <= ERR;
                        st <= DLY;
                        dcnt <= (others => '1');
                        rcnt <= (others => '0');
                    end case;
                when IDLE =>
                    done <= '1';
                end case;
            else
                wcnt <= wcnt - 1;
            end if;
        end if;
    end process;
end rtl;