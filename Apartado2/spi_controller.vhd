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
  -- Declaracion de tipos y señales internas
  ------------------------------------------------------------------------------

  signal shift_reg      : std_logic_vector(7 downto 0);
  signal count_mux      : integer range 0 to 9 := 0;
  signal sclk_int       : std_logic := '1';
  signal ce             : std_logic := '0';
  signal prescaler      : integer := 0;
  signal prescaler_int  : integer := 77; -- N1 = puesto 11 * 7 -- N1 * 10ns (ajustar segun el puesto)
  signal fc             : std_logic := '0';
  signal int            : std_logic := '0'; --para la generacion de ce a partir de fc
  signal busy           : std_logic := '0';

begin

-- Prescaler para generar señal fc y ce
   process(CLK, RST)
   begin
      if RST = '1' then
         prescaler <= 0;
         fc <= '0';
         ce <= '0';
         int <= '0';
      elsif rising_edge(clk) then
         if busy = '1' then
            if prescaler = prescaler_int - 1 then
               if int = '0' then
                  ce <= '1';
               end if;
               prescaler <= 0;
               fc <= '1';
               int <= not int;
            else
               prescaler <= prescaler + 1;
               fc <= '0';
               ce <= '0';
            end if;
         end if;
      end if;
   end process;
   
-- Circuito secuencial para generar SCLK
   process(RST, CLK)
   begin
      if RST = '1' then
         sclk_int <= '1';
         SCLK <= '1';
      elsif rising_edge(CLK) then
         if fc = '1' then
            SCLK <= not sclk_int;
            sclk_int <= not sclk_int;
         end if;
      end if;
   end process;

-- Registro
   process(CLK, RST)
   begin
      if RST = '1' then
         shift_reg <= (others => '0');
         D_C <= '0';
      elsif rising_edge(CLK) then
         if DATA_SPI_OK = '1' then
            D_C <= DATA_SPI(8);
            shift_reg <= DATA_SPI(7 downto 0);
         end if;
      end if;
   end process;

-- Generacion de señal busy y CS
   process(RST, CLK, count_mux)
   begin
      if RST = '1' then
         cs <= '1';
         busy <= '0';
      elsif rising_edge(CLK) then
         if DATA_SPI_OK = '1' then
            cs <= '0';
            busy <= '1';
         end if;  
         if count_mux = 9 then
            cs <= '1';
            busy <= '0';
         end if;
      end if;
   end process;
   
-- Envio de la señal
   process(CLK, RST, ce, count_mux, busy)
   begin
      if RST = '1' then
         END_SPI <= '0';
         count_mux <= 0;
         SDIN <= '0';
      elsif rising_edge(CLK) then
         if ce = '1' then
            case count_mux is
               when 0 =>
                  count_mux <= count_mux + 1;
                  SDIN <= shift_reg(7);
               when 1 =>
                  count_mux <= count_mux + 1;
                  SDIN <= shift_reg(6);
               when 2 =>
                  count_mux <= count_mux + 1;
                  SDIN <= shift_reg(5);
               when 3 =>
                  count_mux <= count_mux + 1;
                  SDIN <= shift_reg(4);
               when 4 =>
                  count_mux <= count_mux + 1;
                  SDIN <= shift_reg(3);
               when 5 =>
                  count_mux <= count_mux + 1;
                  SDIN <= shift_reg(2);
               when 6 =>
                  count_mux <= count_mux + 1;
                  SDIN <= shift_reg(1);
               when 7 =>
                  count_mux <= count_mux + 1;
                  SDIN <= shift_reg(0);
               when 8 =>
                  count_mux <= count_mux + 1;
                  END_SPI <= '1';
--                  cs <= '1';
--                  busy <= '0';
               when others =>
                  END_SPI <= '0';
                  count_mux <= 0;
--                  busy <= '0';
--                  cs <= '1';  
            end case;
         end if;
         if busy = '0' then
            END_SPI <= '0';
            count_mux <= 0;
            SDIN <= '0';
         end if;
      end if;
   end process;

end rtl;

