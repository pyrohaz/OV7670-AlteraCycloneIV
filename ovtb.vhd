library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity ovtb is
end entity;

architecture rtl of ovtb is
    component ov7670 is
    port(
        xclk, nrst: in std_logic;
        
        pclk:       out std_logic;
        hs, vs:     out std_logic;
        do:         out std_logic_vector(7 downto 0)
    );
    end component;
    
    component ovcapture is
    port(
        clk, nrst:  in std_logic;
        
        pclk:       in std_logic;
        hs, vs:     in std_logic;
        di:         in std_logic_vector(7 downto 0);
        
        fifodo:     out std_logic_vector(34 downto 0);
        fifowr:     out std_logic;
        fifofull:   in std_logic
    );
    end component;
    
    component imgprekernel is
    port(
        clk, nrst:  in std_logic;
        
        newframe:   in std_logic;
        pixi:       in std_logic_vector(15 downto 0);
        pixirdy:    in std_logic;
        pixo:       out std_logic_vector(7 downto 0);
        pixordy:    out std_logic;
        
        done:       out std_logic
    );
    end component;
    
    component imgrcedge is
    port(
        clk, nrst:  in std_logic;
        
        newframe:   in std_logic;
        pix:        in std_logic_vector(7 downto 0);
        pixrdy:     in std_logic;
        
        fifodo:     out std_logic_vector(34 downto 0);
        fifowr:     out std_logic;
        fifofull:   in std_logic
    );
    end component;
    
    constant CLK_PERIOD: time := 10 ns;
    constant XCLK_PERIOD: time := 83 ns;
    
    signal hs, vs, pclk, xclk: std_logic;
    signal do: std_logic_vector(7 downto 0);
    
    signal clk, nrst: std_logic;
    
    signal fifowr1, fifowr2: std_logic;
    signal fifodo1, fifodo2: std_logic_vector(34 downto 0);
    signal pixo: std_logic_vector(7 downto 0);
    signal pixordy: std_logic;
    signal done: std_logic;
begin
    clkp: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    xcp: process
    begin
        xclk <= '0';
        wait for XCLK_PERIOD/2;
        xclk <= '1';
        wait for XCLK_PERIOD/2;
    end process;
    
    rstp: process
    begin
        nrst <= '0';
        wait for CLK_PERIOD*2;
        nrst <= '1';
        wait;
    end process;
    
    fwp1: process
        file fo: text is out "bwimg.txt";
        variable ln: line;
    begin
        wait until vs = '0';
        while vs = '0' loop
            if(pixordy = '1') then
                write(ln, to_integer(unsigned(pixo)));
                writeline(fo, ln);
            end if;
            wait until rising_edge(clk);
        end loop;
        wait;
    end process;
    
    fwp2: process
        file fo: text is out "edgeimg.txt";
        variable ln: line;
    begin
        wait until done = '0';
        while done = '0' loop
            wait until rising_edge(fifowr2);
            write(ln, to_integer(unsigned(fifodo2(15 downto 0))));
            writeline(fo, ln);
        end loop;
        wait;
    end process;
    
    iov: ov7670
    port map(
        xclk => xclk,
        nrst => nrst,
        
        pclk => pclk,
        hs => hs,
        vs => vs,
        
        do => do
    );
    
    ioc: ovcapture
    port map(
        clk => clk,
        nrst => nrst,
        
        pclk => pclk,
        hs => hs,
        vs => vs,
        di => do,
        
        fifodo => fifodo1,
        fifowr => fifowr1,
        fifofull => '0'
    );
    
    ipk: imgprekernel
    port map(
        clk => clk,
        nrst => nrst,
        
        newframe => vs,
        pixi => fifodo1(15 downto 0),
        pixirdy => fifowr1,
        
        pixo => pixo,
        pixordy => pixordy,
        done => done
    );
    
    irc: imgrcedge
    port map(
        clk => clk,
        nrst => nrst,
        newframe => vs,
        
        pix => pixo,
        pixrdy => pixordy,
        
        fifofull => '0',
        fifodo => fifodo2,
        fifowr => fifowr2
    );
end rtl;