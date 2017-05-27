library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity ov7670 is
port(
    xclk, nrst: in std_logic;
    
    pclk:       out std_logic;
    hs, vs:     out std_logic;
    do:         out std_logic_vector(7 downto 0)
);
end entity;

architecture rtl of ov7670 is
    signal xc, yc: unsigned(10 downto 0);
    signal pcnt: unsigned(15 downto 0);
begin
    hs <= '1' when xc < 320*2 else '0';
    vs <= '0' when yc < 240 else '1';
    
    --do <= std_logic_vector(pcnt(15 downto 8)) when xc(0) = '0' else std_logic_vector(pcnt(7 downto 0));
    
    pclk <= xclk;
    
    process(xclk, nrst)
    begin
        if(nrst = '0') then
            xc <= (others => '0');
            yc <= (others => '0');
            pcnt <= (others => '0');
            do <= (others => '0');
        elsif(rising_edge(xclk)) then
            if(xc = 330*2-1) then
                if(yc = 242-1) then
                    yc <= (others => '0');
                    pcnt <= (others => '0');
                else
                    yc <= yc + 1;
                end if;
                xc <= (others => '0');  
            else
                xc <= xc + 1;
            end if;
            
            if(xc(0) = '1' and xc<320*2 and yc<240) then
                --pcnt <= pcnt + 100;
                if(xc*2<yc) then pcnt <= (others => '0');
                else pcnt <= (others => '1'); end if;
            end if;
        elsif(falling_edge(xclk)) then
            if(xc(0) = '0') then
                do <= std_logic_vector(pcnt(15 downto 8));
            else
                do <= std_logic_vector(pcnt(7 downto 0));
            end if;
        end if;
    end process;
end rtl;