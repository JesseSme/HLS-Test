-- Copied from stackoverflow

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY bidir IS
    PORT(
        data_io   : INOUT STD_LOGIC;
        wr_en : IN STD_LOGIC;
        inp     : out STD_LOGIC;
        outp    : in std_logic
        );
END bidir;

ARCHITECTURE maxpld OF bidir IS
BEGIN

  data_io <= outp when wr_en = '1' else 'Z';
  inp <= data_io;
END maxpld;