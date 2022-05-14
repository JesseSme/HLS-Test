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


begin

    

end architecture rtl;