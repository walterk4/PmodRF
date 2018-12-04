library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DD is
    Port ( clk : in STD_LOGIC;
           rst_n : in STD_LOGIC;
           en : in STD_LOGIC;
           d : in STD_LOGIC;
           q : out STD_LOGIC);
end DD;

architecture Behavioral of DD is
signal tmp_q : std_logic;

begin

process(clk, rst_n)
begin    
if(rst_n = '0') then
        tmp_q <= '0';
elsif(en = '0')then
    tmp_q <= tmp_q;
elsif (clk' event and clk = '1') then
        tmp_q <= d;
else
        tmp_q <= tmp_q;
end if;
end process;
    q <= tmp_q;
end Behavioral;
