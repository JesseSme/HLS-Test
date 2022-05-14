library ieee;
use ieee.std_logic_1164.all;

entity spi_cs_generator is
    generic (
        g_clk_freq : integer := 120_000_000;
        g_cs_freq : integer := 100
        );
    port (
        i_clk : in std_logic;
        i_done : in std_logic;
        o_cs : out std_logic
        );
end entity;


architecture rtl of spi_cs_generator is

    type t_cs_state is (s_idle, s_cs);
    signal s_cs_state : t_cs_state := s_idle;

    constant c_cs_freq : integer := (g_clk_freq/g_cs_freq);

    signal r_cs : std_logic := '1';
    signal r_done : std_logic;



begin
    o_cs <= r_cs;
    r_done <= i_done;


    p_generate_cs : process(i_clk)
        variable v_cs_counter : integer range 0 to c_cs_freq := 0;
    begin
        if rising_edge(i_clk) then
            case s_cs_state is
                when s_idle =>
                    r_cs <= '1';
                    if v_cs_counter = c_cs_freq then
                        v_cs_counter := 0;
                        s_cs_state <= s_cs;
                    else
                        v_cs_counter := v_cs_counter + 1;
                    end if;

                when s_cs =>
                    r_cs <= '0';
                    if r_done = '1' then
                        s_cs_state <= s_idle;
                    end if;
            end case;
        end if;
    end process;

end architecture rtl;