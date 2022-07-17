library ieee;
use ieee.std_logic_1164.all;
use work.all;
use work.alpha_hex.all;

entity data_forward is
    generic (
        g_data_width        : integer := 16;
        g_marked_data_width : integer := g_data_width+8;
        g_full_data_width   : integer := g_data_width*3;
        g_alpha_marker      : std_logic_vector(7 downto 0) := c_A
    );
    port (
        i_clk           : in std_logic;
        -- i_en_arr        : in t_fir_enable_array;
        i_en            : in std_logic;
        -- i_data_arr      : in t_axis_data_array;
        i_data          : in std_logic_vector(g_full_data_width-1 downto 0);
        o_data          : out std_logic_vector(g_marked_data_width-1 downto 0);
        o_fifo_enable   : out std_logic
    );
end data_forward;

architecture structural of data_forward is

    type t_data_array is array (0 to 2) of std_logic_vector(g_data_width-1 downto 0);
    signal s_data_array : t_data_array;

    type t_data_forward_state is (s_idle, s_setup, s_forward);
    signal s_data_forward_state : t_data_forward_state := s_idle;

    -- signal s_fir_enable_array : t_fir_enable_array;
    -- signal s_axis_data_array : t_axis_data_array;

    signal r_counter : integer range 0 to 2 := 0;

    signal r_en : std_logic := '0';
    signal r_fifo_enable : std_logic := '0';
    signal r_data_in : std_logic_vector(g_full_data_width-1 downto 0) := (others => '0');
    signal r_data_out : std_logic_vector(g_data_width-1 downto 0) := (others => '0');


begin

    -- IN DATA
    r_en <= i_en;
    r_data_in <= i_data;

    -- OUT DATA
    o_data <= g_alpha_marker & r_data_out;
    o_fifo_enable <= r_fifo_enable;


    -- 
    process (i_clk)
    begin
        if rising_edge(i_clk) then
            case s_data_forward_state is
                when s_idle =>
                    r_fifo_enable <= '0';
                    r_counter <= 0;
                    if r_en = '1' then
                        s_data_array(2) <= r_data_in(47 downto 32);
                        s_data_array(1) <= r_data_in(31 downto 16);
                        s_data_array(0) <= r_data_in(15 downto 0);
                        s_data_forward_state <= s_setup;
                    else
                        s_data_forward_state <= s_idle;
                    end if;

                when s_setup =>
                    r_data_out <= s_data_array(r_counter);
                    s_data_forward_state <= s_forward;

                when s_forward =>
                    r_counter <= r_counter + 1;
                    r_fifo_enable <= '1';
                    r_data_out <= s_data_array(r_counter);
                    if r_counter = 2 then
                        s_data_forward_state <= s_idle;
                    end if;
                    
            end case;
        end if;
    end process;


end architecture structural;