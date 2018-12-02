----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/10/2018 08:30:57 PM
-- Design Name: 
-- Module Name: Transmitter - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Transmitter is
    Generic ( WIDTH : integer := 8;
             totalDevice : integer := 2  );
    Port ( clk, rst_n, enable, SDO : in STD_LOGIC;
            SWITCHES : in STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
           SDI, SCK, CS_NOT : out STD_LOGIC;
           Done : out STD_LOGIC);
end Transmitter;

architecture Behavioral of Transmitter is

    component PmodRFDataAccess is
        Port ( enable, clk, rst_n, longShortAddress, RW : in STD_LOGIC;
               Done : out STD_LOGIC;
               SCK : out STD_LOGIC;
               -- There need to be 4 empty SCK between Long Address and Data. 
               Address : in STD_LOGIC_VECTOR (9 downto 0);
               TXData : in STD_LOGIC_VECTOR (7 downto 0);
               RXData, LEDs : out STD_LOGIC_VECTOR (7 downto 0);
               SDO : in STD_LOGIC;                  
               -- Read from PmodRF pin while falling_edge(clk)
               SDI : out STD_LOGIC;                 
               -- Write to PmodRF pin while rising_edge(clk)
               CS_NOT : out STD_LOGIC               
               -- CS_NOT needs to be kept low while communicating with PmodRF
               );
    end component;
    
    component trigger is
        Generic ( count : integer);
        Port ( start, clk, rst_n : in STD_LOGIC;
               outp : out STD_LOGIC);
    end component;
    
    type StateType is (RESET, SLEEP, EQUIP, EXECUTE, FINISH);
    signal CurrentState : StateType := SLEEP;
    signal NextState : StateType;
    
    signal accessEnable, isAccessDone : STD_LOGIC;
    signal Address : STD_LOGIC_VECTOR (9 downto 0);
    signal TXData, SequenceNumber : STD_LOGIC_VECTOR (7 downto 0);
    signal depthIndex, count, remaining, FrameLength, PayloadLength : integer := 0;
    
    type addArray_Vec is array (0 to 22) of STD_LOGIC_VECTOR(11 downto 0);
    type addArray_Bit is array (0 to 22) of STD_LOGIC;
    type dataArray_Vec is array (0 to (20 + totalDevice * 2)) of STD_LOGIC_VECTOR(7 downto 0);
    type dataArray_Bit is array (0 to (20 + totalDevice * 2)) of STD_LOGIC;
    
    signal addressArray : addArray_Vec := (x"000", x"001", x"002", x"003", x"004", 
                                           x"005", x"006", x"007", x"008", x"009",
                                           x"00A", x"00B", x"00C", x"00D");
    signal longShortArray : addArray_Bit := ('1', '1', '1', '1', '1', 
                                             '1', '1', '1', '1', '1',
                                             '1', '1', '1', '1');
    signal dataArray : dataArray_Vec := (x"0B", x"0C", x"01", x"29", x"2C", 
                                         x"EE", x"D4", x"41", x"E3", x"EE",
                                         x"CC", x"B7", x"23", SWITCHES);    
    signal RWArray : dataArray_Bit := ('1', '1', '1', '1', '1', 
                                       '1', '1', '1', '1', '1',
                                       '1', '1', '1', '1');

begin

DataAccess: PmodRFDataAccess    port map (rst_n => rst_n,
                                          Done => isAccessDone,
                                          clk => clk, 
                                          SCK => SCK,
                                          enable => accessEnable,
                                          longShortAddress => '1',
                                          RW => '1',
                                          Address => Address,
                                          TXData => TXData,
                                          SDO => '0',
                                          SDI => SDI,
                                          CS_NOT => CS_NOT);
    
    
    process (clk)
    begin
        if (CurrentState = SLEEP) then
            if (rising_edge(clk)) then
                if (count > 8) then
                    depthIndex <= depthIndex + 1;
                    PayloadLength <= PayloadLength + 1;
                    count <= count - 8;
                elsif (count < 8 and count > 0) then
                    remaining <= count;
                    PayloadLength <= PayloadLength + 1;
                    count <= count - 8;
                else
                    depthIndex <= depthIndex;
                    remaining <= remaining;
                    PayloadLength <= PayloadLength;
                    FrameLength <= PayloadLength + 5;
                end if;
            end if;
        elsif (CurrentState = RESET) then
            count <= WIDTH;
            depthIndex <= 0;
            PayloadLength <= 0;
            remaining <= 0;
            FrameLength <= 5;
        end if;
    end process;
    
	process (CurrentState, isAccessDone)
    begin
        case CurrentState is
            when RESET =>
                Address <= (others => '0');
                Done <= '0';
                accessEnable <= '0';
                NextState <= SLEEP;
            when SLEEP =>
            	
            	
           	when EQUIP =>
           		
           		NextState <= EXECUTE;
            when EXECUTE =>
            	
            	NextState <= SLEEP;
           	when FINISH =>
                Address <= (others => '0');
                Done <= '1';
                NextState <= SLEEP;
        end case;
    end process;
	
	process (clk, enable, rst_n)
    begin
        if rst_n = '0' then
            CurrentState <= RESET;
        else
            if enable = '0' then
                CurrentState <= SLEEP;
            elsif (rising_edge(clk)) then
                CurrentState <= NextState;
            end if;
        end if;
    end process;

end Behavioral;
