library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_controller_tb is
end spi_controller_tb;

architecture sim of spi_controller_tb is

  signal CLK_i         : std_logic := '0';
  signal RST_i         : std_logic := '1';
  signal DATA_SPI_OK_i : std_logic := '0';
  signal DATA_SPI_i    : std_logic_vector(8 downto 0) := (others => '0');
  signal D_C_i         : std_logic;
  signal CS_i          : std_logic;
  signal SDIN_i        : std_logic;
  signal SCLK_i        : std_logic;
  signal END_SPI_i     : std_logic;

  constant T_clk  : time := 10 ns;     -- Periodo de CLK (100 MHz)
  constant T_data : time := 20 us;     -- Tiempo entre envíos de datos

begin

  -- Generación del reloj
  clk_process : process
  begin
    CLK_i <= '0';
    wait for T_clk/2;
    CLK_i <= '1';
    wait for T_clk/2;
  end process;

  -- Instancia del DUT: spi_controller
  DUT: entity work.spi_controller
    port map (
      CLK         => CLK_i,
      RST         => RST_i,
      DATA_SPI_OK => DATA_SPI_OK_i,
      DATA_SPI    => DATA_SPI_i,
      D_C         => D_C_i,
      CS          => CS_i,
      SDIN        => SDIN_i,
      SCLK        => SCLK_i,
      END_SPI     => END_SPI_i
    );

  -- Instancia del dispositivo SPI simulado
  SPI_DEV : entity work.spi_device
    port map(
      D_C  => D_C_i,
      CS   => CS_i,
      SDIN => SDIN_i,
      SCLK => SCLK_i
    );

  -- Estímulos de la simulación
  stimulus : process
    procedure gen_dato(dato : std_logic_vector(8 downto 0)) is
    begin
      wait until CLK_i = '0';
      DATA_SPI_i    <= dato;
      DATA_SPI_OK_i <= '1';
      wait until CLK_i = '0';
      DATA_SPI_OK_i <= '0';
      wait for T_data;
    end procedure;
  begin
    -- Reset inicial
    wait for 100 ns;
    RST_i <= '0';

    -- Enviar varios datos
    gen_dato("0" & x"48"); -- H
    gen_dato("0" & x"45"); -- E
    gen_dato("0" & x"4C"); -- L
    gen_dato("0" & x"4F"); -- O

    wait for 500 us;
    report "Fin de la simulación" severity failure;
  end process;

end sim;


-------------------------------------------------------------------------------
