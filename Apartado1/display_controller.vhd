library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity display_controller is
  port(RST        : in  std_logic;
       CLK        : in  std_logic;
       DATO_RX_OK : in  std_logic;
       DATO_RX    : in  std_logic_vector(7 downto 0);
       DP         : out std_logic;
       SEG_AG     : out std_logic_vector(6 downto 0);  -- gfedcba
       AND_70     : out std_logic_vector(7 downto 0));
end display_controller;

architecture rtl of display_controller is

  -- Constantes del enunciado
  constant CTE_ANDS : integer := 11 * 50; -- Ajustar este valor segun tu puesto de laboratorio
  constant TD : time := 2.75ms;

  -- Registro de desplazamiento
  signal shift_reg : std_logic_vector(31 downto 0);

  -- Multiplexor 32:4
  signal mux_ex : std_logic_vector(3 downto 0);

  -- Contador
  signal count : std_logic_vector(2 downto 0) := "000";

  -- Prescaler
  --constant CLKDIV      : integer := 5e6;   -- para la implementación
  constant CLKDIV      : integer := 11 * 50;  -- para la simulación
  signal   counter_reg : integer range 0 to CLKDIV-1;
  signal pre_out: std_logic;

begin

  -- Proceso de registro de desplazamiento
  process(CLK, RST)
  begin
    if RST = '1' then
      shift_reg <= (others => '0');
    elsif CLK'event and CLK = '1' then
      if DATO_RX_OK = '1' then
        shift_reg <= shift_reg(23 downto 0) & DATO_RX; --Desplazamos a izquierda 8 bits
      end if;
    end if;
  end process;


    -- multiplexor 32:4
    process (count)
    begin
      case count is
        when "000" => mux_ex(3 downto 0) <= shift_reg(3 downto 0);
        when "001" => mux_ex(3 downto 0) <= shift_reg(7 downto 4);
        when "010" => mux_ex(3 downto 0) <= shift_reg(11 downto 8);
        when "011" => mux_ex(3 downto 0) <= shift_reg(15 downto 12);
        when "100" => mux_ex(3 downto 0) <= shift_reg(19 downto 16);
        when "101" => mux_ex(3 downto 0) <= shift_reg(23 downto 20);
        when "110" => mux_ex(3 downto 0) <= shift_reg(27 downto 24);
        when "111" => mux_ex(3 downto 0) <= shift_reg(31 downto 28);
        when others => mux_ex(3 downto 0) <= "0000";
      end case;
    end process;


  -- Proceso del decodificador hex to 7 seg
  -- Muestra en el display el valor en hexadecimal en mux_ex
  process(mux_ex)
  begin
    case mux_ex is
      when "0000" => SEG_AG <= "1000000"; -- 0, se encienden todos menos el segmento 'g'
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
      when "1111" => SEG_AG <= "0001110"; -- F
      when others => SEG_AG <= (others => '0');
    end case;
  end process;

  -- Proceso del prescaler
  process (CLK, RST)
  begin  -- process
      if RST = '1' then
        pre_out   <= '0';
      elsif CLK'event and CLK = '1' then
        if counter_reg = CLKDIV-1 then
          pre_out <= '1';
        else
          pre_out <= '0';
        end if;
      end if;
  end process;

  process (CLK, RST)
  begin  -- process
    if RST = '1' then
      counter_reg   <= 0;
    elsif CLK'event and CLK = '1' then
      if counter_reg = CLKDIV-1 then
        counter_reg <= 0;
      else
        counter_reg <= counter_reg+1;
      end if;
    end if;
  end process;
  
  -- Proceso del contador
  process(pre_out)
  begin
    if pre_out'event and pre_out = '1' then
        count <= std_logic_vector(unsigned(count) + 1);      
    end if;
  end process;

  -- Proceso del decodificador 3:8
  process(count)
  begin
    case count is
      when "000" => AND_70 <= "11111110";
      when "001" => AND_70 <= "11111101";
      when "010" => AND_70 <= "11111011";
      when "011" => AND_70 <= "11110111";
      when "100" => AND_70 <= "11101111";
      when "101" => AND_70 <= "11011111";
      when "110" => AND_70 <= "10111111";
      when "111" => AND_70 <= "01111111";
      when others => AND_70 <= (others => '0');
    end case;
  end process;

  -- Proceso DP
  process(count)
  begin
    if count = "000" or count = "010" or count = "100" or count = "110" then
      DP <= '0';
    else
      DP <= '1';
    end if;
  end process;

end;
