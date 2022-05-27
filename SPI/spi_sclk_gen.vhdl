library ieee;
use ieee.std_logic_1164.all;

entity spi_sclk_generator is
    generic (
        g_clk_freq : integer := 120_000_000;
        g_sclk_freq : integer := 1_000_000;
        g_data_width : integer := 16
        );
    port (
        i_clk : in std_logic;
        i_cs : in std_logic;
        o_sclk : out std_logic
        -- o_data_index : out integer
        );
end entity;


architecture rtl of spi_sclk_generator is

    type t_sclk_state is (s_idle, s_do_sclk);
    signal s_sclk_state : t_sclk_state := s_idle;

    constant c_sclk_freq : integer := (g_clk_freq/g_sclk_freq);
    constant c_half_sclk : integer := (c_sclk_freq/2)-1;

    signal s_half_sclk_counter : integer range 0 to c_half_sclk;

    signal r_cs : std_logic;
    signal r_sclk : std_logic := '1';
    signal r_sclk_m1 : std_logic := '1';

    -- signal r_edges : integer range (g_data_width*2)+1 downto 0 := g_data_width*2;

    -- signal r_data_index : integer range 0 to g_data_width*2 := 0;

begin

    p_generate_sclk : process(i_clk)
    begin
        if rising_edge(i_clk) then

            case s_sclk_state is

                -- Wait until CS goes down
                when s_idle =>
                    r_sclk <= '1';
                    s_half_sclk_counter <= 0;
                    if r_cs = '0' then
                        s_sclk_state <= s_do_sclk;
                    else
                        s_sclk_state <= s_idle;
                    end if;


                when s_do_sclk =>
                    -- Count up until half sclk speed
                    if r_cs = '1' then
                        s_sclk_state <= s_idle;
                    else
                        s_half_sclk_counter <= s_half_sclk_counter + 1;
                        if s_half_sclk_counter = c_half_sclk then
                            -- r_data_index <= r_data_index + 1;
                            s_half_sclk_counter <= 0;
                            r_sclk <= not r_sclk;
                        end if;
                    end if;
            end case;
        end if;
    end process p_generate_sclk;

    -- r_sclk_m1 <= r_sclk;
    o_sclk <= r_sclk;
    -- o_bit_pos <= r_bit_pos when i_cs = '0' else 0;

    r_cs <= i_cs;

    -- o_data_index <= r_data_index;
    
end architecture rtl;