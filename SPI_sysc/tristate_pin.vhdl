-- Copied from stackoverflow

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY bidir_pin IS
  port (
    wr_en : IN std_logic;
    data_io : INOUT std_logic
  );
END bidir_pin;

ARCHITECTURE struct OF bidir_pin IS
  SIGNAL input : std_logic;
  SIGNAL output : std_logic := '1';
BEGIN
  data_io <= output WHEN wr_en = '1' ELSE 'Z';
  input <= data_io;
END ARCHITECTURE struct;