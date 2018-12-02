library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Receiver_MOD is
    Generic ( WIDTH : integer := 8;
             totalDevice : integer := 2  );
    Port ( clk, rst_n, enable, SDO : in STD_LOGIC;
           SDI, CS_NOT : out STD_LOGIC;
           LED_OUT : out STD_LOGIC_VECTOR(7 downto 0);
           Done : out STD_LOGIC);
end Receiver_MOD;

architecture Behavioral of Receiver_MOD is


component DATA_interface is
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
end component;

component DD is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           d : in STD_LOGIC;
           q : out STD_LOGIC);
end component;

component reg_param is
    generic (SIZE : integer := 8);
    Port ( clk : in STD_LOGIC;
           load : in STD_LOGIC;
           rst : in STD_LOGIC;
           d : in STD_LOGIC_VECTOR (SIZE-1 downto 0);
           q : out STD_LOGIC_VECTOR (SIZE-1 downto 0));
end component;

COMPONENT RAM_BLOCK
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;

component counter_addr is
    generic (COUNT : integer := 19);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           ena : in STD_LOGIC;
           outp : out STD_LOGIC_VECTOR (9 downto 0));
end component;

type StateType is (IDLE,UPDATE,READ,HOLD,STORE,OUTSTAGE,TRANSITION);
signal State, NextState : StateType;

signal REG_READ : std_logic_vector(7 downto 0) := (others => '0');
signal REG_IN, RAM_IN : std_logic_vector(7 downto 0);
signal count_end : std_logic_vector(9 downto 0);
signal count_array : unsigned(7 downto 0) := (others => '0');
signal count_addr : unsigned(9 downto 0) := (others => '0');
signal reg_en,RAM_en,ADDR_DONE, DATA_DONE,data_en,count_clr,count_en : std_logic;
signal RAM_wr : std_logic_vector(0 downto 0);
type addArray_Vec is array (0 to 17) of STD_LOGIC_VECTOR(11 downto 0);
type addArray_Bit is array (0 to 17) of STD_LOGIC;
type dataArray_Vec is array (0 to 17) of STD_LOGIC_VECTOR(7 downto 0);
type dataArray_Bit is array (0 to 17) of STD_LOGIC;
signal tmpaddArray : std_logic_vector(11 downto 0);
signal tmpaddBit : std_logic;
signal tmpdataArray : std_logic_vector(7 downto 0);
signal tmpRWBit : std_logic;
            
            --Short two letters , Long three letters                                
signal addressArray : addArray_Vec := (x"000",x"039",x"300",x"301",x"302",x"303",x"304",x"305",x"306",
                                       x"307",x"308",x"309",x"30A",x"30B",x"30C",x"30D",x"30E",x"039");
signal longShortArray : addArray_Bit := ('0','0','1','1','1','1','1','1','1','1','1','1','1','1','1'
                                          ,'1','1','0');
signal dataArray : dataArray_Vec := (x"00", x"04",REG_READ,REG_READ,REG_READ,REG_READ,REG_READ,REG_READ,
                                     REG_READ,REG_READ,REG_READ,REG_READ,REG_READ,REG_READ,REG_READ
                                     ,REG_READ,REG_READ,x"00");    
signal RWArray : dataArray_Bit := ('1', '1','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','1');
signal addArray : std_logic_vector(11 downto 0);
begin

GEN:
for I in 0 to 7 generate
    DD_GEN : DD port map(clk => clk, rst => rst_n, d => REG_READ(I),q => REG_IN(I)); 
end generate GEN;

reg_inst : reg_param port map(clk => clk, rst => rst_n,load => reg_en, d => REG_IN, q => RAM_IN);

counter_address : counter_addr generic map(COUNT => 18) port map(clk => clk, rst => count_clr, ena => count_en, outp => count_end);


RAM : RAM_BLOCK port map(clka => clk, ena => RAM_en, wea => RAM_wr, addra => count_end, dina => RAM_IN, douta => LED_OUT); 


DATA_ACCESS : DATA_interface port map (clk => clk, 
                                       rst => rst_n, 
                                       en => enable, 
                                       add_bit => tmpaddBit, 
                                       ADD => tmpaddArray, 
                                       RW_bit => tmpRWBit, 
                                       data => tmpdataArray,
                                       SPI => SDI,
                                       CS_NOT => CS_NOT, 
                                       ADDY_DONE => ADDR_DONE, 
                                       DATA_DONE => DATA_DONE);                                                               

SYNC_PROC: process (clk,enable)
begin
if (clk'event and clk = '1') then
     if (rst_n = '1') then
         State <= IDLE;
     elsif(enable = '1') then
         State <= NextState;
     end if;
end if;
end process;

OUTPUT_DECODE: process (state)
begin
if State = OUTSTAGE then
     RAM_en <= '1';
     RAM_wr <= "0";
else
     LED_OUT <= (others => '0');   
end if;
end process;


NEXT_STATE_DECODE : process(State,enable)
begin
    case(State) is
        when IDLE =>
            if (enable = '1') then
               NextState <= UPDATE;
            else
               NextState <= IDLE;
            end if;
        when UPDATE =>
            count_en <= '0';
            count_clr <= '0';
            Done <= '0';
            reg_en <= '0';
            RAM_en <= '0';
            RAM_wr <= "0";
            data_en <= '1';
            NextState <= READ;
        when READ => 
                tmpaddBit <= longShortArray(to_integer(count_array));
                tmpaddArray <= addressArray(to_integer(count_array));
                tmpRWBit <= RWArray(to_integer(count_array));
                tmpdataArray <= dataArray(to_integer(count_array));
                NextState <= HOLD;
        when HOLD => 
            if (ADDR_DONE = '0') then
                NextState <= STORE;
            else
                NextState <= HOLD;
            end if;
        when STORE =>
            if(count_array = 17) then
                reg_en <= '1';
                RAM_en <= '1';
                RAM_wr <= "1";
                data_en <= '0';
                count_clr <= '1';
                NextState <= OUTSTAGE;
            elsif(DATA_DONE = '1') then --change to '1'
                reg_en <= '1';
                RAM_en <= '1';
                RAM_wr <= "1";
                count_en <= '1';
                count_array <= count_array + 1;
                --enable off
                data_en <= '0';
                NextState <= UPDATE;
            else
                NextState <= STORE;
            end if;
        when OUTSTAGE => 
             if (count_end = std_logic_vector(to_unsigned(17,10))) then
                Done <= '1';
                count_clr <= '1';
                NextState <= IDLE;
             else
                count_clr <= '0';
                count_en <= '1';
                count_array <= (others => '0');
                NextState <= TRANSITION;
             end if;
        when TRANSITION =>
                count_en <= '0';
                NextState <= OUTSTAGE;
        when others =>
                NextState <= IDLE;
    end case;
end process;
end Behavioral;
