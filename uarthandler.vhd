library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity uarthandler is
port(
    clk, nrst:  in std_logic;
    --UART IF
    uaddr:      out std_logic_vector(23 downto 0);
    udi:        in std_logic_vector(15 downto 0);
    uen:        out std_logic;
    ubsy:       in std_logic;
    
    urx:        in std_logic;
    utx:        out std_logic
);
end entity;

architecture rtl of uarthandler is
    component uart2 is
    generic(
        CLK_FREQ:   integer := 50000000;
        BAUD_RATE:  integer := 115200
    );
    port(
        clk, nrst:  in std_logic;
        
        tx:         out std_logic;
        rx:         in std_logic;
        
        txd:        in std_logic_vector(7 downto 0);
        rxd:        out std_logic_vector(7 downto 0);
        
        txs:        in std_logic;
        txb:        out std_logic;
        
        rxr:        out std_logic;
        rxb:        out std_logic
    );
    end component;
    
    constant PIX_SKIP: integer := 1;

    type states is (IDLE, RDMEM1, RDMEM2, WRVAL1A, WRVAL1B, WRVAL2A, WRVAL2B);
    signal st, nst: states;
    
    signal urxr, utxb, utxs: std_logic;
    signal utxd: std_logic_vector(7 downto 0);
    
    signal xc, yc: unsigned(15 downto 0);
    
    signal ctrlxc, ctrlyc: std_logic_vector(1 downto 0);
    
    signal di: std_logic_vector(15 downto 0);
    signal latdi: std_logic;
begin
    iu: uart2
    generic map(
        CLK_FREQ => 96000000,
        BAUD_RATE => 6000000
    )
    port map(
        clk => clk,
        nrst => nrst,
        
        tx => utx,
        rx => urx,
        
        txd => utxd,
        
        txs => utxs,
        txb => utxb,
        
        rxr => urxr
    );

    process(clk, nrst)
    begin
        if(nrst = '0') then
            st <= IDLE;
            di <= (others => '0');
            xc <= (others => '0');
            yc <= (others => '0');
        elsif(rising_edge(clk)) then
            st <= nst;
            
            case ctrlxc is
            when "00" => xc <= (others => '0');
            when "01" => xc <= xc + PIX_SKIP;
            when others => null;
            end case;
            
            case ctrlyc is
            when "00" => yc <= (others => '0');
            when "01" => yc <= yc + PIX_SKIP;
            when others => null;
            end case;
            
            if(latdi = '1') then
                di <= udi;
            end if;
        end if;
    end process;

    process(st, ubsy, utxb, urxr, xc, yc, di)
    begin
        utxs <= '0';
        utxd <= (others => '0');
        uen <= '0';
        uaddr <= (others => '0');
        latdi <= '0';
        
        ctrlxc <= "10";
        ctrlyc <= "10";
        
        case st is
        when IDLE =>
            nst <= IDLE;
            ctrlxc <= (others => '0');
            ctrlyc <= (others => '0');
            
            if(urxr = '1') then
                nst <= RDMEM1;
            end if;
            
        when RDMEM1 =>
            nst <= RDMEM1;
            uen <= '1';
            uaddr <= std_logic_vector(resize(xc + yc*640, 24));
            
            if(ubsy = '1') then
                nst <= RDMEM2;
            end if;
            
        when RDMEM2 =>
            nst <= RDMEM2;
            
            if(ubsy = '0') then
                latdi <= '1';
                nst <= WRVAL1A;
            end if;
            
        when WRVAL1A =>
            nst <= WRVAL1A;
            utxd <= di(15 downto 8);
            utxs <= '1';
            
            if(utxb = '1') then
                nst <= WRVAL1B;
            end if;
            
        when WRVAL1B =>
            nst <= WRVAL1B;
            
            if(utxb = '0') then
                nst <= WRVAL2A;
            end if;
            
        when WRVAL2A =>
            nst <= WRVAL2A;
            utxd <= di(7 downto 0);
            --utxd <= di(15 downto 13) & di(10 downto 8) & di(4 downto 3);
            utxs <= '1';
            
            if(utxb = '1') then
                nst <= WRVAL2B;
            end if;
            
        when WRVAL2B =>
            nst <= WRVAL2B;
            
            if(utxb = '0') then
                if(xc = 640-PIX_SKIP and yc = 480-PIX_SKIP) then
                    nst <= IDLE;
                else
                    nst <= RDMEM1;
                    if(xc = 640-PIX_SKIP) then
                        ctrlxc <= "00";
                        ctrlyc <= "01";
                    else
                        ctrlxc <= "01";
                    end if;
                end if;
            end if;
        end case;
            
    end process;
end rtl;