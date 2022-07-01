library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.all;

entity spi_sdio is
    generic (
        g_clk_freq : integer := 120_000_000;
        g_sclk_freq : integer := 1_000_000;
        g_data_width : integer := 16
        );
    port (
        -- CLOCK
        i_clk : in std_logic;
        -- IO
        i_cs : in std_logic;
        io_pin : inout std_logic;
        -- DATA
        i_data_transmit : in std_logic_vector(g_data_width-1 downto 0);
        o_data_received : out std_logic_vector(7 downto 0);
        -- DATA VALID
        -- o_spi_rdy : out std_logic;
        o_spi_dv : out std_logic
        );
end entity spi_sdio;

architecture rtl of spi_sdio is

    type t_data_handle_states is (s_idle, s_first_bit, s_do_spi, s_write_data, s_done);
    signal s_data_handle_state : t_data_handle_states := s_idle;

    constant c_sclk_freq : integer := (g_clk_freq/g_sclk_freq);
    constant c_half_sclk : integer := (c_sclk_freq/2);
    constant c_dw_x2 : integer := (g_data_width*2)-1;

    signal r_half_sclk_counter : integer range 0 to c_half_sclk := 0;

    -- # of edges on the data
    signal r_sclk_edge_counter : integer range 0 to c_dw_x2 := 0;

    -- Data valid
    signal r_spi_dv : std_logic := '0';

    -- Chip Select in
    signal r_cs : std_logic;

    -- Data bits
    -- Incoming data
    signal r_data_transmit : std_logic_vector(g_data_width-1 downto 0);
    -- Which bit to send/receive
    signal r_out_bit_counter : integer range 0 to g_data_width-1;
    signal r_in_bit_counter : integer range 0 to (g_data_width/2)-1;
    -- 
    signal r_data_received : std_logic_vector(7 downto 0) := (others => '0');
    signal r_rw_bit : std_logic := '0';

    -- Tristate control
    signal r_we : std_logic := '0';
    signal r_out_bit : std_logic := '0';
    signal r_in_bit : std_logic := '0';

begin

    -- IN SIGNALS
    r_cs <= i_cs;
    r_data_transmit <= i_data_transmit;
    r_rw_bit <= i_data_transmit(0);
    
    -- OUT SIGNALS
    o_spi_dv <= r_spi_dv;
    o_data_received <= r_data_received;

    write_to_pin: process(i_clk)
    begin
        if rising_edge(i_clk) then

            case s_data_handle_state is

                when s_idle =>
                    r_spi_dv <= '0';
                    r_we <= '0';

                    r_sclk_edge_counter <= 0;
                    r_out_bit_counter <= 0;
                    r_in_bit_counter <= 0;
                    r_half_sclk_counter <= 0;

                    if r_cs = '0' then
                        r_we <= '1';
                        r_sclk_edge_counter <= r_sclk_edge_counter + 1;
                        s_data_handle_state <= s_do_spi;
                    else
                        s_data_handle_state <= s_idle;
                    end if;
                    

                when s_do_spi =>

                    if r_sclk_edge_counter = 17 then
                        if r_rw_bit = '1' then
                            r_we <= '0';
                        else
                            r_we <= '1';
                        end if;
                    end if;

                    r_out_bit <= r_data_transmit(r_out_bit_counter);
                    r_data_received(r_in_bit_counter) <= r_in_bit;

                    r_half_sclk_counter <= r_half_sclk_counter + 1;
                    if r_half_sclk_counter = c_half_sclk then
                        -- Increase the sclk bit counter by one when a halfway point is reached
                        -- r_test_counter <= r_sclk_edge_counter;
                        r_sclk_edge_counter <= r_sclk_edge_counter + 1;
                        r_half_sclk_counter <= 0;


                        if r_sclk_edge_counter < 17 then
                            r_we <= '1';
                            
                            if r_sclk_edge_counter mod 2 = 0 then
                                if r_out_bit_counter <= 7 then 
                                    r_out_bit_counter <= r_out_bit_counter + 1;
                                end if;
                            end if;

                        elsif r_sclk_edge_counter < c_dw_x2 and r_rw_bit = '1' then
                            -- r_we <= '0';
                            
                            if r_sclk_edge_counter mod 2 = 1 then
                                r_in_bit_counter <= r_in_bit_counter + 1;
                            end if;

                        elsif r_sclk_edge_counter < c_dw_x2 and r_rw_bit = '0' then
                            -- r_we <= '1';
                            -- r_out_bit <= r_data_transmit(r_out_bit_counter);
                            if r_sclk_edge_counter mod 2 = 0 then
                                r_out_bit_counter <= r_out_bit_counter + 1;
                            end if;

                        elsif r_sclk_edge_counter = c_dw_x2 then
                            s_data_handle_state <= s_done;
                        end if;

                    end if;
                
                when s_write_data =>
                    s_data_handle_state <= s_done;

                when s_done =>
                    r_spi_dv <= '1';
                    r_we <= '0';
                    if r_cs = '1' then
                        s_data_handle_state <= s_idle;
                    else
                        s_data_handle_state <= s_done;
                    end if;

            end case;
        end if;
    end process write_to_pin;


    data_pin : entity bidir
        port map (
            -- i_clk => i_clk,
            io_pin => io_pin,
            i_en => r_we,
            i_bit => r_in_bit,
            o_bit => r_out_bit);

    
    
end architecture rtl;