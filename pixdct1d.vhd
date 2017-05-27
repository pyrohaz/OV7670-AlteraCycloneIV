library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity pixdct1d is
port(
    clk, nrst:      in std_logic;
    
    newframe:       in std_logic;
    pix:            in std_logic_vector(4 downto 0);
    newpix:         in std_logic;
    
    dct1, dct2:     out std_logic_vector(7 downto 0);
    
    dctrdy:         out std_logic;
    
    done:           out std_logic;
);
end entity;

architecture rtl of pixdct1d is
    constant XSIZ: integer := 640;
    constant BLOCKSIZ: integer := 8;

    type inputsrtype is array (0 to XSIZ-1) of std_logic_vector(4 downto 0);
    type blocktype is array (0 to BLOCKSIZ*BLOCKSIZ-1) of std_logic_vector(4 downto 0);
    
    type array8x5 is array (0 to 7) of std_logic_vector(4 downto 0);
    signal pblock: array8x5;
    signal lb: inputsrtype;
    signal newpixo, newframeo: std_logic;
    
    signal bcnt, bcnts1: unsigned(18 downto 0);
    signal drdy: std_logic;
    
    type array8x8 is array (0 to 7) of signed(7 downto 0);
    type array8x16 is array (0 to 7) of signed(15 downto 0);
    
    signal mulip1, mulip2: array8x8;
    signal mulop: array8x16;
    signal mulsum: signed(15 downto 0);
    
    signal dc: unsigned(16 downto 0);
    
    type states is (IDLE, OP1, OP2, OUTPUT);
    signal st, nst: states;
    signal lat: std_logic_vector(1 downto 0);
    
    constant coeffs1: array8x8 := (
        to_signed(91, 8), to_signed(91, 8), to_signed(91, 8), to_signed(91, 8), to_signed(91, 8), to_signed(91, 8), to_signed(91, 8), to_signed(91, 8));
    constant coeffs2: array8x8 := (
        to_signed(126, 8), to_signed(106, 8), to_signed(71, 8), to_signed(25, 8), to_signed(-25, 8), to_signed(-71, 8), to_signed(-106, 8), to_signed(-126, 8));
begin
    bcnts1 <= bcnt-1;
    --Block generator
    process(clk, nrst)
    begin
        if(nrst = '0') then
            lb <= (others => (others => '0'));
            newpixo <= '0';
            newframeo <= '0';
            bcnt <= (others => '0');
            pblock <= (others => (others => '0'));
            drdy <= '0';
        elsif(rising_edge(clk)) then
            newpixo <= newpix;
            newframeo <= newframe;
            drdy <= '0';
            
            if(newframeo = '0' and newframe = '1') then
                bcnt <= (others => '0');
            end if;
                
            if((newpixo = '0' and newpix = '1')) then
                lb(XSIZ-1) <= pix;
                lb(0 to XSIZ-2) <= lb(1 to XSIZ-1);
                
                if(bcnt(2 downto 0) = 7) then
                    for x in 0 to BLOCKSIZ-1 loop
                        pblock(x) <= lb((XSIZ-1)-(BLOCKSIZ-1-x));
                    end loop;
                    
                    drdy <= '1';
                    --bcnt <= (others => '0');
                end if;
                
                bcnt <= bcnt + 1;
            end if;
        end if;
    end process;
    
    done <= '1' when bcnt >= 8+640*480 and st = idle else '0';

    --DCT Section
    mulp: process(mulip1, mulip2)
    begin
        for i in 0 to 7 loop
            mulop(i) <= mulip1(i)*mulip2(i);
        end loop;
    end process;
    
    mulsum <= mulop(0) + mulop(1) + mulop(2) + mulop(3) + mulop(4) + mulop(5) + mulop(6) + mulop(7);
    
    --Wait for data ready then do stuff
    process(clk, nrst)
    begin
        if(nrst = '0') then
            st <= IDLE;
            dct1 <= (others => '0');
            dct2 <= (others => '0');
        elsif(rising_edge(clk)) then
            st <= nst;
            
           case lat is
           when "01" => dct1 <= std_logic_vector(mulsum(15 downto 8));
           when "10" => dct2 <= std_logic_vector(mulsum(15 downto 8));
           when others => null;
           end case;
        end if;
    end process;
    
    process(st, drdy)
    begin
        mulip1 <= (others => (others => '0'));
        mulip2 <= (others => (others => '0'));
        lat <= "00";
        dctrdy <= '0';
        
        case st is
        when IDLE =>
            nst <= IDLE;
            
            if(drdy = '1') then
                nst <= OP1;
            end if;
            
        when OP1 =>
            nst <= OP2;
            for i in 0 to 7 loop
                mulip1(i) <= resize(coeffs1(i), mulip1(0)'length);
                mulip2(i) <= resize("0"&signed(pblock(i)), mulip1(0)'length);
            end loop;
            
            lat <= "01";
            
        when OP2 =>
            nst <= OUTPUT;
            for i in 0 to 7 loop
                mulip1(i) <= resize(coeffs2(i), mulip1(0)'length);
                mulip2(i) <= resize("0"&signed(pblock(i)), mulip1(0)'length);
            end loop;
            
            lat <= "10";
            
        when OUTPUT =>
            nst <= IDLE;
            dctrdy <= '1';
            
        end case;
    end process;
end rtl;
