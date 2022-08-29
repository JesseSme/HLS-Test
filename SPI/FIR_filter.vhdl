library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity FIR_filter is
    generic (
        g_data_width        : integer := 16;
        g_filter_data_width : integer := g_data_width + 8;
        g_result_data_width : integer := (g_filter_data_width * 2);
        g_full_data_width   : integer := g_data_width * 3
    );
    port (
        i_clk  : in std_logic;
        i_data : in std_logic_vector(g_full_data_width - 1 downto 0);
        i_en   : in std_logic;
        o_data : out std_logic_vector(g_full_data_width - 1 downto 0);
        o_DV   : out std_logic
    );
end entity;

architecture rtl of FIR_filter is

    type t_fir_state is (s_idle, s_calc, s_wait, s_data_valid, s_done);
    signal s_fir_state : t_fir_state := s_idle;

    signal r_data_out : std_logic_vector(g_full_data_width - 1 downto 0);
    signal r_data_in  : std_logic_vector(g_full_data_width - 1 downto 0);

    -- NEW DATA
    signal r_new_data_x : signed(g_filter_data_width - 1 downto 0);
    signal r_new_data_y : signed(g_filter_data_width - 1 downto 0);
    signal r_new_data_z : signed(g_filter_data_width - 1 downto 0);

    -- OLD DATA
    signal r_old_data_x : signed(g_filter_data_width - 1 downto 0) := (others => '0');
    signal r_old_data_y : signed(g_filter_data_width - 1 downto 0) := (others => '0');
    signal r_old_data_z : signed(g_filter_data_width - 1 downto 0) := (others => '0');

    -- SIGN BIT
    signal r_sign_bit_x : std_logic := '0';
    signal r_sign_bit_y : std_logic := '0';
    signal r_sign_bit_z : std_logic := '0';

    -- TODO: Add the right amount of bits for mult+acc
    --      The current amount is probably wrong.
    --                                  integer + fractional bits                       1      1      1      1      0      1       1
    --                                  16        8                                     .5     .25    .125   .0625  .03125 .015625 .0078125
    constant c_old_multiplier : signed(g_filter_data_width - 1 downto 0) := "00000000" & "00000000" & "11101110";
    constant c_new_multiplier : signed(g_filter_data_width - 1 downto 0) := "00000000" & "00000000" & "00010000";

    signal r_result_x  : signed(g_result_data_width - 1 downto 0);
    signal r_result_y  : signed(g_result_data_width - 1 downto 0);
    signal r_result_z  : signed(g_result_data_width - 1 downto 0);
    signal r_en        : std_logic := '0';
    signal r_calc_done : std_logic := '0';
    signal r_dv        : std_logic := '1';

    constant c_counter_max : integer                          := 20;
    signal r_counter       : integer range 0 to c_counter_max := 0;

begin

    r_en      <= i_en;
    o_DV      <= r_dv;
    o_data    <= r_data_out;
    r_data_in <= i_data;

    calculate_moving_average : process (i_clk)
    begin
        if rising_edge(i_clk) then

            case s_fir_state is
                when s_idle =>
                    r_counter <= 0;
                    r_dv      <= '0';
                    if r_en = '1' then
                        r_new_data_x((g_data_width - 1) + 8 downto 0) <= signed(r_data_in(15 downto 0)) & "00000000";
                        r_new_data_y((g_data_width - 1) + 8 downto 0) <= signed(r_data_in(31 downto 16)) & "00000000";
                        r_new_data_z((g_data_width - 1) + 8 downto 0) <= signed(r_data_in(47 downto 32)) & "00000000";
                        r_sign_bit_x                                  <= r_data_in(15);
                        r_sign_bit_y                                  <= r_data_in(31);
                        r_sign_bit_z                                  <= r_data_in(47);
                        s_fir_state                                   <= s_calc;
                    else
                        s_fir_state <= s_idle;
                    end if;

                when s_calc =>
                    r_result_x  <= c_old_multiplier * r_old_data_x + c_new_multiplier * r_new_data_x;
                    r_result_y  <= c_old_multiplier * r_old_data_y + c_new_multiplier * r_new_data_y;
                    r_result_z  <= c_old_multiplier * r_old_data_z + c_new_multiplier * r_new_data_z;
                    s_fir_state <= s_wait;

                when s_wait =>
                    r_counter <= r_counter + 1;
                    if r_counter = c_counter_max then
                        r_old_data_x((g_data_width - 1) + 8 downto 0) <= r_sign_bit_x & r_result_x(30 downto 16) & "00000000";
                        r_old_data_y((g_data_width - 1) + 8 downto 0) <= r_sign_bit_y & r_result_y(30 downto 16) & "00000000";
                        r_old_data_z((g_data_width - 1) + 8 downto 0) <= r_sign_bit_z & r_result_z(30 downto 16) & "00000000";
                        r_data_out                                    <= r_sign_bit_x & std_logic_vector(r_result_x(30 downto 16))
                            & r_sign_bit_y & std_logic_vector(r_result_y(30 downto 16))
                            & r_sign_bit_z & std_logic_vector(r_result_z(30 downto 16));
                        s_fir_state <= s_data_valid;
                    else
                        s_fir_state <= s_wait;
                    end if;

                when s_data_valid =>
                    r_dv        <= '1';
                    s_fir_state <= s_done;

                when s_done =>
                    r_dv        <= '0';
                    s_fir_state <= s_idle;

            end case;
        end if;
    end process;

end architecture rtl;