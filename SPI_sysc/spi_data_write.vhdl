library ieee;
use ieee.std_logic_1164.all;

entity spi_data_write is
    port (
        i_sclk : in std_logic;
        i_data : in std_logic_vector(14 downto 0);
        o_data : out std_logic_vector(7 downto 0);
        o_done : out std_logic
        );
end entity spi_data_write;

architecture rtl of spi_data_write is

    type t_write_states is ();

    signal s_read_or_write : std_logic := '0';
    signal s_address : std_logic_vector(5 downto 0) := (others => '0');
    signal s_data : std_logic_vector(7 downto 0) := (others => '0');

    signal s_bit_counter : integer range 0 to 14 := 14;

    signal s_we : std_logic := '1';
    signal s_data_bit : std_logic;

    component bidir_pin
        port (
            wr_en : IN std_logic;
            data_io : INOUT std_logic
          );
    end component;
    
begin

    s_read_or_write <= i_data(14);

    data_pin : bidir_pin 
        port map (
            wr_en => s_we;
            data_io => s_data_bit
        );
    

    write_to_pin: process(i_sclk)
    begin
        if falling_edge(i_sclk) then
            if s_read_or_write = '1' then
                s_we <= '1';
                s_data_bit <= i_data(s_bit_counter);
                s_bit_counter <= s_bit_counter - 1;
                if s_bit_counter = 0 then
                    s_bit_counter <= 14;
                end if;
            else 

            end if;
        end if;
    end process proc_name;

    
    
end architecture rtl;