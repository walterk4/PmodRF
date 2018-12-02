library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity interruptHandler is
    Port ( clk, rst_n : in STD_LOGIC;
           enable : in STD_LOGIC;
           SDO : in STD_LOGIC;
           SDI : out STD_LOGIC;
           SCK : out STD_LOGIC;
           CS_NOT : out STD_LOGIC;
           isWorkDone : out STD_LOGIC;
           originalInterruptStat : in STD_LOGIC_VECTOR (7 downto 0)
           );
end interruptHandler;

architecture Behavioral of interruptHandler is

    component PmodRFDataAccess is
        Port ( enable, clk, rst_n, longShortAddress, RW : in STD_LOGIC;
               Done : out STD_LOGIC;
               SCK : out STD_LOGIC;
               Address : in STD_LOGIC_VECTOR (9 downto 0);
               TXData : in STD_LOGIC_VECTOR (7 downto 0);
               RXData, LEDs : out STD_LOGIC_VECTOR (7 downto 0);
               SDO : in STD_LOGIC;                  
               SDI : out STD_LOGIC;                 
               CS_NOT : out STD_LOGIC               
               );
    end component;
    
    shared variable INTSTAT : STD_LOGIC_VECTOR (11 downto 0) := x"031";
    signal accessEnable, isInterruptDone : STD_LOGIC := '0';
    signal longShortAddressIndicator, RWIndicator, isAccessDone : STD_LOGIC := '-';
    signal Address : STD_LOGIC_VECTOR (9 downto 0);
    signal newInterruptStat, Data : STD_LOGIC_VECTOR (7 downto 0);
    
begin

DataAccess: PmodRFDataAccess    port map (rst_n => rst_n,
                                          clk => clk, 
                                          enable => accessEnable,
                                          SCK => SCK,
                                          longShortAddress => longShortAddressIndicator,
                                          RW => RWIndicator,
                                          Address => Address,
                                          TXData => Data,
                                          RXData => newInterruptStat,
                                          SDO => SDO,
                                          SDI => SDI,
                                          CS_NOT => isAccessDone);

    isWorkDone <= isInterruptDone;
    
end Behavioral;
