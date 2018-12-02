library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DATA_interface is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           en : in STD_LOGIC;
           add_bit : in STD_LOGIC;
           ADD : in STD_LOGIC_VECTOR (11 downto 0);
           RW_bit : in STD_LOGIC;
           data : in STD_LOGIC_VECTOR (7 downto 0);
           
           SPI : out STD_LOGIC;
           CS_NOT : out STD_LOGIC;
           
           ADDY_DONE: out STD_LOGIC;
           DATA_DONE: out STD_LOGIC);
end DATA_interface;

architecture Behavioral of DATA_interface is

type StateType is (IDLE, READ, WRITE, WRITE_LONG, WRITE_SHORT, READ_LONG, READ_SHORT, FINISH);
signal CurrentState : StateType := IDLE;
signal NextState : StateType;

signal add_done, dat_done, data_line, count_down_en : STD_LOGIC;
signal shrt_add_wr : STD_LOGIC_VECTOR(15 downto 0);
signal long_add_wr : STD_LOGIC_VECTOR(23 downto 0);
signal long_wr : integer := 23;
signal short_wr : integer := 15;

begin
ADDY_DONE <= add_done;
DATA_DONE <= dat_done;

shrt_add_wr <= add_bit & ADD(5 downto 0) & RW_bit & data;
long_add_wr <= add_bit & ADD(9 downto 0) & RW_bit & "0000" & data;

SPI <= data_line;

clock_process: process(clk, rst, count_down_en, en)
begin
    if (rst = '0')then
        CurrentState <= IDLE;
    else
        if (en = '0')then
            long_wr <= 23;
            short_wr <= 15;        
            CurrentState <= IDLE;
        elsif(clk'event and clk = '1')then
            CurrentState <= NextState;
            if(count_down_en = '1')then
                long_wr <= long_wr - 1;
                short_wr <= short_wr - 1;
            else
                long_wr <= 23;
                short_wr <= 15;
            end if;
        end if;
    end if;
end process;

nextstate_logic: process(CurrentState, add_bit, RW_bit, ADD, data, en, long_wr, short_wr)
begin
    case CurrentState is
        when IDLE =>
            dat_done <= '0';
            add_done <= '0';
            data_line <= '0';
            if (en = '1')then
                if(RW_bit = '1')then
                    NextState <= WRITE;
                else
                    NextSTATE <= READ;
                end if;
            else
                Nextstate <= IDLE;
            end if;
        when READ =>
            dat_done <= '0';
            add_done <= '0';
            data_line <= '0';
            if (add_bit = '1')then
                NextState <= READ_LONG;
            else
                NextState <= READ_SHORT;
            end if;
        when WRITE =>
            dat_done <= '0';
            add_done <= '0';
            data_line <= '0';
            if (add_bit = '1')then
                NextState <= WRITE_LONG;
            else
                NextState <= WRITE_SHORT;
            end if;
        when WRITE_LONG =>
            if(long_wr < 1)then
                dat_done <= '1';
                add_done <= '0';
                data_line <= long_add_wr(long_wr);
                NextState <= FINISH;
            elsif(long_wr < 9)then
                dat_done <= '0';
                add_done <= '0';
                data_line <= long_add_wr(long_wr);
                NextState <= WRITE_LONG;
            elsif(long_wr < 12)then
                dat_done <= '0';
                add_done <= '1';
                data_line <= long_add_wr(long_wr);
                NextState <= WRITE_LONG;
            else
                dat_done <= '0';
                add_done <= '0';
                data_line <= long_add_wr(long_wr);
                NextState <= WRITE_LONG;
            end if;
        when WRITE_SHORT =>
            if(short_wr < 1)then
                dat_done <= '1';
                add_done <= '0';
                data_line <= shrt_add_wr(short_wr);
                NextState <= FINISH;
            elsif(short_wr < 9)then
                dat_done <= '0';
                add_done <= '0';
                data_line <= shrt_add_wr(short_wr);
                NextState <= WRITE_SHORT;
            elsif(short_wr < 11)then
                dat_done <= '0';
                add_done <= '1';
                data_line <= shrt_add_wr(short_wr);
                NextState <= WRITE_SHORT;
            else
                dat_done <= '0';
                add_done <= '0';
                data_line <= shrt_add_wr(short_wr);
                NextState <= WRITE_SHORT;
            end if;
        when READ_LONG =>
            if (long_wr < 1)then
               dat_done <= '1';
               add_done <= '0';
               data_line <= long_add_wr(long_wr); 
               NextState <= FINISH; 
            elsif(long_wr < 9)then
               dat_done <= '0';
               add_done <= '0';
               data_line <= long_add_wr(long_wr);
               NextState <= READ_LONG;
            elsif(long_wr < 12)then
                dat_done <= '0';
                add_done <= '1';
                data_line <= long_add_wr(long_wr);  
                NextState <= READ_LONG; 
            else
                dat_done <= '0';
                add_done <= '0';
                data_line <= long_add_wr(long_wr);
                NextState <= READ_LONG;
            end if;
        when READ_SHORT =>
            if(short_wr < 1)then
                dat_done <= '1';
                add_done <= '0';
                data_line <= shrt_add_wr(short_wr);
                NextState <= FINISH;
            elsif(short_wr < 10) then
                dat_done <= '0';
                add_done <= '0';    
                data_line <= shrt_add_wr(short_wr);
                NextState <= READ_SHORT;
            elsif(short_wr < 12) then
                dat_done <= '0';
                add_done <= '1';   
                data_line <= shrt_add_wr(short_wr); 
                NextState <= READ_SHORT;
            else
                dat_done <= '0';
                add_done <= '0';
                data_line <= shrt_add_wr(short_wr);
                NextState <= READ_SHORT;
            end if;
        when FINISH =>
            add_done <= '1';
            dat_done <= '1';
            data_line <= '0';
            NextState <= IDLE;
        when others =>
            NextState <= IDLE;
    end case;
    
end process;

output_logic: process(CurrentState, NextState)
begin
    case CurrentState is
        when IDLE =>
            CS_NOT <= '1';
            count_down_en <= '0';
        when READ =>
            CS_NOT <= '0';
            count_down_en <= '0';
        when WRITE =>
            CS_NOT <= '0';
            count_down_en <= '0';
        when WRITE_LONG =>
            CS_NOT <= '0';
            count_down_en <= '1';
        when WRITE_SHORT =>
            CS_NOT <= '0';
            count_down_en <= '1';
        when READ_LONG =>
            CS_NOT <= '0';
            count_down_en <= '1';
        when READ_SHORT =>
            CS_NOT <= '0';
            count_down_en <= '1';
        when FINISH =>
            CS_NOT <= '1';
            count_down_en <= '0';
        when others =>
            CS_NOT <= '1';
            count_down_en <= '0';            
    end case;
end process;
end Behavioral;
