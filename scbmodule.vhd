library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity scbmodule is
port(
    clk, nrst:  in std_logic;
    
    done:       out std_logic;
    
    scl, sda:   inout std_logic
);
end entity;

architecture rtl of scbmodule is
    component sccb is
    generic(
        CLK_FREQ:   integer;
        I2C_FREQ:   integer
    );
    port(
        clk, nrst:  in std_logic;
        
        scl, sda:   inout std_logic;
        
        devaddr:    in std_logic_vector(7 downto 0);
        regaddr:    in std_logic_vector(7 downto 0);
        regdatai:   in std_logic_vector(7 downto 0);
        regdatao:   out std_logic_vector(7 downto 0);
        
        en, wr:     in std_logic;
        busy:       out std_logic
    );
    end component;

    constant NREG: integer := 168;
    type regar is array (0 to 167) of std_logic_vector(7 downto 0);
    constant regs: regar := (
    x"12", x"3a", x"40", x"12", x"32", x"17", x"18", x"19", x"1a", x"03", x"0c", x"3e", x"70", x"71", x"72", x"73", 
    x"a2", x"11", x"7a", x"7b", x"7c", x"7d", x"7e", x"7f", x"80", x"81", x"82", x"83", x"84", x"85", x"86", x"87", 
    x"88", x"89", x"13", x"00", x"10", x"0d", x"14", x"a5", x"ab", x"24", x"25", x"26", x"9f", x"a0", x"a1", x"a6", 
    x"a7", x"a8", x"a9", x"aa", x"13", x"0e", x"0f", x"16", x"1e", x"21", x"22", x"29", x"33", x"35", x"37", x"38", 
    x"39", x"3c", x"4d", x"4e", x"69", x"6b", x"74", x"8d", x"8e", x"8f", x"90", x"91", x"92", x"96", x"9a", x"b0", 
    x"b1", x"b2", x"b3", x"b8", x"43", x"44", x"45", x"46", x"47", x"48", x"59", x"5a", x"5b", x"5c", x"5d", x"5e", 
    x"64", x"65", x"66", x"94", x"95", x"6c", x"6d", x"6e", x"6f", x"6a", x"13", x"15", x"4f", x"50", x"51", x"52", 
    x"53", x"54", x"55", x"56", x"57", x"58", x"41", x"3f", x"75", x"76", x"4c", x"77", x"3d", x"4b", x"c9", x"41", 
    x"34", x"3b", x"a4", x"96", x"97", x"98", x"99", x"9a", x"9b", x"9c", x"9d", x"9e", x"78", x"79", x"c8", x"79", 
    x"c8", x"79", x"c8", x"79", x"c8", x"79", x"c8", x"79", x"c8", x"79", x"c8", x"79", x"c8", x"79", x"c8", x"79", 
    x"c8", x"79", x"c8", x"69", x"09", x"3b", x"2d", x"00");
    constant vals: regar := (
    x"80", x"04", x"10", x"04", x"80", x"17", x"05", x"02", x"7b", x"0a", x"00", x"00", x"3a", x"35", x"11", x"f0", 
    x"02", x"01", x"20", x"1c", x"28", x"3c", x"55", x"68", x"76", x"80", x"88", x"8f", x"96", x"a3", x"af", x"c4", 
    x"d7", x"e8", x"e0", x"00", x"00", x"00", x"10", x"05", x"07", x"75", x"63", x"a5", x"78", x"68", x"03", x"df", 
    x"df", x"f0", x"90", x"94", x"e5", x"61", x"4b", x"02", x"27", x"02", x"91", x"07", x"0b", x"0b", x"1d", x"71", 
    x"2a", x"78", x"40", x"20", x"5d", x"40", x"19", x"4f", x"00", x"00", x"00", x"00", x"00", x"00", x"80", x"84", 
    x"0c", x"0e", x"82", x"0a", x"14", x"f0", x"34", x"58", x"28", x"3a", x"88", x"88", x"44", x"67", x"49", x"0e", 
    x"04", x"20", x"05", x"04", x"08", x"0a", x"55", x"11", x"9f", x"40", x"e7", x"00", x"80", x"80", x"00", x"22", 
    x"5e", x"80", x"00", x"60", x"90", x"9e", x"08", x"05", x"05", x"e1", x"0f", x"0a", x"c2", x"09", x"c8", x"38", 
    x"11", x"02", x"89", x"00", x"30", x"20", x"30", x"84", x"29", x"03", x"4c", x"3f", x"04", x"01", x"f0", x"0f", 
    x"00", x"10", x"7e", x"0a", x"80", x"0b", x"01", x"0c", x"0f", x"0d", x"20", x"09", x"80", x"02", x"c0", x"03", 
    x"40", x"05", x"30", x"aa", x"00", x"42", x"01", x"00");

    
    type states is (SDELAY, SOFTRST1A, SOFTRST1B, IDELAY, RDVER1, RDVER2, WRREG1, WRREG2, SERROR, SDONE);
    signal st, nst: states;
    
    signal rcnt: unsigned(7 downto 0);
    signal ctrlrcnt: std_logic_vector(1 downto 0);
    
    signal cnt: unsigned(19 downto 0);
    signal ctrlcnt: std_logic;
    
    signal dad, rad, rdi, rdo: std_logic_vector(7 downto 0);
    signal en, wr, busy, error: std_logic;
begin
    error <= '0';
    iss:sccb
    generic map(
        CLK_FREQ => 48000000,
        I2C_FREQ => 5000
    )
    port map(
        clk => clk,
        nrst => nrst,
        
        scl => scl,
        sda => sda,
        
        devaddr => x"42",
        regaddr => rad,
        regdatai => rdi,
        regdatao => rdo,
        
        en => en,
        wr => wr,
        busy => busy
    );

    process(clk, nrst)
    begin
        if(nrst = '0') then
            cnt <= (others => '1');
            rcnt <= (others => '0');
            st <= SDELAY;
        elsif(rising_edge(clk)) then
            st <= nst;
            
            if(ctrlcnt = '0') then
                cnt <= (others => '1');
            else
                cnt <= cnt - 1;
            end if;
            
            case ctrlrcnt is
            when "00" => rcnt <= (others => '0');
            when "01" => rcnt <= rcnt + 1;
            when others => null;
            end case;
        end if;
    end process;
    
    process(st, busy, error, rdo, cnt, rcnt)
    begin
        en <= '0';
        wr <= '0';
        done <= '0';
        ctrlcnt <= '0';
        ctrlrcnt <= "10";
        rad <= (others => '0');
        rdi <= (others => '0');
        
        case st is
        when SDELAY =>
            nst <= SDELAY;
            
            ctrlcnt <= '1';
            
            if(cnt = 0) then
                nst <= SOFTRST1A;
            end if;
            
        when SOFTRST1A =>
            nst <= SOFTRST1A;
            
            rad <= x"12";
            rdi <= x"80";
            en <= '1';
            wr <= '1';
            if(busy = '1') then
                nst <= SOFTRST1B;
            end if;
            
        when SOFTRST1B =>
            nst <= SOFTRST1B;
            if(busy = '0') then
                nst <= IDELAY;
            elsif(error = '1') then
                nst <= SERROR;
            end if;
            
        when IDELAY =>
            nst <= IDELAY;
            ctrlcnt <= '1';
            if(cnt = 0) then
                nst <= RDVER1;
            end if;
            
            
        when RDVER1 =>
            nst <= RDVER1;
            
            rad <= x"0B";
            en <= '1';
            wr <= '0';
            if(busy = '1') then
                nst <= RDVER2;
            end if;
            
        when RDVER2 =>
            nst <= RDVER2;
            
            if(busy = '0') then
                if(rdo = x"73") then
                    --ID match!
                    nst <= WRREG1;
                else
                    nst <= SERROR;
                end if;
            elsif(error = '1') then
                nst <= SERROR;
            end if;
            
        when WRREG1 =>
            nst <= WRREG1;
            rad <= REGS(to_integer(rcnt));
            rdi <= VALS(to_integer(rcnt));
            en <= '1';
            wr <= '1';
            
            if(busy = '1') then
                nst <= WRREG2;
            end if;
            
        when WRREG2 =>
            nst <= WRREG2;
            
            if(busy = '0') then
                if(rcnt = NREG) then
                    nst <= SDONE;
                else
                    nst <= WRREG1;
                    ctrlrcnt <= "01";
                end if;
            elsif(error = '1') then
                nst <= SERROR;
            end if;
            
        when SERROR =>
            nst <= SERROR;
            
        when SDONE =>
            nst <= SDONE;
            done <= '1';
        end case;
    end process;
    
end rtl;