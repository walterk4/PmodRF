library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SIPO is
    Port ( clk : in STD_LOGIC;
           rst_n : in STD_LOGIC;
           enable : in STD_LOGIC;
           inp : in STD_LOGIC;
           oup : out STD_LOGIC_VECTOR (7 downto 0);
           disable : in STD_LOGIC);
end SIPO;

architecture Behavioral of SIPO is

COMPONENT DD is
    Port ( clk : in STD_LOGIC;
           rst_n : in STD_LOGIC;
           en : in STD_LOGIC;
           d : in STD_LOGIC;
           q : out STD_LOGIC);
end COMPONENT;

COMPONENT rsg_edge is
    Port ( clk : in STD_LOGIC;
       rst : in STD_LOGIC;
       inp : in STD_LOGIC;
       oup : out STD_LOGIC);
end COMPONENT;

COMPONENT Flng_edge is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           inp : in STD_LOGIC;
           oup : out STD_LOGIC);
end COMPONENT;

signal tmp : STD_LOGIC_VECTOR(8 downto 0);
signal en, dis, cntrl : STD_LOGIC;
signal count : integer := 0;

begin
UUT: Flng_edge PORT MAP (clk => clk, rst => rst_n, inp => enable, oup => en);
UTT: rsg_edge PORT MAP (clk => clk, rst => rst_n, inp => disable, oup => dis);
enable_process: process(en, dis, count)
begin
    if(count = 0)then
        if(en = '1')then
            cntrl <= '1';
        else
            cntrl <= '0';    
        end if;
    elsif(count < 8)then
        cntrl <= '1';
        if(dis = '1')then
            cntrl <= '0';
        else
            cntrl <= '1';
        end if;
    else
        cntrl <= '0';        
    end if;
end process;

clk_process: process(clk, rst_n, cntrl)
begin
    if(rst_n = '0')then
        count <= 0;
    elsif(clk'event and clk = '1')then
        if(cntrl ='1')then
            count <= count + 1;
        else
            count <= 0;
        end if;
    end if;
end process;

tmp(0) <= inp;

gen: for i in 0 to 7 generate
    DFF0: DD PORT MAP (clk => clk, rst_n => rst_n, en => cntrl, d => tmp(i), q => tmp(i+1));
end generate gen;

oup <= tmp(8 downto 1);
end Behavioral;
