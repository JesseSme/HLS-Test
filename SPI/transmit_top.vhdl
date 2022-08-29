library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.spi_top;
use work.data_forward;
use work.uart_top;
use work.FIR_filter;

entity transmit_top is
    generic (
        g_data_width : integer := 16
    );
    port (
        -- clk : in std_logic;
        rst_n    : in std_logic;
        i_rst : in std_logic;
        o_TX     : out std_logic;
        i_RX     : in std_logic;
        -- sdio : inout std_logic_vector(17 downto 0);
        sdio : inout std_logic;
        -- debug : out std_logic_vector(7 downto 0);
        o_sclk      : out std_logic;
        o_cs        : out std_logic;
        o_debug_led : out std_logic
    );
end entity transmit_top;

architecture top of transmit_top is

    type t_passthrough_ctrl is (s_Idle, s_Start, s_Wait);
    signal r_passthrough_ctrl : t_passthrough_ctrl := s_Idle;

    type t_button_ctrl is (s_button_idle, s_button_pressed, s_button_held);
    signal r_button_ctrl : t_button_ctrl := s_button_idle;

    constant c_CLKS_PER_BIT : integer := 130;
    constant c_CLK_FREQ     : integer := 120_000_000;
    constant c_SCLK_FREQ    : integer := 2_000_000;

    -- MANUALLY ENABLE READING
    signal r_old_button : std_logic := '0';
    signal r_out_button : std_logic := '0';

    -- SPI PORTS
    signal r_sclk   : std_logic := '1';
    signal r_cs     : std_logic;
    signal r_spi_dv : std_logic_vector(17 downto 0) := (others => '0'); --! ADXL data valid ports

    -- ACCELEROMETER REGISTERS
    signal r_axis_data_non_filtered : std_logic_vector((g_data_width * 3) - 1 downto 0);
    signal r_axis_data_filtered     : std_logic_vector((g_data_width * 3) - 1 downto 0);

    -- FIFO REGISTERS
    signal r_fifo_full          : std_logic;
    signal r_fifo_write_enable  : std_logic := '0';
    signal r_fifo_read_enable   : std_logic := '0';
    signal r_axis_data_marked   : std_logic_vector((g_data_width + 16) - 1 downto 0);
    signal r_axis_data_fifo_out : std_logic_vector((g_data_width + 16) - 1 downto 0);

    -- UART REGISTERS
    signal r_uart_enable   : std_logic;
    signal r_transmit_data : std_logic_vector(g_data_width - 1 downto 0);

    -- FIR FILTER ENABLE AND DATA VALID
    signal r_fir_enable : std_logic_vector(17 downto 0) := (others => '0');
    signal r_fir_dv     : std_logic_vector(17 downto 0) := (others => '0');

    signal r_sdio : std_logic_vector(17 downto 0);

    signal r_enable : std_logic := '1';

    signal r_rst_n     : std_logic;

    -- INTERNAL OSCILLATOR
    component Gowin_OSC
        port (
            oscout : out std_logic
        );
    end component;
    component Gowin_CLKDIV
        port (
            clkout: out std_logic;
            hclkin: in std_logic;
            resetn: in std_logic
        );
    end component;
    signal clk : std_logic;
    signal clk_divided : std_logic;

    component FIFO_HS_Top
        port (
            Data  : in std_logic_vector(31 downto 0);
            WrClk : in std_logic;
            RdClk : in std_logic;
            WrEn  : in std_logic;
            RdEn  : in std_logic;
            Q     : out std_logic_vector(31 downto 0);
            Empty : out std_logic;
            Full  : out std_logic
        );
    end component;

begin -- BEGIN !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    r_rst_n    <= not i_rst;
    o_sclk      <= r_sclk;
    o_cs        <= r_cs;
    sdio        <= r_sdio(0);
    o_debug_led <= r_uart_enable;

    OSC_120MHz : Gowin_OSC
    port map(
        oscout => clk
    );
    Clock_divider : Gowin_CLKDIV
    port map (
        clkout => clk_divided,
        hclkin => clk,
        resetn => open
    );

    --! 
    SPI_INST : entity spi_top
        generic map(
            g_clk_freq  => c_CLK_FREQ,
            g_sclk_freq => c_SCLK_FREQ)
        port map(
            i_clk   => clk_divided,
            data_io => r_sdio,
            --  i_rst        => r_button,
            i_rst     => r_enable,
            o_cs         => r_cs,
            o_sclk       => r_sclk,
            o_data       => r_axis_data_non_filtered,
            o_data_debug => open,
            o_spi_dv     => r_spi_dv,
            o_fir_enable => r_fir_enable
        );

    -- --! Filter
    -- e_FIR_filter : entity FIR_filter
    --     port map(
    --         i_clk  => clk,
    --         i_data => r_axis_data_non_filtered,
    --         i_en   => r_fir_enable(0),
    --         o_data => r_axis_data_filtered,
    --         o_DV   => r_fir_dv(0)
    --     );

    --! writes filtered data/non-filtered data to fifo
    e_data_forward : entity data_forward
        port map(
            i_clk => clk_divided,
            -- i_en_arr        : in t_fir_enable_array,
            i_en => r_fir_enable(0),
            -- i_en => r_fir_dv(0),
            i_data => r_axis_data_non_filtered,
            -- i_data        => r_axis_data_filtered,
            o_data        => r_axis_data_marked,
            o_fifo_enable => r_fifo_write_enable
        );

    --! Gowin Premade fifo
    e_FIFO_top : FIFO_HS_Top
    port map(
        Data  => r_axis_data_marked,
        WrClk => clk_divided,
        RdClk => clk_divided,
        WrEn  => r_fifo_write_enable,
        RdEn  => r_fifo_read_enable,
        Q     => r_axis_data_fifo_out,
        Empty => r_uart_enable,
        Full  => r_fifo_full
    );

    --! UART TOP
    UART_INST : entity uart_top
        generic map(
            g_clk_freq     => c_CLK_FREQ,
            g_clks_per_bit => c_CLKS_PER_BIT)
        port map(
            i_clk => clk_divided,
            -- i_we => r_out_button,
            -- i_we => r_fir_dv(0),
            i_we      => r_uart_enable,
            o_fifo_re => r_fifo_read_enable,
            -- o_fifo_re => open,
            -- i_data => r_axis_data_filtered(23 downto 0),
            i_data => r_axis_data_fifo_out,
            -- i_data => r_axis_data_non_filtered(23 downto 0),
            -- i_data => open,
            o_DV => open,
            -- RX/TX
            i_RX => i_RX,
            o_TX => o_TX
        );

    -- test_write : process(clk) is
    -- begin
    --     if rising_edge(clk) then

    --         case r_button_ctrl is

    --             when s_button_idle =>
    --                 r_out_button <= '0';
    --                 if (r_button = '1') then
    --                     r_button_ctrl <= s_button_pressed;
    --                 else
    --                     r_button_ctrl <= s_button_idle;
    --                 end if;

    --             when s_button_pressed =>
    --                 r_out_button <= '1';
    --                 r_button_ctrl <= s_button_held;

    --             when s_button_held => 
    --                 r_out_button <= '0';
    --                 if (r_button = '1') then
    --                     r_button_ctrl <= s_button_held;
    --                 else
    --                     r_button_ctrl <= s_button_idle;
    --                 end if;

    --             when others =>
    --                 r_button_ctrl <= s_button_idle;

    --         end case;
    --     end if;
    -- end process test_write;

end architecture top;