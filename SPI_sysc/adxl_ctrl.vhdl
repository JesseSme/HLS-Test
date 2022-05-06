library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity adxl_ctrl is
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
end entity adxl_ctrl;


architecture rtl of adxl_ctrl is

    type t_data_xyz is array (0 to 5) of std_logic_vector(7 downto 0);
    signal s_data_xyz : t_data_xyz;

    type t_ctrl_state is (s_booting, s_configure, s_fetch_data, s_combine);
    signal s_ctrl_state : t_ctrl_state := s_booting;

    -- Data locations
    -- Read or write bits
    type t_rw : is array (0 to 1) of std_logic_vector(1 downto 0);
    constant c_rw : t_rw := ("00", "01"); -- 00 = write, 01 = read

    constant c_





    function reverseStd_logic_vector(toVec : std_logic_vector(0 to 5))
        return std_logic_vector(5 downto 0) is

        variable tmp : std_logic_vector(5 downto 0);
    begin



    end function;


begin

end architecture rtl;