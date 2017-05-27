library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity imgrcedge is
port(
    clk, nrst:  in std_logic;
    
    newframe:   in std_logic;
    pix:        in std_logic_vector(7 downto 0);
    pixrdy:     in std_logic;
    
    fifodo:     out std_logic_vector(34 downto 0);
    fifowr:     out std_logic;
    fifofull:   in std_logic
);
end entity;

architecture rtl of imgrcedge is
    constant XSIZ: integer := 640;
    constant THRESHOLD: integer := 18;
    constant HYSTERESIS: integer := 4;
    type pixbufarray is array (0 to XSIZ-1) of std_logic_vector(7 downto 0);
    signal row1, row2, row3: pixbufarray;
    
    signal pxcnt: unsigned(3 downto 0);
    signal addr: unsigned(18 downto 0);
    signal edgear: std_logic_vector(15 downto 0);
    signal ipixcnt: unsigned(10 downto 0);
    signal newframeo: std_logic;
    
    signal rc1, rc2: signed(9 downto 0);
    signal arc1, arc2: unsigned(9 downto 0);
    signal cbit: std_logic;
    
    signal fifopending: std_logic;
begin
    rc1 <= (('0'&signed('0'&row1(0))) + (signed('0'&row1(1))&'0') + ('0'&signed('0'&row1(2)))) - (('0'&signed('0'&row3(0))) + (signed('0'&row3(1))&'0') + ('0'&signed('0'&row3(2))));
    rc2 <= (('0'&signed('0'&row1(0))) + (signed('0'&row2(0))&'0') + ('0'&signed('0'&row3(0)))) - (('0'&signed('0'&row1(2))) + (signed('0'&row2(2))&'0') + ('0'&signed('0'&row3(2))));
    
    --rc1 <= ('0'&signed('0'&row1(0))) - ('0'&signed('0'&row2(1)));
    --rc2 <= ('0'&signed('0'&row1(1))) - ('0'&signed('0'&row2(0)));
    arc1 <= unsigned(rc1) when rc1>=0 else unsigned(-rc1);
    arc2 <= unsigned(rc2) when rc2>=0 else unsigned(-rc2);

    --cbit <= '1' when (arc1+arc2)>=THRESHOLD else '0';
    
    process(clk, nrst)
    begin
        if(nrst = '0') then
            newframeo <= '1';
            edgear <= (others => '0');
            pxcnt <= (others => '0');
            addr <= (others => '0');
            ipixcnt <= (others => '0');
            
            row1 <= (others => (others => '0'));
            row2 <= (others => (others => '0'));
            row3 <= (others => (others => '0'));
            
            fifodo <= (others => '0');
            fifowr <= '0';
            fifopending <= '0';
            cbit <= '0';
        elsif(rising_edge(clk)) then
            newframeo <= newframe;
            
            if(newframe = '0' and newframeo = '1') then
                ipixcnt <= (others => '0');
                addr <= (others => '0');
            end if;
            
            if((arc1+arc2)>=THRESHOLD+HYSTERESIS) then
                cbit <= '1';
            elsif((arc1+arc2)<THRESHOLD) then
                cbit <= '0';
            end if;
            
            fifowr <= '1';
            if(pixrdy = '1') then
                row1(0 to XSIZ-2) <= row1(1 to XSIZ-1);
                row2(0 to XSIZ-2) <= row2(1 to XSIZ-1);
                row3(0 to XSIZ-2) <= row3(1 to XSIZ-1);
                row1(XSIZ-1) <= row2(0);
                --row2(XSIZ-1) <= pix;
                row2(XSIZ-1) <= row3(0);
                row3(XSIZ-1) <= pix;
                
                if(ipixcnt = XSIZ*3) then
                    edgear <= edgear(14 downto 0) & cbit;
                
                    pxcnt <= pxcnt + 1;
                    if(pxcnt = 15) then
                        fifopending <= '1';
                    end if;
                else
                    ipixcnt <= ipixcnt + 1;
                end if;
            end if;
            
            fifowr <= '0';
            if(fifopending = '1' and fifofull = '0') then
                fifodo <= std_logic_vector(addr)&edgear;
                fifowr <= '1';
                fifopending <= '0';
                addr <= addr + 1;
            end if;
        end if;
    end process;
end rtl;