library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity display_controller_tb is
end display_controller_tb;

architecture sim of display_controller_tb is

  signal clk         : std_logic := '0';
  signal rst         : std_logic := '1';
  signal dato_rx     : std_logic_vector(7 downto 0) := (others => '0');
  signal dato_rx_ok  : std_logic := '0';
  signal seg_ag      : std_logic_vector(6 downto 0);
  signal and_70      : std_logic_vector(7 downto 0);
  signal dp          : std_logic;

  constant T_clk : time := 10 ns; -- 100 MHz

begin

  -- Generador de reloj
  clk_process : process
  begin
    while true loop
      clk <= '0'; wait for T_clk/2;
      clk <= '1'; wait for T_clk/2;
    end loop;
  end process;

  -- Instancia del display_controller
  DUT : entity work.display_controller
    port map (
      RST         => rst,
      CLK         => clk,
      DATO_RX_OK  => dato_rx_ok,
      DATO_RX     => dato_rx,
      DP          => dp,
      SEG_AG      => seg_ag,
      AND_70      => and_70
    );

  -- Proceso de estímulos
  stim_proc : process
  begin
    wait for 100 ns;
    rst <= '0';

    -- Enviar caracteres "A", "B", "C", "D"
    dato_rx <= x"41"; dato_rx_ok <= '1'; wait for T_clk; dato_rx_ok <= '0'; wait for 2 us;
    dato_rx <= x"42"; dato_rx_ok <= '1'; wait for T_clk; dato_rx_ok <= '0'; wait for 2 us;
    dato_rx <= x"43"; dato_rx_ok <= '1'; wait for T_clk; dato_rx_ok <= '0'; wait for 2 us;
    dato_rx <= x"44"; dato_rx_ok <= '1'; wait for T_clk; dato_rx_ok <= '0'; wait for 2 us;

    wait for 500 us;
    report "Fin de la simulacion" severity failure;
  end process;

end sim;


-------------------------------------------------------------------------------
