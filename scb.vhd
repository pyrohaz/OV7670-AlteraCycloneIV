library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity scb is
    port(
        clk, nrst:  in std_logic;
        scl:        inout std_logic;
        sda:        inout std_logic;
        
        mode:       in std_logic_vector(2 downto 0);
        en:         in std_logic;
        di:         in std_logic_vector(7 downto 0);
        do:         out std_logic_vector(7 downto 0);
        bsy:        out std_logic
    );
end entity;

architecture rtl of scb is
    type states is (IDLE, START, STOP, NOACK, WRITEBYTE, READBYTE);
    type ssstates is (SDAH, SCLH, SDAL, SCLL, DLY, FIN);
    type wrstates is (DATA, CLKH, CLKL, SDAH, SCLH, ACK, FIN, DLY);
    
    constant DELAYL: unsigned(11 downto 0) := x"300";
    constant DELAYS: unsigned(11 downto 0) := '0'&DELAYL(10 downto 0);
    constant DELAYSL: unsigned(11 downto 0) := x"480";
    
    signal st: states;
    
    signal sst, snst: ssstates;
    signal wst, wnst: wrstates;
    
    signal dcnt: unsigned(11 downto 0);
    signal bcnt: unsigned(3 downto 0);
    signal txd, rxd: std_logic_vector(7 downto 0);
    signal ackv: std_logic;
begin
    process(nrst, clk)
    begin
        if(nrst = '0') then
            bsy <= '1';
            do <= (others => '0');
            scl <= 'Z';
            sda <= 'Z';
        elsif(rising_edge(clk)) then
            case st is
            when IDLE =>
                if(en = '1') then
                    bsy <= '1';
                    if(mode = "000") then       --Start
                        st <= START;
                        sst <= SDAH;
                    elsif(mode = "001") then    --Stop
                        st <= STOP;
                        sst <= SDAL;
                    elsif(mode = "010") then    --No Ack
                        st <= NOACK;
                        sst <= SDAH;
                    elsif(mode = "100") then    --TX Byte
                        st <= WRITEBYTE;
                        wst <= DATA;
                        txd <= di;
                        bcnt <= (others => '0');
                    elsif(mode = "101") then    --RX Byte
                        st <= READBYTE;
                        rxd <= (others => '0');
                        bcnt <= (others => '0');
                    end if;
                else
                    bsy <= '0';
                end if;
                
            when START =>
                case sst is
                when SDAH =>
                    sda <= 'Z';
                    dcnt <= DELAYL;
                    sst <= DLY;
                    snst <= SCLH;
                    
                when SCLH =>
                    scl <= 'Z';
                    dcnt <= DELAYL;
                    sst <= DLY;
                    snst <= SDAL;
                   
                when SDAL =>
                    sda <= '0';
                    dcnt <= DELAYL;
                    sst <= DLY;
                    snst <= SCLL;
                    
                when SCLL =>
                    scl <= '0';
                    dcnt <= DELAYL;
                    sst <= DLY;
                    snst <= FIN;
                    
                when FIN =>
                    st <= IDLE;
                    
                when DLY =>
                    if(dcnt = 0) then
                        sst <= snst;
                    else
                        dcnt <= dcnt - 1;
                    end if;
                end case;
            
            when STOP =>
                case sst is
                when SDAL =>
                    sda <= '0';
                    dcnt <= DELAYL;
                    sst <= DLY;
                    snst <= SCLH;
                    
                when SCLH =>
                    scl <= 'Z';
                    dcnt <= DELAYL;
                    sst <= DLY;
                    snst <= SDAH;
                   
                when SDAH =>
                    sda <= 'Z';
                    dcnt <= DELAYL;
                    sst <= DLY;
                    snst <= FIN;
                
                when FIN =>
                    st <= IDLE;
                    
                when DLY =>
                    if(dcnt = 0) then
                        sst <= snst;
                    else
                        dcnt <= dcnt - 1;
                    end if;
                    
                when others => null;
                end case;
                
            when NOACK =>
                case sst is
                when SDAH =>
                    sda <= 'Z';
                    dcnt <= DELAYL;
                    sst <= DLY;
                    snst <= SCLH;
                    
                when SCLH =>
                    scl <= 'Z';
                    dcnt <= DELAYL;
                    sst <= DLY;
                    snst <= SCLL;
                   
                when SCLL =>
                    scl <= '0';
                    dcnt <= DELAYL;
                    sst <= DLY;
                    snst <= SDAL;
                   
                when SDAL =>
                    sda <= '0';
                    dcnt <= DELAYL;
                    sst <= DLY;
                    snst <= FIN;
                    
                when FIN =>
                    st <= IDLE;
                    
                when DLY =>
                    if(dcnt = 0) then
                        sst <= snst;
                    else
                        dcnt <= dcnt - 1;
                    end if;
                end case;
            
            when WRITEBYTE =>
                case wst is
                when DATA =>
                    sda <= txd(7);
                    dcnt <= DELAYL;
                    wst <= DLY;
                    wnst <= CLKH;
                    
                when CLKH =>
                    scl <= 'Z';
                    dcnt <= DELAYL;
                    wst <= DLY;
                    wnst <= CLKL;
                    
                when CLKL =>
                    scl <= '0';
                    wst <= DLY;
                    if(bcnt = 7) then
                        wnst <= SDAH;
                        dcnt <= DELAYSL;
                    else
                        bcnt <= bcnt + 1;
                        txd <= txd(6 downto 0)&'0';
                        dcnt <= DELAYL;
                        wnst <= DATA;
                    end if;
                    
                when SDAH =>
                    sda <= 'Z'; 
                    dcnt <= DELAYL;
                    wst <= DLY;
                    wnst <= SCLH;
                    
                when SCLH =>
                    scl <= 'Z';
                    dcnt <= DELAYS;
                    wst <= DLY;
                    wnst <= ACK;
                    
                when ACK =>
                    if(sda /= '0') then ackv <= '0';
                    else ackv <= '1'; end if;
                    scl <= '0';
                    dcnt <= DELAYL;
                    wst <= DLY;
                    wnst <= FIN;
                    
                when FIN =>
                    do <= "0000000" & ackv;
                    st <= IDLE;
                    
                when DLY =>
                    if(dcnt = 0) then
                        wst <= wnst;
                    else
                        dcnt <= dcnt - 1;
                    end if;
                end case;
            when READBYTE => null;
            end case;
        end if;
    end process;
end rtl;