library ieee;
use IEEE.float_pkg.all;
use IEEE.fixed_pkg.all;
use IEEE.std_logic_1164.all;

entity FIR_filter is
    generic (
        g_clk_freq : integer := 120_000_000;
        g_data_width : integer := 16
    );
    port (
        i_clk : in std_logic;
        i_data : in std_logic_vector(g_data_width-1 downto 0);
        i_en : in std_logic;
        o_data : out std_logic_vector(g_data_width-1 downto 0)
    );
end entity;

architecture rtl of FIR_filter is

    type t_FIR_states is (s_idle, s_calc);
    signal s_Fir_state : t_FIR_states := s_idle;

    signal r_data_out : std_logic_vector(g_data_width-1 downto 0);
    signal r_new_data : sfixed(g_data_width downto -8);
    signal r_old_data : sfixed(g_data_width downto -8) := (others => '0');

    constant c_old_multiplier : sfixed(g_data_width-1 downto -8) := "000000000000000011110110";
    constant c_new_multiplier : sfixed(g_data_width-1 downto -8) := "000000000000000000001000";

    signal r_fixed_point_data : sfixed(10 downto -8);
    signal r_en : std_logic := '0';
    signal r_calc_done : std_logic := '0';
    signal r_done : std_logic := '1';

begin

    r_en <= i_en;

    -- Fixed point number 
    -- 0.96
    -- 
    -- 1      1      1      1      0      1       1
    -- .5     .25    .125   .0625  .03125 .015625 .0078125
    enable_FIR : process(i_clk)
    begin

        if rising_edge(i_clk) then
            if r_en = '1' and r_done = '1' then
                r_done <= '0';
            elsif r_en = '0' then
                r_done <= '1';
            end if; -- i_en

        end if; -- i_clk
        
    end process;


    calculate_moving_average : process(i_clk)
        variable v_temp : sfixed(g_data_width downto -8);
    begin
        if rising_edge(i_clk) then
            if r_done = '0' then
                r_calc_done <= '0';
            end if;
            
            if r_calc_done = '0' then
                r_new_data <= to_sfixed(i_data,g_data_width,-8);
                r_old_data <= c_old_multiplier * r_old_data + c_new_multiplier * to_sfixed(i_data,g_data_width,-8);
                r_data_out <= std_logic_vector(r_old_data(g_data_width-1 downto 0));
                r_calc_done <= '1';
            end if; -- r_done
        end if;
    end process;

end architecture rtl;