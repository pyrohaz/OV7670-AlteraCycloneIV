library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity sccb is
generic(
    CLK_FREQ: integer;
    I2C_FREQ: integer
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
end entity;

architecture rtl of sccb is
    constant BIT_PERIOD:    integer := CLK_FREQ/I2C_FREQ;
    constant CNTR_LEN:      integer := integer(ceil(log2(real(BIT_PERIOD))));
    
    type states is (
        IDLE, 
        START1, WRADDR1, WRB1, WRB2, 
        START2, WRADDR2, RDB1, 
        STOP1A, STOP1B,
        STOP2A, STOP2B);
    signal st, nst: states;
    
    signal cntbp: unsigned(CNTR_LEN-1 downto 0);
    signal ctrlcntbp: std_logic_vector(1 downto 0);
    
    signal cntbt: unsigned(3 downto 0); 
    signal ctrlcntbt: std_logic_vector(1 downto 0);
    
    signal idaw, idar, ira, irdi, irdo: std_logic_vector(8 downto 0);
    signal iwr: std_logic;
    signal latdi: std_logic;
    
    signal shiftd: std_logic;
    
    signal sdas: std_logic_vector(1 downto 0);
    
    signal iscl, isda: std_logic;
begin
    scl <= '0' when iscl = '0' else 'Z';
    sda <= '0' when isda = '0' else 'Z';
    
    regdatao <= irdo(8 downto 1);

    process(nrst, clk)
    begin
        if(nrst = '0') then
            idaw <= (others => '0');
            idar <= (others => '0');
            ira <= (others => '0');
            irdi <= (others => '0');
            irdo <= (others => '0');
            iwr <= '0';
            
            sdas <= (others => '0');
            cntbp <= (others => '0');
            cntbt <= (others => '0');
            
            st <= IDLE;
        elsif(rising_edge(clk)) then
            st <= nst;
            
            sdas <= sdas(0) & sda;
            
            if(latdi = '1') then
                idaw <= devaddr&'0';
                idar <= devaddr(7 downto 1)&'1'&'0';
                ira <= regaddr&'0';
                irdi <= regdatai&'0';
                iwr <= wr;
            end if;
            
            if(shiftd = '1') then
                if(sdas(1) = '0') then
                    irdo <= irdo(7 downto 0) & '0';
                else
                    irdo <= irdo(7 downto 0) & '1';
                end if;
            end if;
            
            case ctrlcntbp is
            when "00" => cntbp <= (others => '0');
            when "01" => cntbp <= cntbp + 1;
            when others => null;
            end case;
            
            case ctrlcntbt is
            when "00" => cntbt <= "1000";
            when "01" => cntbt <= cntbt - 1;
            when others => null;
            end case;
        end if;
    end process;
    
    process(st, sdas, idaw, idar, ira, irdi, cntbp, cntbt, en, wr)
    begin
        busy <= '1';
        latdi <= '0';
        isda <= 'Z';
        iscl <= 'Z';
        ctrlcntbp <= "10";
        ctrlcntbt <= "10";
        shiftd <= '0';
        
        case st is
        when IDLE =>
            nst <= IDLE;
            busy <= '0';
            ctrlcntbp <= "00";
            ctrlcntbt <= "00";
            if(en = '1') then
                nst <= START1;
                latdi <= '1';
            end if;
            
        when START1 =>
            nst <= START1;
            isda <= '0';
            ctrlcntbp <= "01";
            if(cntbp > BIT_PERIOD/2) then
                iscl <= '0';
            end if;
            if(cntbp = BIT_PERIOD) then
                nst <= WRADDR1;
                ctrlcntbp <= "00";
            end if;
            
        when WRADDR1 =>
            nst <= WRADDR1;
            ctrlcntbp <= "01";
            isda <= idaw(to_integer(cntbt));
            
            if(cntbp < BIT_PERIOD/2) then
                iscl <= '0';
            end if;
            
            if(cntbp = BIT_PERIOD) then
                ctrlcntbp <= "00";
                ctrlcntbt <= "01";
                if(cntbt = 0) then
                    ctrlcntbt <= "00";
                    nst <= WRB1;
                end if;
            end if;
            
        when WRB1 =>
            nst <= WRB1;
            ctrlcntbp <= "01";
            isda <= ira(to_integer(cntbt));
            
            if(cntbp < BIT_PERIOD/2) then
                iscl <= '0';
            end if;
            
            if(cntbp = BIT_PERIOD) then
                ctrlcntbp <= "00";
                ctrlcntbt <= "01";
                if(cntbt = 0) then
                    ctrlcntbt <= "00";
                    if(iwr = '1') then
                        nst <= WRB2;
                    else
                        nst <= STOP1A;
                    end if;
                end if;
            end if;
            
        when WRB2 =>
            nst <= WRB2;
            ctrlcntbp <= "01";
            isda <= irdi(to_integer(cntbt));
            
            if(cntbp < BIT_PERIOD/2) then
                iscl <= '0';
            end if;
            
            if(cntbp = BIT_PERIOD) then
                ctrlcntbp <= "00";
                ctrlcntbt <= "01";
                if(cntbt = 0) then
                    ctrlcntbt <= "00";
                    nst <= STOP1A;
                end if;
            end if;
            
        when STOP1A =>
            nst <= STOP1A;
            isda <= '0';
            if(cntbp<BIT_PERIOD/2) then
                iscl <= '0';
            end if;
            ctrlcntbp <= "01";
            
            if(cntbp = BIT_PERIOD) then
                ctrlcntbp <= "00";
                nst <= STOP1B;
            end if;
            
        when STOP1B =>
            nst <= STOP1B;
            ctrlcntbp <= "01";
            
            if(cntbp = BIT_PERIOD) then
                ctrlcntbp <= "00";
                if(iwr = '0') then
                    nst <= START2;
                else
                    nst <= IDLE;
                end if;
            end if;
            
        --Reads
        when START2 =>
            nst <= START2;
            isda <= '0';
            ctrlcntbp <= "01";
            if(cntbp > BIT_PERIOD/2) then
                iscl <= '0';
            end if;
            if(cntbp = BIT_PERIOD) then
                nst <= WRADDR2;
                ctrlcntbp <= "00";
            end if;
            
        when WRADDR2 =>
            nst <= WRADDR2;
            ctrlcntbp <= "01";
            isda <= idar(to_integer(cntbt));
            
            if(cntbp < BIT_PERIOD/2) then
                iscl <= '0';
            end if;
            
            if(cntbp = BIT_PERIOD) then
                ctrlcntbp <= "00";
                ctrlcntbt <= "01";
                if(cntbt = 0) then
                    ctrlcntbt <= "00";
                    nst <= RDB1;
                end if;
            end if;
            
        when RDB1 =>
            nst <= RDB1;
            ctrlcntbp <= "01";
            
            if(cntbp < BIT_PERIOD/2) then
                iscl <= '0';
            end if;
            
            if(cntbp = BIT_PERIOD/2) then
                shiftd <= '1';
            end if;
            
            if(cntbp = BIT_PERIOD) then
                ctrlcntbp <= "00";
                ctrlcntbt <= "01";
                if(cntbt = 0) then
                    ctrlcntbt <= "00";
                    nst <= STOP2A;
                end if;
            end if;    
        
        when STOP2A =>
            nst <= STOP2A;
            isda <= '0';
            if(cntbp<BIT_PERIOD/2) then
                iscl <= '0';
            end if;
            ctrlcntbp <= "01";
            
            if(cntbp = BIT_PERIOD) then
                ctrlcntbp <= "00";
                nst <= STOP2B;
            end if;
            
        when STOP2B =>
            nst <= STOP2B;
            ctrlcntbp <= "01";
            
            if(cntbp = BIT_PERIOD) then
                ctrlcntbp <= "00";
                nst <= IDLE;
            end if;
        end case;
    end process;
end rtl;
