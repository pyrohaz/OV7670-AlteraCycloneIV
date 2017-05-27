library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity imgprekernel is
port(
    clk, nrst:  in std_logic;
    
    newframe:   in std_logic;
    pixi:       in std_logic_vector(15 downto 0);
    pixirdy:    in std_logic;
    pixo:       out std_logic_vector(7 downto 0);
    pixordy:    out std_logic;
    
    done:       out std_logic
);
end entity;

architecture rtl of imgprekernel is
    constant XPIX:          integer := 640;
    constant YPIX:          integer := 480;
    constant KERNEL_SIZE:   integer := 3;
    
    signal pxcnt: unsigned(18 downto 0);
    signal newframeo: std_logic;
begin
    pixo <= std_logic_vector(resize(unsigned(pixi(4 downto 2)), 8) + resize(unsigned(pixi(10 downto 6)), 8) + resize(unsigned(pixi(15 downto 13)), 8)) when pxcnt < XPIX*YPIX else (others => '0');
    pixordy <= pixirdy when pxcnt < XPIX*YPIX else '1' when (pxcnt >= XPIX*YPIX and pxcnt < XPIX*(YPIX+KERNEL_SIZE)) else '0';
    done <= '1' when pxcnt = XPIX*(YPIX+KERNEL_SIZE) else '0';
    
    process(clk, nrst)
    begin
        if(nrst = '0') then
            pxcnt <= (others => '0');
            newframeo <= '1';
        elsif(rising_edge(clk)) then
            newframeo <= newframe;
            if(newframe = '0' and newframeo = '1') then
                pxcnt <= (others => '0');
            elsif((pixirdy = '1' and pxcnt < XPIX*YPIX) or (pxcnt >= XPIX*YPIX and pxcnt < XPIX*(YPIX+KERNEL_SIZE))) then
                pxcnt <= pxcnt + 1;
            end if;
        end if;
    end process;
end rtl;
