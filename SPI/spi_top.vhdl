library ieee;
use IEEE.std_logic_1164.all;

library work;
use work.all;
use work.adxl_addresses.all;

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

    type t_ctrl_state is (s_read_devid,
                        s_write_power_ctl, 
                        s_write_data_format_reg, 
                        s_write_bw_rate_reg, 
                        s_read_x0,
                        s_read_x1,
                        s_read_y0,
                        s_read_y1,
                        s_read_z0,
                        s_read_z1);
    signal s_ctrl_state : t_ctrl_state := s_write_power_ctl;

    -- Oscillator clock 120/60/30MHz
    signal clk : std_logic;
    
    -- SCLK clock
    signal sclk : std_logic;


    -- signal test_data : std_logic_vector(15 downto 0) := x"0001";
    -- signal test_data : std_logic_vector(15 downto 0) := x"006D";
    -- signal test_data : std_logic_vector(15 downto 0) := x"006C";
    -- signal test_data : std_logic_vector(15 downto 0) := x"8F55";
    -- signal test_data : std_logic_vector(15 downto 0) := x"028D";
    signal test_data : std_logic_vector(15 downto 0);
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

    -- component IOBUF
    --     port (
    --         O: out std_logic;
    --         IO: inout std_logic;
    --         I: in std_logic;
    --         OEN: in std_logic
    --     );
    -- end component;

begin

    -- test_data <= setWriteVector(c_READ, getAddress(c_DATA_X0_R), '0','0','0','0','0','0','0','0');

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


    p_data_ctrl : process (s_cs)
    begin
        if rising_edge(s_cs) then

            case s_ctrl_state is

                -- Configuration and bidir pin verification
                when s_write_power_ctl =>
                    test_data <= setWriteVector(c_WRITE,
                                             getAddress(c_POWER_CTL_RW),
                                              '0', '0', '0', '0', 
                                              '1', '0', '0', '0');
                    s_ctrl_state <= s_write_power_ctl;

                when s_write_data_format_reg => 
                    test_data <= setWriteVector(c_WRITE, 
                                            getAddress(c_DATA_FORMAT_RW),
                                            '1', '1', '0', '0',
                                            '0', '1', '0', '1');
                    s_ctrl_state <= s_write_bw_rate_reg;

                when s_write_bw_rate_reg =>
                    test_data <= setWriteVector(c_WRITE,
                                            getAddress(c_BW_RATE_RW),
                                            '0', '0', '0', '0',
                                            '1', '1', '1', '1');
                    s_ctrl_state <= s_read_devid;

                when s_read_devid =>
                    test_data <= setWriteVector(c_READ,
                                            getAddress(c_DEVID_R),
                                            '0', '0', '0', '0',
                                            '0', '0', '0', '0');
                    if out_data = "11100101" or out_data = "10100111" then
                        s_ctrl_state <= s_read_x0;
                    else
                        s_ctrl_state <= s_read_devid;
                    end if;

                -- Read loop
                when s_read_x0 =>
                    test_data <= setWriteVector(c_READ,
                                        getAddress(c_DATA_X0_R),
                                        '0', '0', '0', '0',
                                        '0', '0', '0', '0');
                when s_read_x1 =>
                    test_data <= setWriteVector(c_READ,
                                        getAddress(c_DATA_X1_R),
                                        '0', '0', '0', '0',
                                        '0', '0', '0', '0');

                when s_read_y0 =>
                    test_data <= setWriteVector(c_READ,
                                        getAddress(c_DATA_Y0_R),
                                        '0', '0', '0', '0',
                                        '0', '0', '0', '0');

                when s_read_y1 =>
                    test_data <= setWriteVector(c_READ,
                                    getAddress(c_DATA_Y1_R),
                                    '0', '0', '0', '0',
                                    '0', '0', '0', '0');

                when s_read_z0 =>
                    test_data <= setWriteVector(c_READ,
                                    getAddress(c_DATA_Z0_R),
                                    '0', '0', '0', '0',
                                    '0', '0', '0', '0');

                when s_read_z1 =>
                    test_data <= setWriteVector(c_READ,
                                    getAddress(c_DATA_Z1_R),
                                    '0', '0', '0', '0',
                                    '0', '0', '0', '0');



        end if;
    end process p_data_ctrl;

    -- uut:IOBUF
    --     port map (
    --         O => s_bidir_outp,
    --         IO => data_io,
    --         I => s_bidir_inp,
    --         OEN => s_we
    --         );

end architecture;