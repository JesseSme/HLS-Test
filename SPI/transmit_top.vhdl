library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.all;

entity transmit_top is
    generic (
        g_data_width : integer := 16
    );
    port (
        -- clk : in std_logic;
        rst_n : in std_logic;
        i_button : in std_logic;
        o_TX : out std_logic;
        i_RX : in std_logic;
        sdio : inout std_logic_vector(17 downto 0);
        o_sclk : out std_logic;
        o_cs : out std_logic
    );
end entity transmit_top;

architecture rtl of transmit_top is

    type t_passthrough_ctrl is (s_Idle, s_Start, s_Wait);
    signal r_passthrough_ctrl : t_passthrough_ctrl := s_Idle;

    type t_button_ctrl is (s_button_idle, s_button_pressed, s_button_held);
    signal r_button_ctrl : t_button_ctrl := s_button_idle;

    constant c_CLKS_PER_BIT : integer := 1041;
    constant c_CLK_FREQ : integer := 120_000_000;
    constant c_SCLK_FREQ : integer := 2_000_000;

    signal r_TX_DV     : std_logic                    := '0';
    signal r_TX_BYTE   : std_logic_vector(7 downto 0) := "10101010";
    signal w_TX_SERIAL : std_logic;
    signal w_TX_DONE   : std_logic;
    signal w_RX_DV     : std_logic;
    signal w_RX_BYTE   : std_logic_vector(7 downto 0);
    signal r_RX_SERIAL : std_logic;

    signal r_button : std_logic;
    signal r_old_button : std_logic := '0';
    signal r_out_button : std_logic := '0';

    signal w_SPI_BYTE : std_logic_vector(7 downto 0) := (others => '0');
    signal r_SDIO : std_logic;
    signal r_sclk : std_logic := '1';
    signal r_cs : std_logic;
    signal r_spi_dv : std_logic;

    signal r_axis_data_non_filtered : std_logic_vector(g_data_width-1 downto 0);
    signal r_axis_data_filtered : std_logic_vector(g_data_width-1 downto 0);
    signal r_axis_enable : std_logic_vector(2 downto 0);

    signal r_transmit_data : std_logic_vector(g_data_width-1 downto 0);
    

    component Gowin_OSC
        port (
            oscout: out std_logic
        );
    end component;
    signal clk : std_logic;

    component FIR_filter is
        port (
            i_clk : in std_logic;
            i_data : in std_logic_vector(g_data_width-1 downto 0);
            i_en : in std_logic;
            o_data : out std_logic_vector(g_data_width-1 downto 0);
            o_DV : out std_logic
            );
    end component;
    
begin

    OSC_120MHz: Gowin_OSC
    port map (
        oscout => clk);


    r_button <= '0' when not i_button else '1';

    o_sclk <= r_sclk;
    r_TX_DV <= r_out_button;
    -- r_TX_DV <= w_RX_DV;
    o_TX <= w_TX_Serial;
    r_RX_SERIAL <= i_RX;
    -- r_TX_BYTE <= w_RX_BYTE;
    r_TX_BYTE <= w_SPI_BYTE;

    -- Instantiate UART Receiver
    UART_RX_INST : entity uart_rx
        generic map (
            g_CLKS_PER_BIT => c_CLKS_PER_BIT
            )
        port map (
            i_clk       => clk,
            i_rx_serial => r_RX_SERIAL,
            o_rx_dv     => w_RX_DV,
            o_rx_byte   => w_RX_BYTE
            );


    -- Instantiate UART transmitter
    UART_TX_INST : entity uart_tx
        generic map (
            g_CLKS_PER_BIT => c_CLKS_PER_BIT
            )
        port map (
            i_clk       => clk,
            i_tx_dv     => r_TX_DV,
            i_tx_byte   => r_TX_BYTE,
            o_tx_active => open,
            o_tx_serial => w_TX_SERIAL,
            o_tx_done   => w_TX_DONE
            );


    CS_gen : entity spi_cs_generator
        generic map (
            g_clk_freq => c_clk_freq
            )
        port map (
            i_clk => clk,
            i_done => r_spi_dv,
            i_we => r_button,
            o_cs => r_cs);

    SCLK_gen : entity spi_sclk_generator
        generic map (
            g_clk_freq => c_clk_freq
            )
        port map (
            i_clk => clk,
            i_cs => r_cs,
            o_sclk => r_sclk);


    SPI_INST : entity spi_top
        generic map (
            g_clk_freq => c_CLK_FREQ,
            g_sclk_freq => c_SCLK_FREQ
            )
        port map (
            i_clk => clk,
            data_io => sdio,
            i_button => r_button,
            i_cs => r_cs,
            o_data => r_axis_data_non_filtered,
            o_data_axis =>  r_axis_enable,
            o_spi_dv => open
            );


    -- TODO: Create a method how to send data to the PC, maybe a FIFO?
    -- TODO: Need one for every axis of every accelerometer
    -- unless the old data is passed in with the new data.
    GEN_FIR_FILTER: for I in 0 to 2 generate
        FIRX : FIR_filter port map (
            i_clk => clk, 
            i_data => r_axis_data_non_filtered,
            i_en => r_axis_enable(I),
            o_data => r_axis_data_filtered,
            o_DV => open
            );
    end generate GEN_FIR_FILTER;

    
    test_write : process(clk) is
    begin
        if rising_edge(clk) then

            case r_button_ctrl is
                
                when s_button_idle =>
                    r_out_button <= '0';
                    if (r_button = '1') then
                        r_button_ctrl <= s_button_pressed;
                    else
                        r_button_ctrl <= s_button_idle;
                    end if;

                when s_button_pressed =>
                    r_out_button <= '1';
                    r_button_ctrl <= s_button_held;

                when s_button_held => 
                    r_out_button <= '0';
                    if (r_button = '1') then
                        r_button_ctrl <= s_button_held;
                    else
                        r_button_ctrl <= s_button_idle;
                    end if;
                
                when others =>
                    r_button_ctrl <= s_button_idle;

            end case;
        end if;
    end process test_write;

end architecture rtl;
