library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity FIR_filter is
    generic (
        g_data_width : integer := 16;
        g_axis_data_width : integer := 10
    );
    port (
        i_clk : in std_logic;
        i_data : in std_logic_vector(g_data_width-1 downto 0);
        i_en : in std_logic;
        i_cs : in std_logic;
        o_data : out std_logic_vector(g_data_width-1 downto 0);
        o_DV : out std_logic
    );
end entity;

architecture rtl of FIR_filter is

    type t_fir_state is (s_idle, s_calc, s_done);
    signal s_fir_state : t_fir_state := s_idle;

    signal r_data_out : std_logic_vector(g_data_width-1 downto 0);
    signal r_new_data : signed((g_axis_data_width-1)+8 downto 0);
    signal r_old_data : signed((g_axis_data_width-1)+8 downto 0) := (others => '0');

    --                                  integer + fractional bits
    constant c_old_multiplier : signed((g_axis_data_width-1)+8 downto 0) := "000000000011110110";
    constant c_new_multiplier : signed((g_axis_data_width-1)+8 downto 0) := "000000000000001000";

    signal r_result : signed((((g_axis_data_width-1)+8)*2)+1 downto 0);
    signal r_en : std_logic := '0';
    signal r_calc_done : std_logic := '0';
    signal r_done : std_logic := '1';

    signal r_counter : integer range 0 to 5 := 0;

begin

    r_en <= i_en;
    o_DV <= r_done;
    o_data <= r_data_out;

    -- Fixed point number 
    -- 0.96
    -- 
    -- 1      1      1      1      0      1       1
    -- .5     .25    .125   .0625  .03125 .015625 .0078125
    calculate_moving_average : process(i_clk)
    begin
        if rising_edge(i_clk) then

            if r_en = '1' then

                if r_counter = 0 then
                    r_new_data((g_axis_data_width-1)+8 downto 8) <= signed(i_data(9 downto 0));
                elsif r_counter = 1 then
                    r_result <= c_old_multiplier * r_old_data + c_new_multiplier * r_new_data;
                elsif r_counter < 5 then
                elsif r_counter = 5 then
                    r_counter <= 0;
                    r_old_data((g_axis_data_width-1)+8 downto 8) <= r_result(25 downto 16);
                    r_data_out <= "000000" & std_logic_vector(r_result(25 downto 16));
                    r_done <= '1';
                end if;
                r_counter <= r_counter + 1;

            else
                r_done <= '0';
            end if;
        end if;
    end process;

end architecture rtl;