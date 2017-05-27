library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity pixwriter is
port(
    clk, nrst:  in std_logic;
    
    fifodo:     out std_logic_vector(34 downto 0);
    fifowr:     out std_logic;
    fifofull:   in std_logic
);
end entity;

architecture rtl of pixwriter is
    type states is (IDLE, WRFIFO, INC);
    signal st, nst: states;
    
    signal ctrl: std_logic_vector(1 downto 0);
    signal acnt: unsigned(23 downto 0);
    signal dcnt: unsigned(15 downto 0);
begin
    process(clk, nrst)
    begin
        if(nrst = '0') then
            acnt <= (others => '0');
            dcnt <= (others => '0');
            
            st <= WRFIFO;
        elsif(rising_edge(clk)) then
            st <= nst;
            
            if(ctrl = "00") then
                acnt <= (others => '0');
                dcnt <= (others => '0');
            elsif(ctrl = "01") then
                acnt <= acnt + 1;
                dcnt <= dcnt + 1;
            end if;
        end if;
    end process;
    
    process(st, acnt, dcnt, fifofull)
    begin
        fifodo <= (others => '0');
        fifowr <= '0';
        
        ctrl <= "10";
        
        case st is
        when IDLE =>
            nst <= IDLE;
        
        when WRFIFO =>
            nst <= WRFIFO;
            if(fifofull = '0') then
                fifowr <= '1';
                fifodo <= std_logic_vector(acnt(18 downto 0))&std_logic_vector(dcnt);
                nst <= INC;
            end if;
            
        when INC =>
            if(acnt = 640*480) then
                nst <= IDLE;
            else
                nst <= WRFIFO;
                ctrl <= "01";
            end if;
        end case;
    end process;
end rtl;