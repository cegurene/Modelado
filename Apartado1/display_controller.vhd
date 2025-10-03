library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity display_controller is
  port(
    RST         : in  std_logic;
    CLK         : in  std_logic;
    DATO_RX_OK  : in  std_logic;
    DATO_RX     : in  std_logic_vector(7 downto 0);
    DP          : out std_logic;
    SEG_AG      : out std_logic_vector(6 downto 0);
    AND_70      : out std_logic_vector(7 downto 0)
  );
end display_controller;

architecture Behavioral of display_controller is

  --puesto 11
  constant CTE_ANDS : integer := 11 * 50; --simulacion
  --constant CTE_ANDS : integer := 137500; --descarga (2,75ms/10ns)

  -- Registro de desplazamiento de 4 caracteres (4 x 8 bits = 32 bits)
  signal shift_reg : std_logic_vector(31 downto 0) := (others => '0');

  -- Prescaler y contador para multiplexar displays
  signal prescaler : integer := 0;
  signal sel_disp  : integer range 0 to 7 := 0;

  -- Datos internos
  signal nibble_sel : std_logic_vector(3 downto 0);

begin

  -- Proceso para almacenar y desplazar caracteres
  process(CLK, RST)
  begin
    if RST = '1' then
      shift_reg <= (others => '0');
    elsif rising_edge(CLK) then
      if DATO_RX_OK = '1' then
        shift_reg <= shift_reg(23 downto 0) & DATO_RX;
      end if;
    end if;
  end process;

  -- Proceso para gestionar el prescaler y seleccionar el display activo
  process(CLK, RST)
  begin
    if RST = '1' then
      prescaler <= 0;
      sel_disp <= 0;
    elsif rising_edge(CLK) then
      if prescaler = CTE_ANDS - 1 then
        prescaler <= 0;
        if sel_disp = 7 then
          sel_disp <= 0;
        else
          sel_disp <= sel_disp + 1;
        end if;
      else
        prescaler <= prescaler + 1;
      end if;
    end if;
  end process;

  -- Multiplexor para seleccionar el nibble (4 bits) que se mostrara
  with sel_disp select
    nibble_sel <= shift_reg(3 downto 0)   when 0,
                  shift_reg(7 downto 4)   when 1,
                  shift_reg(11 downto 8)  when 2,
                  shift_reg(15 downto 12) when 3,
                  shift_reg(19 downto 16) when 4,
                  shift_reg(23 downto 20) when 5,
                  shift_reg(27 downto 24) when 6,
                  shift_reg(31 downto 28) when others;

  -- Conversor HEX -> 7 segmentos
  process(nibble_sel)
  begin
    case nibble_sel is
      when "0000" => SEG_AG <= "1000000"; -- 0
      when "0001" => SEG_AG <= "1111001"; -- 1
      when "0010" => SEG_AG <= "0100100"; -- 2
      when "0011" => SEG_AG <= "0110000"; -- 3
      when "0100" => SEG_AG <= "0011001"; -- 4
      when "0101" => SEG_AG <= "0010010"; -- 5
      when "0110" => SEG_AG <= "0000010"; -- 6
      when "0111" => SEG_AG <= "1111000"; -- 7
      when "1000" => SEG_AG <= "0000000"; -- 8
      when "1001" => SEG_AG <= "0011000"; -- 9
      when "1010" => SEG_AG <= "0001000"; -- A
      when "1011" => SEG_AG <= "0000011"; -- B
      when "1100" => SEG_AG <= "1000110"; -- C
      when "1101" => SEG_AG <= "0100001"; -- D
      when "1110" => SEG_AG <= "0000110"; -- E
      when others => SEG_AG <= "0001110"; -- F y otros
    end case;
  end process;

  -- Activacion del display correspondiente (AND_70 activo bajo)
  with sel_disp select
    AND_70 <= "11111110" when 0,
              "11111101" when 1,
              "11111011" when 2,
              "11110111" when 3,
              "11101111" when 4,
              "11011111" when 5,
              "10111111" when 6,
              "01111111" when others;

  -- Activacion del punto decimal en D2, D4, D6
  process(sel_disp)
  begin
    case sel_disp is
      when 2 | 4 | 6 => DP <= '0';
      when others    => DP <= '1';
    end case;
  end process;

end Behavioral;

