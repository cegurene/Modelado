library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity receiver is
  port (
    clk         : in  std_logic;
    rst         : in  std_logic;
    rx          : in  std_logic;
    dato_rx     : out std_logic_vector(7 downto 0);
    error_recep : out std_logic;
    DATO_RX_OK  : out std_logic
  );
end receiver;

architecture rtl of receiver is

  -- Definición de tipos para la máquina de estados
  type state_type is (idle, start_bit, receiving, parity_check, stop_bit, output_data);
  signal state, next_state : state_type := idle;

  -- Señales internas
  signal bit_counter  : integer range 0 to 10 := 0; -- 8 datos + paridad + stop
  signal rx_samples   : std_logic_vector(7 downto 0) := (others => '1');
  signal sample_count : integer := 0;
  signal bit_value    : std_logic;
  signal temp_data    : std_logic_vector(7 downto 0);
  signal parity_calc  : std_logic;
  signal parity_rx    : std_logic;

  -- Constantes
  constant BAUD_RATE        : integer := 230400;
  constant CLK_FREQ         : integer := 100_000_000;
  constant T_BIT_CYCLES     : integer := CLK_FREQ / BAUD_RATE; -- ciclos de reloj por bit
  constant SAMPLES_PER_BIT  : integer := 8; -- Número de sobremuestras
  constant SAMPLE_CYCLES    : integer := T_BIT_CYCLES / SAMPLES_PER_BIT;

  signal prescaler    : integer := 0;
  signal sample_point : std_logic := '0';

begin

  -----------------------------------------------------------------------------
  -- Prescaler para generar puntos de muestreo
  -----------------------------------------------------------------------------
  process(clk, rst)
  begin
    if rst = '1' then
      prescaler <= 0;
      sample_point <= '0';
    elsif rising_edge(clk) then
      if prescaler = SAMPLE_CYCLES - 1 then
        prescaler <= 0;
        sample_point <= '1';
      else
        prescaler <= prescaler + 1;
        sample_point <= '0';
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Máquina de estados para recepción de trama
  -----------------------------------------------------------------------------
  process(clk, rst)
  begin
    if rst = '1' then
      state <= idle;
      bit_counter <= 0;
      sample_count <= 0;
      dato_rx <= (others => '0');
      DATO_RX_OK <= '0';
      error_recep <= '0';
    elsif rising_edge(clk) then
      if sample_point = '1' then
        case state is

          when idle =>
            DATO_RX_OK <= '0';
            error_recep <= '0';
            if rx = '0' then -- Detectar bit de START
              state <= start_bit;
              sample_count <= 0;
            end if;

          when start_bit =>
            if sample_count = SAMPLES_PER_BIT / 2 then
              if rx = '0' then
                state <= receiving;
                bit_counter <= 0;
              else
                state <= idle; -- No era un START válido
              end if;
            else
              sample_count <= sample_count + 1;
            end if;

          when receiving =>
            if sample_count = SAMPLES_PER_BIT - 1 then
              temp_data(bit_counter) <= rx;
              if bit_counter = 7 then
                state <= parity_check;
              else
                bit_counter <= bit_counter + 1;
              end if;
              sample_count <= 0;
            else
              sample_count <= sample_count + 1;
            end if;

          when parity_check =>
            if sample_count = SAMPLES_PER_BIT - 1 then
              parity_rx <= rx;
              sample_count <= 0;
              state <= stop_bit;
            else
              sample_count <= sample_count + 1;
            end if;

          when stop_bit =>
            if sample_count = SAMPLES_PER_BIT - 1 then
              if rx = '1' then
                state <= output_data;
              else
                error_recep <= '1';
                state <= idle;
              end if;
              sample_count <= 0;
            else
              sample_count <= sample_count + 1;
            end if;

          when output_data =>
            parity_calc <= '0';
            for i in 0 to 7 loop
              if temp_data(i) = '1' then
                parity_calc <= not parity_calc;
              end if;
            end loop;

            if parity_calc = not parity_rx then
              dato_rx <= temp_data;
              DATO_RX_OK <= '1';
              error_recep <= '0';
            else
              DATO_RX_OK <= '0';
              error_recep <= '1';
            end if;
            state <= idle;

          when others =>
            state <= idle;

        end case;
      end if;
    end if;
  end process;

end rtl;

