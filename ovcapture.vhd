library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity ovcapture is
port(
    clk, nrst:  in std_logic;
    
    pclk:       in std_logic;
    hs, vs:     in std_logic;
    di:         in std_logic_vector(7 downto 0);
    
    fifodo:     out std_logic_vector(34 downto 0);
    fifowr:     out std_logic;
    fifofull:   in std_logic
);
end entity;

architecture rtl of ovcapture is
    signal pss, hss, vss: std_logic_vector(2 downto 0);
    signal ds1, ds2: std_logic_vector(7 downto 0);
    signal pixh, pixl: std_logic_vector(7 downto 0);
    
    signal latpixh, latpixl: std_logic;
    signal addr: unsigned(18 downto 0);
    signal xc: unsigned(10 downto 0);
    
    signal ctrladdr, ctrlxc: std_logic_vector(1 downto 0);
begin
    process(clk, nrst)
    begin
        if(nrst = '0') then
            addr <= (others => '0');
            xc <= (others => '0');
            
            pss <= (others => '0');
            hss <= (others => '0');
            vss <= (others => '0');
            
            ds1 <= (others => '0');
            ds2 <= (others => '0');
            pixh <= (others => '0');
            pixl <= (others => '0');
        elsif(rising_edge(clk)) then
            pss <= pss(1 downto 0) & pclk;
            hss <= hss(1 downto 0) & hs;
            vss <= vss(1 downto 0) & vs;
            
            ds1 <= di;
            ds2 <= ds1;
            
            case ctrladdr is
            when "00" => addr <= (others => '0');
            when "01" => addr <= addr + 1;
            when others => null;
            end case;
            
            case ctrlxc is
            when "00" => xc <= (others => '0');
            when "01" => xc <= xc + 1;
            when others => null;
            end case;
            
            if(latpixh = '1') then
                pixh <= ds2;
            elsif(latpixl = '1') then
                pixl <= ds2;
            end if;
        end if;
    end process;
    
    process(pss, hss, vss, addr, xc)
    begin
        ctrladdr <= "10";
        ctrlxc <= "10";
        latpixh <= '0';
        latpixl <= '0';
        
        fifowr <= '0';
        fifodo <= (others => '0');
        
        if(vss(2) = '1') then
            ctrladdr <= "00";
        else
            if(hss(2) = '0') then
                ctrlxc <= "00";
            elsif(pss(2 downto 1) = "01") then
                ctrlxc <= "01";
                
                if(xc(0) = '0') then
                    latpixh <= '1';
                else
                    latpixl <= '1';
                    --fifodo <= std_logic_vector(addr) & "000000" & std_logic_vector(xc(10 downto 1));
                    fifodo <= std_logic_vector(addr) & pixh&ds2;
                    fifowr <= not fifofull;
                    ctrladdr <= "01";
                end if;
                
            elsif(pss(2 downto 1) = "10") then
                if(xc(0) = '0') then
                    
                end if;
            end if;
        end if;
    end process;

end rtl;