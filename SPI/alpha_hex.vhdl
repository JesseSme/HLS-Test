library ieee;
use IEEE.std_logic_1164.all;

package alpha_hex is

    constant c_A : std_logic_vector(7 downto 0) := "01000001";
    constant c_B : std_logic_vector(7 downto 0) := "01000010";
    constant c_C : std_logic_vector(7 downto 0):= "01000011";
    constant c_D : std_logic_vector(7 downto 0):= "01000100";
    constant c_E : std_logic_vector(7 downto 0) := "01000101";
    constant c_F : std_logic_vector(7 downto 0) := "01000110";
    constant c_G : std_logic_vector(7 downto 0) := "01000111";
    constant c_H : std_logic_vector(7 downto 0) := "01001000";
    constant c_I : std_logic_vector(7 downto 0) := "01001001";
    constant c_J : std_logic_vector(7 downto 0) := "01001010";
    constant c_K : std_logic_vector(7 downto 0) := "01001011";
    constant c_L : std_logic_vector(7 downto 0) := "01001100";
    constant c_M : std_logic_vector(7 downto 0) := "01001101";
    constant c_N : std_logic_vector(7 downto 0) := "01001110";
    constant c_O : std_logic_vector(7 downto 0) := "01001111";
    constant c_P : std_logic_vector(7 downto 0) := "01010000";
    constant c_Q : std_logic_vector(7 downto 0) := "01010001";
    constant c_R : std_logic_vector(7 downto 0) := "01010010";
    constant c_S : std_logic_vector(7 downto 0) := "01010011";
    constant c_T : std_logic_vector(7 downto 0) := "01010100";
    constant c_U : std_logic_vector(7 downto 0) := "01010101";
    constant c_V : std_logic_vector(7 downto 0) := "01010110";
    constant c_W : std_logic_vector(7 downto 0) := "01010111";
    constant c_X : std_logic_vector(7 downto 0) := "01011000";
    constant c_Y : std_logic_vector(7 downto 0) := "01011001";
    constant c_Z : std_logic_vector(7 downto 0) := "01011010";

    type c_ALPHABET is array(25 downto 0) of std_logic_vector(7 downto 0);

end package alpha_hex;