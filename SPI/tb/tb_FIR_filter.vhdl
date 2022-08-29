library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

use work.FIR_filter;

entity tb_FIR_filter is
end entity tb_FIR_filter;

architecture tb of tb_FIR_filter is

    -- FIR_Filter constants
    constant c_data_width        : integer := 16;
    constant c_filter_data_width : integer := c_data_width + 8;
    constant c_result_data_width : integer := (c_filter_data_width * 2);
    constant c_full_data_width   : integer := c_data_width * 3;

    -- Constants
    constant c_clk_period : time := 10 ns;

    -- TB Control Signals
    signal tb_clk_ctrl : std_logic := '0';

    signal clk : std_logic := '0';

    file input_data : text;
    file ref_data   : text;

    signal r_data_to_duv   : std_logic_vector(c_full_data_width - 1 downto 0) := (others => '0');
    signal r_data_from_duv : std_logic_vector(c_full_data_width - 1 downto 0) := (others => '0');

    signal r_en     : std_logic := '0';
    signal r_DUV_DV : std_logic;

begin

    DUV : entity FIR_filter
        generic map(
            g_data_width => c_data_width
        )
        port map(
            i_clk  => clk,
            i_en   => r_en,
            i_data => r_data_to_duv,
            o_data => r_data_from_duv,
            o_DV   => r_DUV_DV);

    p_clk : process
    begin
        clk <= '0';
        wait for c_clk_period;
        clk <= '1';
        wait for c_clk_period;

    end process;

    p_test : process
        variable v_DATA_LINE : line;
        variable v_SPACE : character;
        variable v_X_DUV_INPUT : std_logic_vector(c_data_width - 1 downto 0);
        variable v_Y_DUV_INPUT : std_logic_vector(c_data_width - 1 downto 0);
        variable v_Z_DUV_INPUT : std_logic_vector(c_data_width - 1 downto 0);
        variable v_FULL_DUV_INPUT : std_logic_vector(c_full_data_width - 1 downto 0);
    begin
        readline();
        
        r_en <= '1';
        wait until r_DUV_DV = '1';

    end process;

end architecture;