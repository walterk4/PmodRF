library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity debounce is
    Port ( clk : in STD_LOGIC;
       rst : in STD_LOGIC;
       input : in STD_LOGIC;
       output : out STD_LOGIC);
end debounce;

architecture Behavioral of debounce is
signal x, y, SCLR, ena : STD_LOGIC;
signal cnt : STD_LOGIC_VECTOR(18 downto 0);
begin
ff_process: process (rst, clk, input)
begin
    if(clk' event and clk = '1')then
        if (rst = '0') then     -- Active Low device
            output <= '0';
            x <= '0';
            y <= '0';
            --oup <= '0';
        else
            x <= input;
            y <= x;
            if (ena = '1') then
                output <= y;
            end if;
        end if;
    end if;
end process;

counter_process: process(clk)
begin
    if(clk'event and clk = '1') then
        if (rst = '0') then
            cnt <= (others => '0');
        else
            if (SCLR = '1') then
                cnt <= (others => '0');
            else
                if (ena = '0')then
                    cnt <= STD_LOGIC_VECTOR(unsigned(cnt) + 1);
                else
                    cnt <= cnt;
                end if;
            end if;
        end if;
    end if;
end process;
ena <= cnt(18) AND cnt(17) AND cnt(16) AND cnt(15) AND cnt(14) AND cnt(13) AND cnt(12) AND cnt(11) AND cnt(10) AND cnt(9) AND cnt(8) AND cnt(7) AND cnt(6) AND cnt(5) AND cnt(4) AND cnt(3) AND cnt(2) AND cnt(1) AND cnt(0);
--ena <= cnt(12) AND cnt(11) AND cnt(10) AND cnt(9) AND cnt(8) AND cnt(7) AND cnt(6) AND cnt(5) AND cnt(4) AND cnt(3) AND cnt(2) AND cnt(1) AND cnt(0);
SCLR <= x XOR y;
--output <= oup;
end Behavioral;