library ieee;
use ieee.std_logic_1164.all;

library work;

package adxl_addresses is

    type t_fir_enable is array (17 downto 0) of std_logic;

    type t_axis_data_array is array (17 downto 0) of std_logic_vector(47 downto 0);

    constant c_read  : std_logic_vector(1 downto 0) := "01";
    constant c_write : std_logic_vector(1 downto 0) := "00";

    --! Device ID
    constant c_devid_r : std_logic_vector(0 to 5) := "000000";

    --! Tap threshold
    constant c_thresh_tap_rw   : std_logic_vector(0 to 5)     := "101110";
    constant c_thresh_tap_data : std_logic_vector(7 downto 0) := "00000000";

    --! Offset registers
    -- vsg_disable_next_line constant_001
    constant c_offset_x_rw   : std_logic_vector(0 to 5)     := "011110";
    constant c_offset_y_rw   : std_logic_vector(0 to 5)     := "111110";
    constant c_offset_z_rw   : std_logic_vector(0 to 5)     := "000001";
    constant c_offset_x_data : std_logic_vector(7 downto 0) := "00000000";
    constant c_offset_y_data : std_logic_vector(7 downto 0) := "00000000";
    constant c_offset_z_data : std_logic_vector(7 downto 0) := "00000000";

    --! ???
    constant c_dur_rw   : std_logic_vector(0 to 5)     := "100001";
    constant c_dur_data : std_logic_vector(7 downto 0) := "00000000";

    --! Latent
    constant c_latent_rw : std_logic_vector(0 to 5) := "010001";

    --! Window
    constant c_window_rw : std_logic_vector(0 to 5) := "110001";

    --! Activation time
    constant c_thresh_act_rw     : std_logic_vector(0 to 5) := "001001";
    constant c_thresh_inact_rw   : std_logic_vector(0 to 5) := "101001";
    constant c_time_inact_rw     : std_logic_vector(0 to 5) := "011001";
    constant c_act_inact_ctl_rw  : std_logic_vector(0 to 5) := "111001";
    constant c_thresh_ff_rw      : std_logic_vector(0 to 5) := "000101";
    constant c_time_ff_rw        : std_logic_vector(0 to 5) := "101001";
    constant c_tap_axes_rw       : std_logic_vector(0 to 5) := "010101";
    constant c_act_tap_status_rw : std_logic_vector(0 to 5) := "110101";
    constant c_bw_rate_rw        : std_logic_vector(0 to 5) := "001101";
    constant c_power_ctl_rw      : std_logic_vector(0 to 5) := "101101";
    constant c_int_enable_rw     : std_logic_vector(0 to 5) := "011101";
    constant c_int_map_rw        : std_logic_vector(0 to 5) := "111101";
    constant c_int_source_r      : std_logic_vector(0 to 5) := "000011";
    constant c_data_format_rw    : std_logic_vector(0 to 5) := "100011";

    constant c_data_x0_r : std_logic_vector(0 to 5) := "010011";
    constant c_data_x1_r : std_logic_vector(0 to 5) := "110011";
    constant c_data_y0_r : std_logic_vector(0 to 5) := "001011";
    constant c_data_y1_r : std_logic_vector(0 to 5) := "101011";
    constant c_data_z0_r : std_logic_vector(0 to 5) := "011011";
    constant c_data_z1_r : std_logic_vector(0 to 5) := "111011";

    constant c_fifo_ctl_rw   : std_logic_vector(0 to 5) := "000111";
    constant c_fifo_status_r : std_logic_vector(0 to 5) := "100111";

    function setwritevector (
        rw      : std_logic_vector(1 downto 0);
        address : std_logic_vector(5 downto 0);
        data    : std_logic_vector(7 downto 0)
    ) return std_logic_vector;

    function flipstdvector (data_in : std_logic_vector(7 downto 0)
    ) return std_logic_vector;

end package adxl_addresses;

package body adxl_addresses is

    function setwritevector (
        rw      : std_logic_vector(1 downto 0);
        address : std_logic_vector(5 downto 0);
        data    : std_logic_vector(7 downto 0))
        return std_logic_vector is

        variable tmp : std_logic_vector(15 downto 0) := (others => '0');

    begin

        tmp(15 downto 0) := data & address & rw;
        return tmp;

    end function;

    function flipstdvector (data_in : std_logic_vector(7 downto 0))
        return std_logic_vector is
    begin

        return data_in(0) & data_in(1) & data_in(2) & data_in(3) &
        data_in(4) & data_in(5) & data_in(6) & data_in(7);

    end function;

end package body adxl_addresses;