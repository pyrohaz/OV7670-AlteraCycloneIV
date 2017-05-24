library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity tb is
end entity;

architecture rtl of tb is
    component top is
    port(
        clk, nrst:  in std_logic;
        
        s_cke, s_clk: out std_logic;
        s_cs, s_we, s_cas, s_ras: out std_logic;
        s_addr: out std_logic_vector(12 downto 0);
        s_ba: out std_logic_vector(1 downto 0);
        s_d: inout std_logic_vector(15 downto 0);
        s_dq: out std_logic_vector(1 downto 0);
        
        utx:    out std_logic;
        urx:    in std_logic
    );
    end component;
    
    component sdram is
    port(
        s_cke, s_clk: in std_logic;
        s_cs, s_we, s_cas, s_ras: in std_logic;
        s_addr: in std_logic_vector(12 downto 0);
        s_ba: in std_logic_vector(1 downto 0);
        s_d: inout std_logic_vector(15 downto 0);
        s_dq: in std_logic_vector(1 downto 0)
    );
    end component;

    signal clk, nrst: std_logic;
    constant CLK_PERIOD: time := 10 ns;
    
    signal urx: std_logic;
    
    signal s_cs, s_we, s_cas, s_ras, s_cke, s_clk: std_logic;
    signal s_addr: std_logic_vector(12 downto 0);
    signal s_ba: std_logic_vector(1 downto 0);
    signal s_d: std_logic_vector(15 downto 0);
    signal s_dq: std_logic_vector(1 downto 0);
begin
    clkp: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    rstp: process
    begin
        nrst <= '0';
        wait for CLK_PERIOD*2;
        nrst <= '1';
        wait;
    end process;
    
    up: process
    begin
        urx <= '1';
        wait for 300 us;
        urx <= '0';
        wait for 8.7 us;
        urx <= '1';
        
        wait;
    end process;
    
    itop: top 
    port map(
        clk => clk,
        nrst => nrst,
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
        
        utx => open,
        urx => urx
    );
    
    isdr: sdram
    port map(
        s_cke => s_cke,
        s_clk => s_clk,
        s_cs => s_cs,
        s_we => s_we,
        s_cas => s_cas,
        s_ras => s_ras,
        
        s_addr => s_addr,
        s_ba => s_ba,
        s_d => s_d,
        s_dq => s_dq
    );
end rtl;