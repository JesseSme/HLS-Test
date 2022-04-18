library ieee;
use ieee.std_logic_1164.all;

entity spi_sclk_generator is
    generic (
        g_clk_freq : integer := 120_000_000;
        g_sclk_freq : integer := 5_000_000;
        g_data_width : integer := 15;
        );
    port (
        i_clk : in std_logic;
        i_cs : in std_logic;
        o_sclk : out std_logic
        );
end entity;



architecture rtl of spi_sclk_generator is

    constant c_sclk_freq : integer := (g_clk_freq/g_sclk_freq);
    constant c_half_sclk : integer := (c_sclk_freq/2);

    signal r_cs : std_logic;
    signal r_sclk : std_logic := '1';

begin

    p_generate_sclk : process(i_clk)
        variable v_half_sclk_counter : integer range 0 to c_half_sclk;
    begin
        if rising_edge(i_clk) then
            if i_cs = '0' then
                v_half_sclk_counter := v_half_sclk_counter + 1;
                if v_half_sclk_counter = c_half_sclk then
                    v_half_sclk_counter := 0;
                    r_sclk <= not r_sclk;
                end if;
            else
                r_sclk <= '1';
            end if;
        end if;
    end process p_generate_sclk;

    o_sclk <= r_sclk;
    
end architecture rtl;