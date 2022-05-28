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
        -- CLK
        i_clk : in std_logic;
        -- BUTTON TO MANUALLY ENABLE SPI
        i_button : in std_logic;
        -- SPI PINS
        data_io : inout std_logic_vector(17 downto 0);
        i_cs : in std_logic;
        -- SINGLE AXIS DATA OUT
        o_data : out std_logic_vector(g_data_width-1 downto 0);
        -- ENABLE VECTOR FOR FIR_FILTERS
        o_data_axis : out std_logic_vector(2 downto 0);
        -- DATA VALID
        o_spi_dv : out std_logic
    );
end entity;

architecture rtl of spi_top is

    type t_ctrl_state is (s_read_devid,
                        s_write_power_ctl, 
                        s_write_data_format_reg,
                        s_read_data_format_reg,
                        s_write_bw_rate_reg,
                        s_read_x0,
                        s_read_x1,
                        s_read_y0,
                        s_read_y1,
                        s_read_z0,
                        s_read_z1);
    signal s_ctrl_state : t_ctrl_state := s_write_data_format_reg;

    type t_received_data_array is array (17 downto 0) of std_logic_vector(7 downto 0);

    -- Oscillator clock 120/60/30MHz
    signal clk : std_logic;

    -- DATA TO SEND
    signal r_transmit_data : std_logic_vector(g_data_width-1 downto 0) := (others => '0');

    -- ALL 3 AXIS JUST IN CASE
    signal r_full_data : std_logic_vector((3*g_data_width)-1 downto 0) := (others => '0');

    -- SINGLE AXIS
    signal r_single_axis_data : std_logic_vector(g_data_width-1 downto 0) := (others => '0');
    signal r_data_axis : std_logic_vector(2 downto 0) := "000";

    -- DATA RECEIVED FROM SDIO
    signal r_received_data : t_received_data_array;

    -- DATA VALID FOR CS
    -- signal r_spi_dv_vector : std_logic_vector
    signal r_spi_dv : std_logic;

    -- ENABLE REGISTER FOR CS
    signal r_we : std_logic;
    signal r_cs : std_logic;

    signal r_button : std_logic := '0';

begin

    clk <= i_clk;

    r_cs <= i_cs;

    r_transmit_data <= i_data_transmit;
    -- o_cs <= r_cs when r_button = '1' else '1';

    o_data <= r_single_axis_data;
    o_data_axis <= r_data_axis;


    -- TODO: 
    SPI_data : entity spi_sdio
        generic map (
            g_clk_freq => g_clk_freq,
            g_sclk_freq => g_sclk_freq
            )
        port map (
            i_clk => clk,
            i_cs => r_cs,
            io_pin => data_io,
            i_data_transmit => r_transmit_data(15 downto 0),
            o_data_received => r_received_data,
            o_spi_dv => r_spi_dv
            );

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
    p_data_ctrl : process (r_cs)
        variable v_failed_to_read : integer range 0 to 5 := 0;
    begin
        if rising_edge(r_cs) then

            case s_ctrl_state is

                -- Configure and read devid before 
                -- setting ADXL to measurement mode
                -- via POWER_CTL register

                -- Configuration and bidir pin verification
                when s_write_data_format_reg => 
                    r_transmit_data <= setWriteVector(c_WRITE, 
                                            c_DATA_FORMAT_RW,
                                            "11000011");
                    s_ctrl_state <= s_read_data_format_reg;

                when s_read_data_format_reg =>
                    r_transmit_data <= setWriteVector(c_READ,
                                        c_DATA_FORMAT_RW,
                                        "00000000");
                    if r_received_data = "11000011" or r_received_data = "11000011" then
                        s_ctrl_state <= s_write_bw_rate_reg;
                    else
                        if v_failed_to_read = 5 then
                            v_failed_to_read := 0;
                            s_ctrl_state <= s_write_data_format_reg;
                        else 
                            v_failed_to_read := v_failed_to_read + 1;
                        end if;
                    end if;
                            

                when s_write_bw_rate_reg =>
                    r_transmit_data <= setWriteVector(c_WRITE,
                                            c_BW_RATE_RW,
                                            "11110000");
                    s_ctrl_state <= s_read_devid;

                when s_read_devid =>
                    r_transmit_data <= setWriteVector(c_READ,
                                            c_DEVID_R,
                                            "00000000");
                    if r_received_data(0) = "11100101" or r_received_data(0) = "10100111" then
                        s_ctrl_state <= s_write_power_ctl;
                        -- s_ctrl_state <= s_read_devid;
                        -- s_ctrl_state <= s_read_x0;
                    else
                        s_ctrl_state <= s_read_devid;
                    end if;

                when s_write_power_ctl => 
                    r_transmit_data <= setWriteVector(c_WRITE,
                                            c_POWER_CTL_RW,
                                            "00010000");
                    s_ctrl_state <= s_read_x0;

                -- Read loop
                -- X-AXIS
                when s_read_x0 =>
                    r_transmit_data <= setWriteVector(c_READ,
                                        c_DATA_X0_R,
                                        "00000000");
                    r_single_axis_data <= r_single_axis_data(g_data_width-1 downto g_data_width) & r_received_data;
                    
                    -- s_ctrl_state <= s_read_x1;
                    
                when s_read_x1 =>
                    r_transmit_data <= setWriteVector(c_READ,
                                        c_DATA_X1_R,
                                        "00000000");
                    r_single_axis_data <= r_received_data & r_single_axis_data((g_data_width/2)-1 downto 0);
                    r_data_axis <= "001";
                    s_ctrl_state <= s_read_y0;

                -- Y-AXIS
                when s_read_y0 =>
                    r_transmit_data <= setWriteVector(c_READ,
                                        c_DATA_Y0_R,
                                        "00000000");
                    r_single_axis_data <= r_single_axis_data(g_data_width-1 downto g_data_width) & r_received_data;
                    s_ctrl_state <= s_read_y1;

                when s_read_y1 =>
                    r_transmit_data <= setWriteVector(c_READ,
                                    c_DATA_Y1_R,
                                    "00000000");
                    r_single_axis_data <= r_received_data & r_single_axis_data((g_data_width/2)-1 downto 0);
                    r_data_axis <= "010";
                    s_ctrl_state <= s_read_z0;

                -- Z-AXIS
                when s_read_z0 =>
                    r_transmit_data <= setWriteVector(c_READ,
                                    c_DATA_Z0_R,
                                    "00000000");
                    r_single_axis_data <= r_single_axis_data(g_data_width-1 downto g_data_width) & r_received_data;
                    s_ctrl_state <= s_read_z1;

                when s_read_z1 =>
                    r_transmit_data <= setWriteVector(c_READ,
                                    c_DATA_Z1_R,
                                    "00000000");
                    r_single_axis_data <= r_received_data & r_single_axis_data((g_data_width/2)-1 downto 0);
                    r_data_axis <= "100";
                    s_ctrl_state <= s_read_x0;


            end case;
        end if;
    end process p_data_ctrl;

end architecture;