library ieee;
use IEEE.std_logic_1164.all;

use work.adxl_addresses.all;
use work.spi_cs_generator;
use work.spi_sclk_generator;
use work.spi_sdio;

entity spi_top is
    generic (
        g_clk_freq : integer := 120_000_000;
        g_sclk_freq : integer := 1_000_000;
        g_data_width : integer := 16;
        g_full_data_width : integer := g_data_width*3
    );
    port (
        -- CLK
        i_clk : in std_logic;
        -- BUTTON TO MANUALLY ENABLE SPI
        i_button : in std_logic;
        -- SPI PINS
        data_io : inout std_logic_vector(17 downto 0);
        o_cs : out std_logic;
        o_sclk : out std_logic;
        -- SINGLE AXIS DATA OUT
        o_data : out std_logic_vector(g_full_data_width-1 downto 0);
        o_data_debug : out std_logic_vector((g_data_width/2)-1 downto 0);
        -- DATA VALID
        o_spi_dv : out std_logic_vector(17 downto 0);
        o_fir_enable : out std_logic_vector(17 downto 0)
    );
end entity;

architecture structural of spi_top is

    type t_ctrl_state is (s_read_devid,
                        s_write_power_ctl, 
                        s_read_power_ctl,
                        s_write_data_format_reg,
                        s_read_data_format_reg,
                        s_write_bw_rate_reg,
                        s_read_bw_rate_reg,
                        s_write_init_power_ctl,
                        s_read_x0,
                        s_read_x1,
                        s_read_y0,
                        s_read_y1,
                        s_read_z0,
                        s_read_z1,
                        s_activate_fir);
    -- State machine 
    signal s_ctrl_state : t_ctrl_state := s_write_init_power_ctl;

    type t_received_data_array is array (17 downto 0) of std_logic_vector(7 downto 0);

    -- Oscillator clock 120/60/30MHz
    signal clk : std_logic;

    -- DATA TO SEND
    signal r_transmit_data : std_logic_vector(g_data_width-1 downto 0) := (others => '0');

    -- SETTINGS
    signal r_power_ctl_settings : std_logic_vector(7 downto 0) := "01000011";

    -- ALL 3 AXIS JUST IN CASE
    signal r_full_data : std_logic_vector((3*g_data_width)-1 downto 0) := (others => '0');

    -- SINGLE AXIS
    signal r_single_axis_data : std_logic_vector(g_data_width-1 downto 0) := (others => '0');
    signal r_data_axis : std_logic_vector(2 downto 0) := "000";

    -- DATA RECEIVED FROM SDIO
    -- signal r_received_data : t_received_data_array;
    signal r_received_data : std_logic_vector(7 downto 0);
    signal r_padding : std_logic_vector(7 downto 0) := "10000101";

    -- DATA VALID FOR CS
    -- signal r_spi_dv_vector : std_logic_vector(17 downto 0);
    signal r_spi_dv : std_logic_vector(17 downto 0) := (others => '0');
    signal r_fir_enable : std_logic_vector(17 downto 0) := (others => '0');

    -- ENABLE REGISTER FOR CS
    signal r_we : std_logic := '1';
    signal r_cs : std_logic;
    signal r_sclk : std_logic;

    -- FOR MANUAL ENABLING
    signal r_button : std_logic := '0';

    procedure waitNextState (
        -- Enable
        signal enable       : in std_logic;
        -- Control
        signal control      : out t_ctrl_state;
        constant next_state   : in t_ctrl_state;
        constant old_state    : in t_ctrl_state) is
    begin
        if enable = '1' then
            control <= next_state;
        else
            control <= old_state;
        end if;
    end procedure;

begin

    clk <= i_clk;

    o_sclk <= r_sclk;
    o_cs <= r_cs;
    -- r_cs <= i_cs;

    -- r_transmit_data <= i_data_transmit;
    -- o_cs <= r_cs when r_button = '1' else '1';

    o_data_debug <= r_received_data;
    -- o_data <= r_single_axis_data;
    o_data <= r_full_data;
    -- o_data <= r_padding & r_received_data;
    o_spi_dv <= r_spi_dv;
    o_fir_enable <= r_fir_enable;


    CS_gen : entity spi_cs_generator
        generic map (
            g_clk_freq => g_clk_freq
            )
        port map (
            i_clk => clk,
            i_done => r_spi_dv(0),
            i_we => r_button, -- r_we or r_button
            o_cs => r_cs);

    SCLK_gen : entity spi_sclk_generator
        generic map (
            g_clk_freq => g_clk_freq,
            g_sclk_freq => g_sclk_freq
            )
        port map (
            i_clk => clk,
            i_cs => r_cs,
            o_sclk => r_sclk);

    -- TODO:  Add generate for multiple pins
    -- TODO: This shouldnt be duplicated. Instead the pins inside SPI_SDIO should be duplicated
    -- GEN_SPI_PINS : for i in 0 to 17 generate
        SPI_data : entity spi_sdio
            generic map (
                g_clk_freq => g_clk_freq,
                g_sclk_freq => g_sclk_freq
                )
            port map (
                i_clk => clk,
                i_cs => r_cs,
                io_pin => data_io(0),
                i_data_transmit => r_transmit_data,
                o_data_received => r_received_data,
                o_spi_dv => r_spi_dv(0)
                );
    -- end generate;

    -- A button debouncer
    process (clk)
        variable v_button_counter : integer range 0 to 1000 := 0;
    begin
        if rising_edge(clk) then
            if i_button = '1' then
                if v_button_counter = 1000 then
                    r_button <= '1';
                else
                    v_button_counter := v_button_counter + 1;
                end if;
            else
                -- s_ctrl_state <= s_write_data_format_reg;
                v_button_counter := 0;
                r_button <= '0';
            end if;
        end if;
    end process;


    -- Process that reads the accelerators acceleration registers
    -- TODO: Add a delay to stall the reading of received data.
    p_data_ctrl : process (i_clk)
        variable startup_sleep_counter : integer range 0 to g_clk_freq;
    begin
        if r_button = '0' then
            s_ctrl_state <= s_write_init_power_ctl;
        elsif rising_edge(i_clk) then

            case s_ctrl_state is

                -- Configure and read devid before 
                -- setting ADXL to measurement mode
                -- via POWER_CTL register

                -- Configuration and bidir pin verification
                when s_write_init_power_ctl =>
                    if startup_sleep_counter = g_clk_freq then
                        s_ctrl_state <= s_write_data_format_reg;
                    else
                        s_ctrl_state <= s_write_init_power_ctl;
                        startup_sleep_counter := startup_sleep_counter + 1;
                    end if;
                    -- s_ctrl_state <= s_write_data_format_reg;

                when s_write_data_format_reg => 
                    r_transmit_data <= setWriteVector(c_WRITE, c_DATA_FORMAT_RW, "01000010");
                    waitNextState(r_spi_dv(0), s_ctrl_state, s_read_data_format_reg, s_write_data_format_reg);
                    -- s_ctrl_state <= s_read_data_format_reg;


                when s_read_data_format_reg =>
                    r_transmit_data <= setWriteVector(c_READ, c_DATA_FORMAT_RW, "00000000");

                    if r_spi_dv(0) = '1' then
                        if r_received_data = "01000010" then
                            -- s_ctrl_state <= s_read_data_format_reg;
                            s_ctrl_state <= s_write_bw_rate_reg;
                        else
                            s_ctrl_state <= s_read_data_format_reg;
                        end if;
                    else
                        s_ctrl_state <= s_read_data_format_reg;
                    end if;
                            

                when s_write_bw_rate_reg =>
                    r_transmit_data <= setWriteVector(c_WRITE, c_BW_RATE_RW, "00110000");
                    waitNextState(r_spi_dv(0), s_ctrl_state, s_read_bw_rate_reg, s_write_bw_rate_reg);
                    -- s_ctrl_state <= s_read_bw_rate_reg;

                when s_read_bw_rate_reg =>
                    r_transmit_data <= setWriteVector(c_READ, c_BW_RATE_RW, "00000000");
                    if r_spi_dv(0) = '1' then
                        if r_received_data = "00110000" then
                            -- s_ctrl_state <= s_read_bw_rate_reg;
                            s_ctrl_state <= s_read_devid;
                        else
                            s_ctrl_state <= s_read_bw_rate_reg;
                        end if;
                    else
                        s_ctrl_state <= s_read_bw_rate_reg;
                    end if;



                when s_read_devid =>
                    r_transmit_data <= setWriteVector(c_READ, c_DEVID_R, "00000000");
                    
                    if r_spi_dv(0) = '1'then
                        if r_received_data = "10100111" then
                            s_ctrl_state <= s_write_power_ctl;
                            -- s_ctrl_state <= s_read_devid;
                            -- s_ctrl_state <= s_read_x0;
                        else
                            s_ctrl_state <= s_read_devid;
                        end if;
                    else
                        s_ctrl_state <= s_read_devid;
                    end if;

                when s_write_power_ctl => 
                    r_transmit_data <= setWriteVector(c_WRITE, c_POWER_CTL_RW, "00010000");
                    waitNextState(r_spi_dv(0), s_ctrl_state, s_read_power_ctl, s_write_power_ctl);
                    -- s_ctrl_state <= s_read_power_ctl;

                when s_read_power_ctl =>
                    r_transmit_data <= setWriteVector(c_READ, c_POWER_CTL_RW, "00000000");
                    if r_spi_dv(0) = '1' then
                        if r_received_data = "00010000" then
                            -- s_ctrl_state <= s_read_power_ctl;
                            s_ctrl_state <= s_read_x0;
                        else
                            s_ctrl_state <= s_write_power_ctl;
                        end if;
                    else
                        s_ctrl_state <= s_read_power_ctl;
                    end if;

                -- Read loop
                -- X-AXIS!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                when s_read_x0 =>
                    
                    r_transmit_data <= setWriteVector(c_READ, c_DATA_X0_R, "00000000");
                    r_fir_enable(0) <= '0';
                    
                    if r_spi_dv(0) = '1' then
                        r_full_data((g_data_width/2)-1 downto 0) <= flipStdVector(r_received_data); -- 7 downto 0
                        -- r_full_data((g_data_width/2)-1 downto 0) <= r_received_data(0) &r_received_data(1) &r_received_data(2) &r_received_data(3) &r_received_data(4) &r_received_data(5) &r_received_data(6) &r_received_data(7); -- 7 downto 0
                        s_ctrl_state <= s_read_x1;
                        -- s_ctrl_state <= s_read_x0;
                    else
                        s_ctrl_state <= s_read_x0;
                    end if;
                    
                when s_read_x1 =>
                    r_transmit_data <= setWriteVector(c_READ, c_DATA_X1_R, "00000000");
                    r_fir_enable(0) <= '0';

                    if r_spi_dv(0) = '1' then
                        r_full_data(g_data_width-1 downto (g_data_width/2)) <= flipStdVector(r_received_data); -- 15 downto 8
                        -- r_full_data(g_data_width-1 downto g_data_width/2) <= r_received_data(0) &r_received_data(1) &r_received_data(2) &r_received_data(3) &r_received_data(4) &r_received_data(5) &r_received_data(6) &r_received_data(7); -- 15 downto 8
                        -- s_ctrl_state <= s_read_x0;
                        s_ctrl_state <= s_read_y0;
                    else
                        s_ctrl_state <= s_read_x1;
                    end if;


                -- Y-AXIS!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                when s_read_y0 =>
                    r_transmit_data <= setWriteVector(c_READ, c_DATA_Y0_R, "00000000");
                    r_fir_enable(0) <= '0';

                    if r_spi_dv(0) = '1' then
                        r_full_data((g_data_width+(g_data_width/2)-1) -- 23
                                    downto 
                                    g_data_width) -- 16
                                    <= flipStdVector(r_received_data);
                        s_ctrl_state <= s_read_y1;
                    else
                        s_ctrl_state <= s_read_y0;
                    end if;

                when s_read_y1 =>
                    r_transmit_data <= setWriteVector(c_READ, c_DATA_Y1_R, "00000000");
                    r_fir_enable(0) <= '0';
                    if r_spi_dv(0) = '1' then
                        r_full_data((g_data_width*2)-1 -- 31
                                    downto 
                                    g_data_width+(g_data_width/2)) -- 24
                                    <= flipStdVector(r_received_data);
                        s_ctrl_state <= s_read_z0;
                    else
                        s_ctrl_state <= s_read_y1;
                    end if;

                -- Z-AXIS!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                when s_read_z0 =>
                    r_transmit_data <= setWriteVector(c_READ, c_DATA_Z0_R, "00000000");
                    r_fir_enable(0) <= '0';

                    if r_spi_dv(0) = '1' then
                        r_full_data(((g_data_width*2)+(g_data_width/2)-1) -- 39
                                    downto 
                                    g_data_width*2) -- 32
                                    <= flipStdVector(r_received_data);
                        s_ctrl_state <= s_read_z1;
                    else
                        s_ctrl_state <= s_read_z0;
                    end if;

                when s_read_z1 =>
                    r_transmit_data <= setWriteVector(c_READ, c_DATA_Z1_R, "00000000");
                    r_fir_enable(0) <= '0';
                    if r_spi_dv(0) = '1' then
                        r_full_data((g_data_width*3)-1 -- 47
                                    downto 
                                    g_data_width*2+(g_data_width/2)) -- 40
                                    <= flipStdVector(r_received_data);
                        s_ctrl_state <= s_activate_fir;
                    else
                        s_ctrl_state <= s_read_z1;
                    end if;

                when s_activate_fir =>
                    r_fir_enable(0) <= '1';
                    s_ctrl_state <= s_read_x0;


            end case;
        end if;
    end process p_data_ctrl;

end architecture;