library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.uart_tx;
use work.uart_rx;

entity uart_top is
    generic (
        g_clk_freq     : integer := 120_000_000;
        g_clks_per_bit : integer := 1041; -- 115200 baud at 120MHz
        -- g_data_width : integer := 24;
        g_data_width : integer := 32;
        g_byte_width : integer := 8
    );
    port (
        i_clk     : in std_logic;
        i_we      : in std_logic;
        o_fifo_re : out std_logic;
        i_data    : in std_logic_vector(g_data_width - 1 downto 0) := (others => '0');
        o_DV      : out std_logic;
        -- RX/TX
        i_RX : in std_logic;
        o_TX : out std_logic
    );
end entity;

architecture structural of uart_top is

    type t_uart_state is (s_idle,
        s_read_fifo,
        s_send_bytes,
        s_wait_TX_DONE);
    signal s_uart_state : t_uart_state := s_idle;

    signal r_data     : std_logic_vector(g_data_width - 1 downto 0);
    signal r_data_tmp : std_logic_vector(g_data_width - 1 downto 0);

    signal r_TX_DV     : std_logic                    := '0';
    signal r_TX_BYTE   : std_logic_vector(7 downto 0) := "10001010";
    signal r_TX_ACTIVE : std_logic;
    signal w_TX_SERIAL : std_logic;
    signal w_TX_DONE   : std_logic;
    signal w_RX_DV     : std_logic;
    signal w_RX_BYTE   : std_logic_vector(7 downto 0);
    signal r_RX_SERIAL : std_logic;

    signal r_we       : std_logic                    := '0';
    signal w_SPI_BYTE : std_logic_vector(7 downto 0) := "10101010";

    signal r_fifo_re : std_logic := '0';

    signal r_byte_counter : integer range 0 to 3 := 3;

begin
    r_we        <= not i_we;
    o_fifo_re   <= r_fifo_re;
    o_TX        <= w_TX_Serial;
    r_RX_SERIAL <= i_RX;
    r_data_tmp  <= i_data;
    -- Instantiate UART Receiver
    -- UART_RX_INST : entity uart_rx
    --     generic map (
    --         g_CLKS_PER_BIT => g_CLKS_PER_BIT
    --         )
    --     port map (
    --         i_clk       => i_clk,
    --         i_rx_serial => r_RX_SERIAL,
    --         o_rx_dv     => w_RX_DV,
    --         o_rx_byte   => w_RX_BYTE
    --         );
    -- Instantiate UART transmitter
    UART_TX_INST : entity uart_tx
        generic map(
            g_clks_per_bit => g_clks_per_bit
        )
        port map(
            i_clk       => i_clk,
            i_tx_dv     => r_TX_DV,
            i_tx_byte   => w_SPI_BYTE,
            o_tx_active => r_TX_ACTIVE,
            o_tx_serial => w_TX_SERIAL,
            o_tx_done   => w_TX_DONE
        );

    p_write_bytes : process (i_clk) is
    begin
        if rising_edge(i_clk) then

            case s_uart_state is

                when s_idle =>
                    -- w_SPI_BYTE <= (others => '0');
                    r_fifo_re      <= '0';
                    r_TX_DV        <= '0';
                    r_byte_counter <= 3;
                    if r_we = '1' then
                        s_uart_state <= s_read_fifo;
                    else
                        s_uart_state <= s_idle;
                    end if;

                when s_read_fifo =>
                    r_fifo_re    <= '1';
                    r_data       <= r_data_tmp;
                    s_uart_state <= s_send_bytes;

                when s_send_bytes =>
                    if r_byte_counter = 3 then
                        w_SPI_BYTE <= r_data((g_byte_width * 4) - 1 downto (g_byte_width * 3));
                    elsif r_byte_counter = 2 then
                        w_SPI_BYTE <= r_data(((g_byte_width * 3) - 1) downto (g_byte_width * 2));
                    elsif r_byte_counter = 1 then
                        w_SPI_BYTE <= r_data(((g_byte_width * 2) - 1) downto (g_byte_width * 1));
                    elsif r_byte_counter = 0 then
                        w_SPI_BYTE <= r_data(((g_byte_width * 1) - 1) downto (g_byte_width * 0));
                    end if;
                    r_fifo_re <= '0';
                    r_TX_DV      <= '1';
                    s_uart_state <= s_wait_TX_DONE;

                when s_wait_TX_DONE =>
                    r_fifo_re <= '0';
                    r_TX_DV   <= '0';
                    if w_TX_DONE = '1' then
                        if r_byte_counter = 0 then
                            s_uart_state <= s_idle;
                        else
                            r_byte_counter <= r_byte_counter - 1;
                            s_uart_state   <= s_send_bytes;
                        end if;
                        -- s_uart_state <= s_delay_1s   
                    else
                        s_uart_state <= s_wait_TX_DONE;
                    end if;
            end case;
        end if;
    end process;
end architecture structural;