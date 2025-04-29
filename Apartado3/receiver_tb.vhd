-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity receiver_tb is
end receiver_tb;

architecture sim of receiver_tb is

  -- Señales internas
  signal clk_i         : std_logic := '0';
  signal rst_i         : std_logic := '1';
  signal rx_i          : std_logic := '1';
  signal dato_rx_i     : std_logic_vector(7 downto 0);
  signal error_recep_i : std_logic;
  signal DATO_RX_OK_i  : std_logic;

  constant T_clk : time := 10 ns; -- 100 MHz

  -- Procedimiento para simular el envío serie
  procedure send_byte(signal rx_line : out std_logic; dato : std_logic_vector(7 downto 0)) is
    variable parity : std_logic;
  begin
    parity := '0';
    for i in 0 to 7 loop
      if dato(i) = '1' then
        parity := not parity;
      end if;
    end loop;

    -- START bit
    rx_line <= '0';
    wait for 4.34 us;

    -- Data bits (LSB a MSB)
    for i in 0 to 7 loop
      rx_line <= dato(i);
      wait for 4.34 us;
    end loop;

    -- Parity bit (paridad impar)
    rx_line <= not parity;
    wait for 4.34 us;

    -- STOP bit
    rx_line <= '1';
    wait for 4.34 us;
  end procedure;

begin

  -- Generador de reloj
  clk_process : process
  begin
    while true loop
      clk_i <= '0';
      wait for T_clk/2;
      clk_i <= '1';
      wait for T_clk/2;
    end loop;
  end process;

  -- Instanciación del receiver
  DUT : entity work.receiver
    port map (
      clk         => clk_i,
      rst         => rst_i,
      rx          => rx_i,
      dato_rx     => dato_rx_i,
      error_recep => error_recep_i,
      DATO_RX_OK  => DATO_RX_OK_i
    );

  -- Generador de estímulos
  stim_proc : process
  begin
    -- Inicialización
    wait for 100 ns;
    rst_i <= '0';

    -- Enviar un carácter (por ejemplo "A" = 0x41)
    send_byte(rx_i, x"41");
    wait for 20 us;

    -- Enviar un carácter (por ejemplo "E" = 0x45)
    send_byte(rx_i, x"45");
    wait for 20 us;

    -- Finalizar la simulación controladamente
    wait for 100 us;
    report "Fin de la simulación" severity failure;

  end process;

end sim;



-------------------------------------------------------------------------------
