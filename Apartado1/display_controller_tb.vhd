-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity display_controller_tb is

end display_controller_tb;

-------------------------------------------------------------------------------

architecture sim of display_controller_tb is
  constant CNT1         : time      :=;  --completar
  signal   RST_i        : std_logic := '1';
  signal   CLK_i        : std_logic := '0';
  signal   DATO_RX_OK_i : std_logic;
  signal   DATO_RX_i    : std_logic_vector(7 downto 0);
  signal   DP_i         : std_logic;
  signal   SEG_AG_i     : std_logic_vector(6 downto 0);
  signal   AND_70_i     : std_logic_vector(7 downto 0);
  signal   dato_vis     : std_logic_vector(31 downto 0);
begin  -- sim

  DUT : entity work.display_controller
    port map (
      RST        => RST_i,
      CLK        => CLK_i,
      DATO_RX_OK => DATO_RX_OK_i,
      DATO_RX    => DATO_RX_i,
      DP         => DP_i,
      SEG_AG     => SEG_AG_i,
      AND_70     => AND_70_i);


  UD : entity work.display
    port map (
      SEG_AG => SEG_AG_i,
      AND_70 => AND_70_i);

  RST_i <=;                             --completar, copiar del tutorial
  CLK_i <=;                             --completar

  process

    procedure enviar_dato(dato : std_logic_vector(31 downto 0) ) is
    begin
      wait until CLK_i = '0';
      DATO_RX_i    <= dato(31 downto 24);
      DATO_RX_OK_i <= '1';
      wait until CLK_i = '0';
      DATO_RX_OK_i <= '0';
      wait for CNT1;

      DATO_RX_i    <= dato(23 downto 16);
      DATO_RX_OK_i <= '1';
      wait until CLK_i = '0';
      DATO_RX_OK_i <= '0';
      wait for CNT1;

      DATO_RX_i    <= dato(15 downto 8);
      DATO_RX_OK_i <= '1';
      wait until CLK_i = '0';
      DATO_RX_OK_i <= '0';
      wait for CNT1;

      DATO_RX_i    <= dato(7 downto 0);
      DATO_RX_OK_i <= '1';
      wait until CLK_i = '0';
      DATO_RX_OK_i <= '0';

      wait for 4*CNT1;
    end enviar_dato;

    variable dato_1 : std_logic_vector(31 downto 0);
  begin  -- process
    wait for 333 ns;
    dato_1 := x"01234567";                      --completar
    dato_vis <= dato_1; --dato que se debe visualizar
    enviar_dato(dato_1);

    dato_1 := x"";                      --completar
    dato_vis <= dato_1;
    enviar_dato(dato_1);

    dato_1 := x"";                      --completar
    dato_vis <= dato_1;
    enviar_dato(dato_1);

    dato_1 := x"";                      --completar
    dato_vis <= dato_1;
    enviar_dato(dato_1);

    dato_1 := x"";                      --completar
    dato_vis <= dato_1;
    enviar_dato(dato_1);

    dato_1 := x"";                      --completar
    dato_vis <= dato_1;
    enviar_dato(dato_1);

    dato_1 := x"";                      --completar
    dato_vis <= dato_1;
    enviar_dato(dato_1);

    dato_1 := x"";                      --completar
    dato_vis <= dato_1;
    enviar_dato(dato_1);

    report "FIN CONTROLADO DE LA SIMULACION" severity failure;
  end process;


end sim;

-------------------------------------------------------------------------------
