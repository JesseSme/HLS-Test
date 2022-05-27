library ieee;
use ieee.std_logic_1164.all;

package adxl_addresses is

    -- type t_adxl_data is std_logic_vector(15 downto 0);

    constant c_READ                 : std_logic_vector(1 downto 0) := "01";
    constant c_WRITE                : std_logic_vector(1 downto 0) := "00";

    -- Device ID
    constant c_DEVID_R              : std_logic_vector(0 to 5)  := "000000";
    constant c_THRESH_TAP_RW        : std_logic_vector(0 to 5)  := "101110";
    constant c_OFFSET_X_RW          : std_logic_vector(0 to 5)  := "011110";
    constant c_OFFSET_Y_RW          : std_logic_vector(0 to 5)  := "111110";
    constant c_OFFSET_Z_RW          : std_logic_vector(0 to 5)  := "000001";
    constant c_DUR_RW               : std_logic_vector(0 to 5)  := "100001";
    constant c_LATENT_RW            : std_logic_vector(0 to 5)  := "010001";
    constant c_WINDOW_RW            : std_logic_vector(0 to 5)  := "110001";
    constant c_THRESH_ACT_RW        : std_logic_vector(0 to 5)  := "001001"; -- All the above flipped
    constant c_THRESH_INACT_RW      : std_logic_vector(0 to 5)  := "101001";
    constant c_TIME_INACT_RW        : std_logic_vector(0 to 5)  := "011001";
    constant c_ACT_INACT_CTL_RW     : std_logic_vector(0 to 5)  := "111001";
    constant c_THRESH_FF_RW         : std_logic_vector(0 to 5)  := "000101";
    constant c_TIME_FF_RW           : std_logic_vector(0 to 5)  := "101001";
    constant c_TAP_AXES_RW          : std_logic_vector(0 to 5)  := "010101";
    constant c_ACT_TAP_STATUS_RW    : std_logic_vector(0 to 5)  := "110101";
    constant c_BW_RATE_RW           : std_logic_vector(0 to 5)  := "001101"; -- Flipped
    constant c_POWER_CTL_RW         : std_logic_vector(0 to 5)  := "101101"; 
    constant c_INT_ENABLE_RW        : std_logic_vector(0 to 5)  := "011101";
    constant c_INT_MAP_RW           : std_logic_vector(0 to 5)  := "111101";
    constant c_INT_SOURCE_R         : std_logic_vector(0 to 5)  := "000011";
    constant c_DATA_FORMAT_RW       : std_logic_vector(0 to 5)  := "100011"; -- Flipped
    
    constant c_DATA_X0_R            : std_logic_vector(0 to 5)  := "010011";
    constant c_DATA_X1_R            : std_logic_vector(0 to 5)  := "110011";
    constant c_DATA_Y0_R            : std_logic_vector(0 to 5)  := "001011";
    constant c_DATA_Y1_R            : std_logic_vector(0 to 5)  := "101011";
    constant c_DATA_Z0_R            : std_logic_vector(0 to 5)  := "011011";
    constant c_DATA_Z1_R            : std_logic_vector(0 to 5)  := "111011";

    function getAddress(address : std_logic_vector(0 to 5)) 
        return std_logic_vector;

    function setWriteVector(rw : std_logic_vector(1 downto 0);
                          address : std_logic_vector(5 downto 0);
                          data : std_logic_vector(7 downto 0))
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
                            data : std_logic_vector(7 downto 0))
        return std_logic_vector is

        variable tmp : std_logic_vector(15 downto 0) := (others => '0');
    begin
        tmp(15 downto 0)    := data & address & rw;
        return tmp;
    end function;
end package body adxl_addresses;