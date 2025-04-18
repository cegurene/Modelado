library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_controller is
  port (
    CLK         : in  std_logic;
    RST         : in  std_logic;
    DATA_SPI_OK : in  std_logic;
    DATA_SPI    : in  std_logic_vector(8 downto 0); -- bit 8: D_C, bits 7-0: dato
    D_C         : out std_logic;
    CS          : out std_logic;
    SDIN        : out std_logic;
    SCLK        : out std_logic;
    END_SPI     : out std_logic
  );
end spi_controller;

architecture rtl of spi_controller is

  ------------------------------------------------------------------------------
  -- Declaración de tipos y señales internas
  ------------------------------------------------------------------------------
  type state_type is (IDLE, LOAD, SHIFT, DONE);
  signal state, next_state : state_type;

  signal shift_reg  : std_logic_vector(7 downto 0);
  signal bit_index  : integer range 0 to 7 := 0;
  signal clk_count  : integer := 0;
  signal sclk_int   : std_logic := '0';
  signal ce         : std_logic := '0';
  signal prescaler  : integer := 77; -- N1 = puesto 11 × 7 -- N1 * 10ns (ajustar según el puesto)
  signal sclk_enable: std_logic := '0';

begin

  ------------------------------------------------------------------------------
  -- Prescaler para generar señal SCLK más lenta
  ------------------------------------------------------------------------------
  process(CLK, RST)
  begin
    if RST = '1' then
      clk_count <= 0;
      sclk_int  <= '0';
      sclk_enable <= '0';
    elsif rising_edge(CLK) then
      if state = SHIFT then
        if clk_count = prescaler - 1 then
          clk_count <= 0;
          sclk_int <= not sclk_int;
          sclk_enable <= '1';
        else
          clk_count <= clk_count + 1;
          sclk_enable <= '0';
        end if;
      else
        clk_count <= 0;
        sclk_int <= '0';
        sclk_enable <= '0';
      end if;
    end if;
  end process;

  SCLK <= sclk_int;

  ------------------------------------------------------------------------------
  -- Máquina de estados secuencial
  ------------------------------------------------------------------------------
  process(CLK, RST)
  begin
    if RST = '1' then
      state <= IDLE;
    elsif rising_edge(CLK) then
      state <= next_state;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- Lógica combinacional de transición de estados
  ------------------------------------------------------------------------------
  process(state, DATA_SPI_OK, sclk_enable, bit_index)
  begin
    next_state <= state;
    case state is
      when IDLE =>
        if DATA_SPI_OK = '1' then
          next_state <= LOAD;
        end if;
      when LOAD =>
        next_state <= SHIFT;
      when SHIFT =>
        if sclk_enable = '1' and sclk_int = '1' then
          if bit_index = 7 then
            next_state <= DONE;
          end if;
        end if;
      when DONE =>
        next_state <= IDLE;
    end case;
  end process;

  ------------------------------------------------------------------------------
  -- Lógica secuencial: salida y comportamiento del SPI
  ------------------------------------------------------------------------------
  process(CLK, RST)
  begin
    if RST = '1' then
      shift_reg <= (others => '0');
      D_C <= '0';
      CS <= '1';
      SDIN <= '0';
      bit_index <= 0;
      END_SPI <= '0';
    elsif rising_edge(CLK) then
      case state is
        when IDLE =>
          END_SPI <= '0';
        when LOAD =>
          shift_reg <= DATA_SPI(7 downto 0);
          D_C <= DATA_SPI(8);
          CS <= '0';
          bit_index <= 0;
        when SHIFT =>
          if sclk_enable = '1' and sclk_int = '0' then
            SDIN <= shift_reg(7);
          elsif sclk_enable = '1' and sclk_int = '1' then
            shift_reg <= shift_reg(6 downto 0) & '0';
            bit_index <= bit_index + 1;
          end if;
        when DONE =>
          CS <= '1';
          END_SPI <= '1';
      end case;
    end if;
  end process;

end rtl;

