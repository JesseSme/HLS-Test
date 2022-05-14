library ieee;
use ieee.std_logic_1164.all;

package adxl_addresses is

    -- type t_adxl_data is std_logic_vector(15 downto 0);

    constant c_READ                 : std_logic_vector(1 downto 0) := "01";
    constant c_WRITE                : std_logic_vector(1 downto 0) := "00";

    -- Device ID
    constant c_DEVID_R              : std_logic_vector(0 to 5)  := "000000";
    constant c_THRESH_TAP_RW        : std_logic_vector(0 to 5)  := "011101";
    constant c_OFFSET_X_RW          : std_logic_vector(0 to 5)  := "011110";
    constant c_OFFSET_Y_RW          : std_logic_vector(0 to 5)  := "011111";
    constant c_OFFSET_Z_RW          : std_logic_vector(0 to 5)  := "100000";
    constant c_DUR_RW               : std_logic_vector(0 to 5)  := "100001";
    constant c_LATENT_RW            : std_logic_vector(0 to 5)  := "100010";
    constant c_WINDOW_RW            : std_logic_vector(0 to 5)  := "100011";
    constant c_THRESH_ACT_RW        : std_logic_vector(0 to 5)  := "100100";
    constant c_THRESH_INACT_RW      : std_logic_vector(0 to 5)  := "100101";
    constant c_TIME_INACT_RW        : std_logic_vector(0 to 5)  := "100110";
    constant c_ACT_INACT_CTL_RW     : std_logic_vector(0 to 5)  := "100111";
    constant c_THRESH_FF_RW         : std_logic_vector(0 to 5)  := "101000";
    constant c_TIME_FF_RW           : std_logic_vector(0 to 5)  := "101001";
    constant c_TAP_AXES_RW          : std_logic_vector(0 to 5)  := "101010";
    constant c_ACT_TAP_STATUS_RW    : std_logic_vector(0 to 5)  := "101011";
    constant c_BW_RATE_RW           : std_logic_vector(0 to 5)  := "101100";
    constant c_POWER_CTL_RW         : std_logic_vector(0 to 5)  := "101101";
    constant c_INT_ENABLE_RW        : std_logic_vector(0 to 5)  := "101110";
    constant c_INT_MAP_RW           : std_logic_vector(0 to 5)  := "101111";
    constant c_INT_SOURCE_R         : std_logic_vector(0 to 5)  := "110000";
    constant c_DATA_FORMAT_RW       : std_logic_vector(0 to 5)  := "110001";
    constant c_DATA_X0_R            : std_logic_vector(0 to 5)  := "110010";
    constant c_DATA_X1_R            : std_logic_vector(0 to 5)  := "110011";
    constant c_DATA_Y0_R            : std_logic_vector(0 to 5)  := "110100";
    constant c_DATA_Y1_R            : std_logic_vector(0 to 5)  := "110101";
    constant c_DATA_Z0_R            : std_logic_vector(0 to 5)  := "110110";
    constant c_DATA_Z1_R            : std_logic_vector(0 to 5)  := "110111";

    function getAddress(address : std_logic_vector(0 to 5)) 
        return std_logic_vector;

    function setWriteVector(rw : std_logic_vector(1 downto 0);
                          address : std_logic_vector(5 downto 0);
                          D7 : std_logic;
                          D6 : std_logic;
                          D5 : std_logic;
                          D4 : std_logic;
                          D3 : std_logic;
                          D2 : std_logic;
                          D1 : std_logic;
                          D0 : std_logic)
        return std_logic_vector;

end package adxl_addresses;



package body adxl_addresses is

    function getAddress(address : std_logic_vector(0 to 5)) 
        return std_logic_vector is
        variable tmp : std_logic_vector(5 downto 0);
    begin
        tmp := address;
        return tmp;
    end function;


    function setWriteVector(rw : std_logic_vector(1 downto 0);
                            address : std_logic_vector(5 downto 0);
                            D7 : std_logic;
                            D6 : std_logic;
                            D5 : std_logic;
                            D4 : std_logic;
                            D3 : std_logic;
                            D2 : std_logic;
                            D1 : std_logic;
                            D0 : std_logic)
        return std_logic_vector is

        variable tmp : std_logic_vector(15 downto 0) := (others => '0');
    begin
        tmp(15 downto 0)    := D7 & D6 & D5 & D4 & D3 & D2 & D1 & D0 & address & rw;
        return tmp;
    end function;
end package body adxl_addresses;