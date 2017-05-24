library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity fifohandler is
port(
    clk, nrst:  in std_logic;
    
    --Pixel FIFO
    fifodi:     in std_logic_vector(34 downto 0);
    fiford:     out std_logic;
    fifoused:   in std_logic_vector(9 downto 0);
    fifoempty:  in std_logic;
    
    --UART IF
    uaddr:      in std_logic_vector(23 downto 0);
    udo:        out std_logic_vector(15 downto 0);
    uen:        in std_logic;
    ubsy:       out std_logic;
    
    --Memory IF
    addr:       out std_logic_vector(23 downto 0);
    di:         in std_logic_vector(15 downto 0);
    do:         out std_logic_vector(15 downto 0);
    wr, en:     out std_logic;
    bsy:        in std_logic
);
end entity;

architecture rtl of fifohandler is
    type states is (IDLE, WRPIXFIFO1, WRPIXFIFO2, RDUMEM1, RDUMEM2);
    signal st, nst: states;
    
    signal latudo: std_logic;
begin
    process(clk, nrst)
    begin
        if(nrst = '0') then
            st <= IDLE;
            udo <= (others => '0');
        elsif(rising_edge(clk)) then
            st <= nst;
            
            if(latudo = '1') then
                udo <= di;
            end if;
        end if;
    end process;

    process(st, fifodi, fifoused, fifoempty, uaddr, uen, di, bsy)
    begin
        fiford <= '0';
        latudo <= '0';
        ubsy <= '0';
        
        addr <= (others => '0');
        do <= (others => '0');
        wr <= '0';
        en <= '0';
        
        case st is
        when IDLE =>
            nst <= IDLE;
            --if(fifoused(11) = '1' and bsy = '0') then
            if(fifoempty = '0' and bsy = '0') then
                fiford <= '1';
                nst <= WRPIXFIFO1;
            elsif(uen = '1') then
                nst <= RDUMEM1;
            end if;
            
        when WRPIXFIFO1 =>
            nst <= WRPIXFIFO1;
            en <= '1';
            wr <= '1';
            addr <= "00000"&fifodi(34 downto 16);
            do <= fifodi(15 downto 0);
            
            if(bsy = '1') then
                nst <= WRPIXFIFO2;
            end if;
            
        when WRPIXFIFO2 =>
            nst <= WRPIXFIFO2;
            
            if(bsy = '0') then
                nst <= IDLE;
            end if;
            
        when RDUMEM1 =>
            nst <= RDUMEM1;
            
            addr <= uaddr;
            en <= '1';
            
            if(bsy = '1') then
                nst <= RDUMEM2;
            end if;
            
        when RDUMEM2 =>
            nst <= RDUMEM2;
            ubsy <= '1';
            
            if(bsy = '0') then
                nst <= IDLE;
                latudo <= '1';
            end if;
        
        end case;
    end process;
end rtl;