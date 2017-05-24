library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity uart2 is
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
end entity;

architecture rtl of uart2 is
    constant N_BITS:        integer := 10;  --Start - 8D - Stop
    constant BIT_PERIOD:    integer := CLK_FREQ/BAUD_RATE;
    constant CNTR_LEN:      integer := integer(ceil(log2(real(BIT_PERIOD))));
    
    type states is (IDLE, BITS);
    
    signal rxst, nrxst, txst, ntxst: states;
    signal rxsync: std_logic_vector(2 downto 0);
    signal cntrx, cnttx: unsigned(CNTR_LEN-1 downto 0);
    signal cntrxbit, cnttxbit: unsigned(3 downto 0);

    signal ctrlcntrx, ctrlcnttx: std_logic;
    signal rxregsamp: std_logic_vector(2 downto 0);
    
    signal rxdata: std_logic_vector(N_BITS-2 downto 0);
    signal txdata: std_logic_vector(N_BITS-1 downto 0);
    signal rxcurrbit: std_logic;
    
    signal lattxd: std_logic;
begin
    --RX side
    rxcurrbit <= '1' when rxregsamp = "011" or rxregsamp = "101" or rxregsamp = "110" or rxregsamp = "111" else '0';
    
    --process(rxregsamp)
    --    variable h: integer;
    --begin
    --    h := 0;
    --    for i in 0 to 7 loop
    --        if(rxregsamp(i) = '1') then
    --            h := h + 1;
    --        end if;
    --    end loop;
    --    
    --    if(h>=4) then
    --        rxcurrbit <= '1';
    --    else
    --        rxcurrbit <= '0';
    --    end if;
    --end process;
    
    process(nrst, clk)
    begin
        if(nrst = '0') then
            rxsync <= (others => '0');
            cntrx <= (others => '0');
            cntrxbit <= (others => '0');
            rxregsamp <= (others => '0');
            rxdata <= (others => '0');
            rxst <= IDLE;
        elsif(rising_edge(clk)) then
            rxsync <= rxsync(1 downto 0) & rx;
            rxst <= nrxst;
            
            if(ctrlcntrx = '0') then
                cntrx <= (others => '0');
                cntrxbit <= (others => '0');
            else
                cntrx <= cntrx + 1;
            end if;
            
            if(cntrx = BIT_PERIOD-1) then
                cntrx <= (others => '0');
                cntrxbit <= cntrxbit + 1;
                
                rxdata <= rxcurrbit & rxdata(8 downto 1);
            end if;
            
            if(cntrx = BIT_PERIOD/4 or cntrx = BIT_PERIOD/2 or cntrx = (BIT_PERIOD*3)/4) then
            --if(cntrx = BIT_PERIOD/8 or
            --    cntrx = BIT_PERIOD*2/8 or
            --    cntrx = BIT_PERIOD*3/8 or
            --    cntrx = BIT_PERIOD*4/8 or
            --    cntrx = BIT_PERIOD*5/8 or
            --    cntrx = BIT_PERIOD*6/8 or
            --    cntrx = BIT_PERIOD*7/8) then
                rxregsamp <= rxregsamp(1 downto 0) & rxsync(2);
            end if;
        end if;
    end process;
    
    rxd <= rxdata(8 downto 1);  --Bit(0) is the start bit, Bit(10) would be the stop bit but early finish stops it being captured
    rxb <= '0' when rxst = IDLE else '1';
    process(rxst, rxsync, cntrxbit, cntrx, rxcurrbit, rxdata)
    begin
        ctrlcntrx <= '0';
        rxr <= '0';
        
        case rxst is
        when IDLE =>
            nrxst <= IDLE;
            if(rxsync(2 downto 1) = "10") then
            --if(rxsync(2 downto 1) = "00") then
                nrxst <= BITS;
            end if;
        
        when BITS =>
            nrxst <= BITS;
            ctrlcntrx <= '1';
            
            --Stop after 3rd bit sample
            if(cntrxbit >= 9 and cntrx = (BIT_PERIOD*3)/4) then
                nrxst <= IDLE;
                
                --Only output if start and stop bits existed
                if(rxcurrbit = '1' and rxdata(0) = '0') then
                    rxr <= '1';
                end if;
                --rxr <= '1';
            end if;
        end case;
    end process;
    
    --TX side
    process(nrst, clk)
    begin
        if(nrst = '0') then
            cnttx <= (others => '0');
            cnttxbit <= (others => '0');
            txdata <= (others => '0');
            txst <= IDLE;
        elsif(rising_edge(clk)) then
            txst <= ntxst;
        
            if(ctrlcnttx = '0') then
                cnttx <= (others => '0');
                cnttxbit <= (others => '0');
            else
                cnttx <= cnttx + 1;
            end if;
            
            if(cnttx = BIT_PERIOD-1) then
                cnttx <= (others => '0');
                cnttxbit <= cnttxbit + 1;
            end if;
            
            if(lattxd = '1') then
                --        STOP  DATA  START
                txdata <= '1' & txd & '0';
            end if;
        end if;
    end process;
    
    txb <= '0' when txst = IDLE else '1';
    process(txst, txs, cnttxbit, txdata)
    begin
        tx <= '1';
        ctrlcnttx <= '0';
        lattxd <= '0';
        
        case txst is
        when IDLE =>
            ntxst <= IDLE;
            if(txs = '1') then
                ntxst <= BITS;
                lattxd <= '1';
            end if;
            
        when BITS =>
            ntxst <= BITS;
            ctrlcnttx <= '1';
            
            if(cnttxbit >= 10) then
                ntxst <= IDLE;
            else
                tx <= txdata(to_integer(cnttxbit));
            end if;
        end case;
            
    end process;
end rtl;