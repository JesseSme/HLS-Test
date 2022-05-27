library ieee;
use ieee.std_logic_1164.all;
use ieee.fixed_pkg.all;

entity spi_cs_generator is
    generic (
        g_clk_freq : integer := 120_000_000;
        g_cs_freq : integer := 3200
        );
    port (
        i_clk : in std_logic;
        i_done : in std_logic;
        i_we : in std_logic;
        o_cs : out std_logic
        );
end entity;


architecture rtl of spi_cs_generator is

    type t_cs_state is (s_idle, s_cs, s_cs_deassertion);
    signal s_cs_state : t_cs_state := s_idle;

    -- Amount of clock cycles between pulling CS down
    constant c_cs_freq : integer := (g_clk_freq/g_cs_freq);
    constant c_clk_in_ns : sfixed(20 downto -10) := to_sfixed((1.0/g_clk_freq)*1_000_000_000.0, 20, -10);
    constant c_cs_deassertion_max : integer := 150/to_integer(c_clk_in_ns);

    signal r_cs : std_logic := '1';
    signal r_done : std_logic;

begin
    o_cs <= r_cs;
    r_done <= i_done;


    p_generate_cs : process(i_clk)
        -- Clock cycles between readings
        variable v_cs_counter : integer range 0 to c_cs_freq := 0;
        -- Clock cycles between reads. MIN 150ns
        variable v_cs_deassertion_counter : integer range 0 to c_cs_deassertion_max;
        -- Amount of axis to read
        variable v_axis_count : integer range 0 to 5 := 0;
    begin
        if rising_edge(i_clk) then
            case s_cs_state is
                when s_idle =>
                    if i_we = '1' then
                        r_cs <= '1';
                        if v_cs_counter = c_cs_freq then
                            v_cs_counter := 0;
                            s_cs_state <= s_cs;
                        else
                            v_cs_counter := v_cs_counter + 1;
                        end if;
                    else
                        v_axis_count := 0;
                        v_cs_counter := 0;
                        r_cs <= '1';
                    end if;

                when s_cs =>
                    r_cs <= '0';

                    if r_done = '1' and v_axis_count = 5 then
                        s_cs_state <= s_idle;
                    elsif r_done = '1' then
                        v_axis_count := v_axis_count + 1;
                        s_cs_state <= s_cs_deassertion;
                    end if;

                when s_cs_deassertion =>
                    r_cs <= '1';
                    if v_cs_deassertion_counter = c_cs_deassertion_max then
                        v_cs_deassertion_counter := 0;
                        s_cs_state <= s_cs;
                    else
                        v_cs_deassertion_counter := v_cs_deassertion_counter + 1;
                    end if;
            end case;
        end if;
    end process;

end architecture rtl;