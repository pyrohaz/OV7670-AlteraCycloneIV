library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity sdram is
port(
    s_cke, s_clk: in std_logic;
    s_cs, s_we, s_cas, s_ras: in std_logic;
    s_addr: in std_logic_vector(12 downto 0);
    s_ba: in std_logic_vector(1 downto 0);
    s_d: inout std_logic_vector(15 downto 0);
    s_dq: in std_logic_vector(1 downto 0)
);
end entity;

architecture rtl of sdram is
    type memarray is array (0 to 1023) of std_logic_vector(15 downto 0);
    signal mem: memarray;
    
    signal row: std_logic_vector(12 downto 0);
    signal col: std_logic_vector(8 downto 0);
    signal bank: std_logic_vector(1 downto 0);
    
    signal memindex: integer := 0;
    signal inz: std_logic := '1';
    signal dow: std_logic := '0';
    
    signal ocnt: unsigned(1 downto 0) := "00";
    
    signal ip: std_logic_vector(15 downto 0) := (others => '0');
    signal index: integer;
begin
    s_d <= mem(index) when inz = '0' and s_dq = "00" else (others => 'Z');
    index <= to_integer(unsigned(bank)&unsigned(row)&unsigned(col)) when to_integer(unsigned(bank)&unsigned(row)&unsigned(col))<1024 else 1023;
    
    process(s_clk)
    begin
        if(rising_edge(s_clk) and s_cke = '1') then
            inz <= '1';
            if(s_cs = '0' and s_ras = '0' and s_cas = '1' and s_we = '1') then
                --Activate
                bank <= s_ba;
                row <= s_addr;
            elsif(s_cs = '0' and s_ras = '1' and s_cas = '0' and s_we = '0') then
                --Write
                col <= s_addr(8 downto 0);
                dow <= '1';
                ip <= s_d;
            elsif(s_cs = '0' and s_ras = '1' and s_cas = '0' and s_we = '1') then
                --Read
                ocnt <= "01";
                col <= s_addr(8 downto 0);
            elsif(s_cs = '0' and s_ras = '0' and s_cas = '0' and s_we = '1') then
                bank <= (others => '0');
                row <= (others => '0');
                col <= (others => '0');
                dow <= '0';
                ocnt <= "00";
            end if;
            
            if(dow = '1') then
                dow <= '0';
                if(to_integer(unsigned(bank)&unsigned(row)&unsigned(col)) < 1024) then
                    mem(to_integer(unsigned(bank)&unsigned(row)&unsigned(col))) <= ip;
                end if;
            end if;
                
            
            if(ocnt = 1) then
                inz <= '0';
            end if;
            
            if(ocnt /= 0) then
                ocnt <= ocnt-1;
            end if;
        end if;
    end process;
end rtl;