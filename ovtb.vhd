library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

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
    
    constant CLK_PERIOD: time := 10 ns;
    constant XCLK_PERIOD: time := 83 ns;
    
    signal hs, vs, pclk, xclk: std_logic;
    signal do: std_logic_vector(7 downto 0);
    
    signal clk, nrst: std_logic;
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
        
        fifodo => open,
        fifowr => open,
        fifofull => '0'
    );
end rtl;