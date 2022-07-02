library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
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
        -- sdio : inout std_logic_vector(17 downto 0);
        sdio : inout std_logic;
        debug : out std_logic_vector(7 downto 0);
        o_sclk : out std_logic;
        o_cs : out std_logic
    );
end entity transmit_top;

architecture top of transmit_top is

    type t_passthrough_ctrl is (s_Idle, s_Start, s_Wait);
    signal r_passthrough_ctrl : t_passthrough_ctrl := s_Idle;

    type t_button_ctrl is (s_button_idle, s_button_pressed, s_button_held);
    signal r_button_ctrl : t_button_ctrl := s_button_idle;

    constant c_CLKS_PER_BIT : integer := 520;
    constant c_CLK_FREQ : integer := 120_000_000;
    constant c_SCLK_FREQ : integer := 2_000_000;



    signal r_button : std_logic;
    signal r_old_button : std_logic := '0';
    signal r_out_button : std_logic := '0';

    -- SPI PORTS
    signal r_sclk : std_logic := '1';
    signal r_cs : std_logic;
    signal r_spi_dv : std_logic_vector(17 downto 0) := (others => '0');

    -- ACCELEROMETER DATA
    signal r_axis_data_non_filtered : std_logic_vector(g_data_width-1 downto 0);
    signal r_axis_data_filtered : std_logic_vector(g_data_width-1 downto 0);

    -- UART DATA
    signal r_transmit_data : std_logic_vector(g_data_width-1 downto 0);
    
    -- FIR FILTER ENABLE AND DATA VALID
    signal r_fir_enable : std_logic_vector(17 downto 0) := (others => '0'); 
    signal r_fir_dv : std_logic_vector(17 downto 0) := (others => '0');

    signal r_debug : std_logic_vector(7 downto 0);

    signal r_sdio : std_logic_vector(17 downto 0);

    signal r_enable : std_logic := '1';

    -- INTERNAL OSCILLATOR
    component Gowin_OSC
        port (
            oscout: out std_logic
        );
    end component;
    signal clk : std_logic;

    -- component uart_top
    --     generic (
    --         g_clk_freq : integer := 120_000_000;
    --         g_clks_per_bit : integer := 1041; -- 115200 baud at 120MHz
    --         g_data_width : integer := 16
    --     );
    --     port (
    --         i_clk : in std_logic;
    --         i_we : in std_logic;
    --         i_data : in std_logic_vector(g_data_width-1 downto 0);
    --         o_DV : out std_logic;
    --         -- RX/TX
    --         i_RX : in std_logic;
    --         o_TX : out std_logic
    --     );
    -- end component;

    
begin

    r_button <= not i_button;
    o_sclk <= r_sclk;
    o_cs <= r_cs;
    sdio <= r_sdio(0);

    OSC_120MHz: Gowin_OSC
    port map (
        oscout => clk);


    SPI_INST : entity spi_top
        generic map (
            g_clk_freq => c_CLK_FREQ,
            g_sclk_freq => c_SCLK_FREQ)
        port map (
            i_clk => clk,
            data_io => r_sdio,
            i_button => r_button,
            o_cs => r_cs,
            o_sclk => r_sclk,
            o_data => r_axis_data_non_filtered,
            o_data_debug => r_debug,
            o_spi_dv => r_spi_dv,
            o_fir_dv => r_fir_enable);

    e_FIR_filter : entity FIR_filter
        port map (
            i_clk => clk,
            i_data => r_axis_data_non_filtered,
            i_en => r_fir_enable(0),
            i_cs => r_cs,
            o_data => r_axis_data_filtered,
            o_DV => r_fir_dv(0)
            );


    UART_INST : entity uart_top
        generic map ( 
            g_clk_freq => c_CLK_FREQ,
            g_clks_per_bit => c_CLKS_PER_BIT)
        port map (
            i_clk => clk,
            -- i_we => r_out_button,
            -- i_we => r_fir_enable(0),
            i_we => r_spi_dv(0),
            -- i_data => r_axis_data_filtered,
            i_data => r_axis_data_non_filtered,
            -- i_data => open,
            o_DV => open,
            -- RX/TX
            i_RX => i_RX,
            o_TX => o_TX);


    -- TODO: Create a method how to send data to the PC, maybe a FIFO?
    -- TODO: Need one for every axis of every accelerometer
    -- unless the old data is passed in with the new data.
    -- GEN_FIR_FILTER: for I in 0 to 2 generate
        -- FIRX : FIR_filter port map (
        --     i_clk => clk, 
        --     i_data => r_axis_data_non_filtered,
        --     -- i_en => r_axis_enable(I),
        --     i_en => r_axis_enable(0),
        --     o_data => r_axis_data_filtered,
        --     o_DV => open
        --     );
    -- end generate GEN_FIR_FILTER;

    
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

    -- test_write : process

end architecture structural;
