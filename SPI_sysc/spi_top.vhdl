library ieee;
use IEEE.std_logic_1164.all;
use work.all;

entity spi_top is
    generic (
        g_clk_freq : integer := 120_000_000;
        g_sclk_freq : integer := 1_000_000;
        g_data_width : integer := 16
    );
    port (
        i_clk : in std_logic;
        data_io : inout std_logic;
        o_sclk : out std_logic;
        o_cs : out std_logic;
        o_data : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of spi_top is

    -- Oscillator clock 120MHz
    signal clk : std_logic;
    
    -- SCLK clock
    signal sclk : std_logic;

    signal test_data : std_logic_vector(15 downto 0) := x"0001";
    -- signal test_data : std_logic_vector(15 downto 0) := x"006D";
    -- signal test_data : std_logic_vector(15 downto 0) := x"006C";
    -- signal test_data : std_logic_vector(15 downto 0) := x"8F55";
    -- signal test_data : std_logic_vector(15 downto 0) := x"028D";
    signal out_data : std_logic_vector(7 downto 0);
    signal out_test_counter : integer;
    signal r_done : std_logic;
    signal s_we : std_logic;
    signal s_cs : std_logic := '1';

    signal s_bidir_inp : std_logic;
    signal s_bidir_outp : std_logic := '0';
    signal s_inp : std_logic;
    signal s_outp : std_logic;

    -- component Gowin_OSC
    --     port (
    --         oscout: out std_logic
    --     );
    -- end component;

begin

    o_sclk <= sclk;
    -- s_inp <= s_bidir_inp;
    -- s_bidir_outp <= s_outp;
    o_cs <= s_cs;

    o_data <= out_data;
    
    -- OSC_120MHz: Gowin_OSC
    -- port map (
    --     oscout => clk);
    clk <= i_clk;


    SCLK_Gen : entity spi_sclk_generator
        generic map (
            g_clk_freq => g_clk_freq,
            g_sclk_freq => g_sclk_freq
            )
        port map (
            i_clk => clk,
            i_cs => s_cs,
            o_sclk => sclk);

    CS_gen : entity spi_cs_generator
        generic map (
            g_clk_freq => g_clk_freq
            )
        port map (
            i_clk => clk,
            i_done => r_done,
            o_cs => s_cs);

    SPI_data : entity spi_sdio
        generic map (
            g_clk_freq => g_clk_freq,
            g_sclk_freq => g_sclk_freq
            )
        port map (
            i_clk => clk,
            i_cs => s_cs,
            i_data => test_data(15 downto 0),
            o_data => out_data,
            o_bit_out => s_bidir_outp,
            i_bit_in => s_bidir_inp,
            o_test_counter => open,
            o_we => s_we,
            o_done => r_done
            );

    data_pin : entity bidir
        port map (
            wr_en => s_we,
            data_io => data_io,
            inp => s_bidir_inp,
            outp => s_bidir_outp);

end architecture;