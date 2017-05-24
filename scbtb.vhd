library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity scbtb is
end entity;

architecture rtl of scbtb is
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
    
    signal clk, nrst: std_logic;
    constant CLK_PERIOD: time := 10 ns;
    
    signal en, wr, busy: std_logic;
    signal scl, sda: std_logic;
  
begin
    scl <= 'H';
    sda <= 'H';

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
    
    sp: process
    begin
        en <= '0';
        wr <= '0';
        wait until nrst = '1';
        
        wait for 100 us;
        
        en <= '1';
        wr <= '1';
        wait until busy = '1';
        en <= '0';
        wr <= '0';
        wait until busy = '0';
        
        wait for 100 us;
        
        en <= '1';
        wr <= '0';
        wait until busy = '1';
        en <= '0';
        wr <= '0';
        wait until busy = '0';
        
        wait;
    end process;
    
    iscb: sccb
    generic map(
        CLK_FREQ => 50000000,
        I2C_FREQ => 100000
    )
    port map(
        clk => clk,
        nrst => nrst,
        
        scl => scl,
        sda => sda,
        
        devaddr => x"42",
        regaddr => x"81",
        regdatai => x"81",
        en => en,
        wr => wr,
        busy => busy
    );
end rtl;