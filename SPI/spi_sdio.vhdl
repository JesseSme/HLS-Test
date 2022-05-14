library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library SPI_sysc;
use SPI_sysc.adxl_addresses;

entity spi_sdio is
    generic (
        g_clk_freq : integer := 120_000_000;
        g_sclk_freq : integer := 1_000_000;
        g_data_width : integer := 16
        );
    port (
        i_clk : in std_logic;
        i_cs : in std_logic;
        i_data : in std_logic_vector(g_data_width-1 downto 0);
        o_data : out std_logic_vector(7 downto 0);
        o_bit_out : out std_logic;
        i_bit_in : in std_logic;
        o_we : out std_logic;
        o_test_counter : out integer;
        o_done : out std_logic
        );
end entity spi_sdio;

architecture rtl of spi_sdio is

    type t_data_handle_states is (s_idle, s_write, s_read, s_done);
    signal s_data_handle_state : t_data_handle_states := s_idle;

    constant c_sclk_freq : integer := (g_clk_freq/g_sclk_freq);
    constant c_half_sclk : integer := (c_sclk_freq/2);
    constant c_dw_x2 : integer := (g_data_width*2);


    signal r_done : std_logic := '0';
    signal r_we : std_logic := '1';
    signal r_cs : std_logic;


    signal r_in_data : std_logic_vector(15 downto 0);
    signal r_rw_bit : std_logic := '0';
    signal r_out_data_tmp : std_logic_vector(7 downto 0);
    signal r_out_data : std_logic_vector(7 downto 0);


    signal r_out_bit : std_logic := '0';
    signal r_in_bit : std_logic := '0';

    signal r_half_sclk_counter : integer range 0 to c_half_sclk := 0;
    signal r_sclk_counter : integer range 0 to c_dw_x2 := 0;
    signal r_bit_counter : integer range 0 to g_data_width := 0;
    signal r_inbit_counter : integer range 0 to 9 := 0;

    -- signal r_test_counter : integer;

begin

    o_done <= r_done;
    o_we <= r_we; -- not'd when using IP-block
    r_cs <= i_cs;

    r_in_data <= i_data;
    r_rw_bit <= not i_data(0);

    o_bit_out <= r_out_bit;
    r_in_bit <= i_bit_in;

    -- o_test_counter <= r_test_counter;
    o_data <= r_out_data;

    write_to_pin: process(i_clk)
    begin
        if rising_edge(i_clk) then

            case s_data_handle_state is

                when s_idle =>
                    r_done <= '0';
                    r_we <= '1';
                    r_sclk_counter <= 0;
                    r_bit_counter <= 0;
                    r_inbit_counter <= 0;
                    r_half_sclk_counter <= 0;
                    -- r_test_counter <= r_sclk_counter;
                    if r_cs = '0' then
                        if r_rw_bit = '1' then
                            s_data_handle_state <= s_write;
                        else
                            s_data_handle_state <= s_read;
                        end if;
                    else
                        s_data_handle_state <= s_idle;
                    end if;

                when s_read =>
                    r_half_sclk_counter <= r_half_sclk_counter + 1;
                    if r_half_sclk_counter = c_half_sclk then
                        -- Increase the sclk bit counter by one when a halfway point is reached
                        -- r_test_counter <= r_sclk_counter;
                        r_sclk_counter <= r_sclk_counter + 1;
                        r_half_sclk_counter <= 0;

                        if r_sclk_counter = c_dw_x2-1 then
                            s_data_handle_state <= s_done;
                        end if;

                        r_out_bit <= r_in_data(r_bit_counter);
                        if r_sclk_counter < 17 then
                            r_we <= '1';
                            if r_sclk_counter mod 2 = 1 then
                                if r_bit_counter <= 7 then 
                                    r_bit_counter <= r_bit_counter + 1;
                                end if;
                            end if;
                        else 
                            r_we <= '0';
                            if r_sclk_counter mod 2 = 0 then
                                r_out_data(r_inbit_counter) <= r_in_bit;
                                r_inbit_counter <= r_inbit_counter + 1;
                            end if;
                        end if;

                    end if;


                when s_write =>
                    r_half_sclk_counter <= r_half_sclk_counter + 1;
                    if r_half_sclk_counter = c_half_sclk then
                        -- Increase the sclk bit counter by one when a halfway point is reached
                        -- r_test_counter <= r_sclk_counter;
                        r_sclk_counter <= r_sclk_counter + 1;
                        r_half_sclk_counter <= 0;

                        if r_sclk_counter = c_dw_x2-1 then
                            s_data_handle_state <= s_done;
                        end if;

                        r_out_bit <= r_in_data(r_bit_counter);
                        if r_sclk_counter mod 2 = 1 then
                            if r_bit_counter /= 15 then 
                                r_bit_counter <= r_bit_counter + 1;
                            end if;
                        end if;
                    end if;

                when s_done =>
                    r_done <= '1';
                    r_we <= '1';
                    if r_cs = '1' then
                        s_data_handle_state <= s_idle;
                    else
                        s_data_handle_state <= s_done;
                    end if;

            end case;
        end if;
    end process write_to_pin;

    
    
end architecture rtl;