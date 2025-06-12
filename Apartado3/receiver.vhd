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

  -- Definicion de tipos para la maquina de estados
  type state_type is (idle, start_bit, receiving, parity_check, stop_bit, output_data);
  signal state, next_state : state_type := idle;

  -- Señales internas
  signal bit_counter  : integer range 0 to 7 := 0; -- 8 datos
  signal rx_samples   : std_logic_vector(7 downto 0) := (others => '0');
  signal sample_count : integer := 0;
  signal sample_check : integer := 0;
  signal bit_value    : std_logic := '0';
  signal temp_data    : std_logic_vector(7 downto 0) := (others => '0');
  signal parity_calc  : std_logic := '0';
  signal parity_rx    : std_logic := '0';

  -- Constantes
  constant BAUD_RATE        : integer := 230400;
  constant CLK_FREQ         : integer := 100000000; -- 100 millones
  constant T_BIT_CYCLES     : integer := CLK_FREQ / BAUD_RATE; -- ciclos de reloj por bit
  constant SAMPLES_PER_BIT  : integer := 8; -- Numero de sobremuestras
  constant SAMPLE_CYCLES    : integer := T_BIT_CYCLES / (SAMPLES_PER_BIT *2); -- 54.25 ciclos

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
  -- Maquina de estados para recepcion de trama
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
      
      DATO_RX_OK <= '0';
    
      if sample_point = '1' then
        case state is -- Maquina de estados

          when idle =>
            if rx = '0' then -- Detectar bit de START
              state <= start_bit;
              error_recep <= '0';
              sample_count <= 0;
              rx_samples <= (others => '0'); -- Limpiar muestras previas
              bit_counter <= 0;
            end if;

          when start_bit =>
            sample_check <= 0;

            if sample_count = SAMPLES_PER_BIT - 1 then

              if sample_check < 0 then
                state <= receiving;
                parity_calc <= '0';
                temp_data <= (others => '0');

              else
                state <= idle; -- No era un START valido (puede ser ruido)
                error_recep <= '1';
              end if;

              sample_count <= 0;
              rx_samples <= (others => '0'); -- Limpiar muestras previas

            else
              rx_samples(sample_count) <= rx;
              sample_count <= sample_count + 1;
              
              if rx = '1' then
                sample_check <= sample_check + 1;
              else
                sample_check <= sample_check - 1;
              end if;

            end if;

          when receiving =>
            sample_check <= 0;
          
            if sample_count = SAMPLES_PER_BIT - 1 then          
              
              if sample_check < 0 then
                temp_data(bit_counter) <= '0';
              else
                temp_data(bit_counter) <= '1';
                parity_calc <= not parity_calc;
              end if;

              if bit_counter = 7 then
                state <= parity_check;
                rx_samples <= (others => '0'); -- Limpiar muestras previas
              else
                bit_counter <= bit_counter + 1;
              end if;
              sample_count <= 0;

            else
              rx_samples(sample_count) <= rx;
              sample_count <= sample_count + 1;
              
              if rx = '1' then
                sample_check <= sample_check + 1;
              else
                sample_check <= sample_check - 1;
              end if;
            end if;

          when parity_check =>
            
            if sample_count = SAMPLES_PER_BIT - 1 then

              -- Verificar paridad
              if parity_calc = not parity_rx then
                state <= stop_bit;
              else
                error_recep <= '1';
                state <= idle;
              end if;

              sample_count <= 0;
              rx_samples <= (others => '0'); -- Limpiar muestras previas

            else
              rx_samples(sample_count) <= rx;
              sample_count <= sample_count + 1;
              
              if rx = '1' then
                parity_rx <= '1';
              else
                parity_rx <= '0';
              end if;
            end if;

          when stop_bit =>
            sample_check <= 0;
          
            if sample_count = SAMPLES_PER_BIT - 1 then

              if sample_check > 0 then
                state <= output_data;
              else
                error_recep <= '1';
                state <= idle;
              end if;
              
              sample_count <= 0;
              rx_samples <= (others => '0'); -- Limpiar muestras previas

            else
              rx_samples(sample_count) <= rx;
              sample_count <= sample_count + 1;
                
              if rx = '1' then
                sample_check <= sample_check + 1;
              else
                sample_check <= sample_check - 1;
              end if;
            end if;

          when output_data =>

            dato_rx <= temp_data;
            DATO_RX_OK <= '1';
            error_recep <= '0';

            state <= idle;

          when others =>
            state <= idle;

        end case;
      end if;
    end if;
  end process;

end rtl;

