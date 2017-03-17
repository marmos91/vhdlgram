library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.nonogram_package.all;
 
entity nonogram is

   port
	(
		CLOCK_50            	: in  std_logic;
		
		SW                  	: in  std_logic_vector(17 downto 0);
		
		KEY                 	: in  std_logic_vector(3 downto 0);
				
		VGA_R               	: out std_logic_vector(7 downto 0);
		VGA_G               	: out std_logic_vector(7 downto 0);
		VGA_B               	: out std_logic_vector(7 downto 0);
		VGA_HS              	: out std_logic;
		VGA_VS              	: out std_logic;
		VGA_SYNC_N				: out std_logic;
		VGA_BLANK_N				: out std_logic;
		VGA_CLK					: out std_logic;
		
		HEX7						: out std_logic_vector(6 to 0);
		HEX6						: out std_logic_vector(6 to 0);
		HEX3						: out std_logic_vector(6 to 0);
		HEX2						: out std_logic_vector(6 to 0);
		HEX1						: out std_logic_vector(6 to 0);
		HEX0						: out std_logic_vector(6 to 0);
		
		LERG						: out std_logic_vector(8 to 0) := (others => '0');
		LEDR						: out std_logic_vector(17 to 0) := (others => '0')
	);
	
end nonogram;

architecture RTL of nonogram is

	-- Signal declaration
	signal clock					: std_logic;
	signal vga_clock				: std_logic;
	signal reset_n					: std_logic;
	signal reset_sync				: std_logic;
	signal level					: integer range -1 to MAX_LEVEL - 1;
	signal status					: status_type;
	signal ack						: status_type;
	signal row_index				: integer range 0 to MAX_COLUMN - 1;
	signal row_description		: line_type;
	signal iteration				: integer range 0 to MAX_ITERATION - 1;
	signal undefined_cells		: integer range 0 to MAX_ROW * MAX_COLUMN - 1;
	
begin
	
	--entities
	pll: entity work.PLL
		port map
		(
				inclk0	=> CLOCK_50,
				c0			=> clock,
				c1			=> vga_clock
		);
		
	vga_view : entity work.vga_view
		port map 
		(
			CLOCK						=> vga_clock,			
			RESET_N					=> reset_n,
			VGA_R						=> VGA_R,
			VGA_G						=> VGA_G,
			VGA_B						=> VGA_B,
			VGA_HS					=> VGA_HS,
			VGA_VS					=> VGA_VS,
			VGA_SYNC_N				=> VGA_SYNC_N,
			VGA_BLANK_N				=> VGA_BLANK_N,
			
			ROW_DESCRIPTION		=> row_description,
			ROW_INDEX				=> row_index,
			
			LEVEL						=> level,
			STATUS					=> status
		);	
	
	-- processes
	reset : process(clock)
	begin
		if(rising_edge(clock)) then
			reset_sync <= SW(0);
			reset_n <= reset_sync;
		end if;
	end process;
	
	vga_clock_forward : process(vga_clock)
	begin
		VGA_CLK <= vga_clock;
	end process;
	
	--pseudodatapath TODO: implement real datapath
	pseudo_datapath : process(clock, reset_n)
	begin
		if(SW(17) = '1') then
			level <= 0;
		else
			level <= -1;
		end if;
		row_description <= (FULL, UNDEFINED, EMPTY, others=>(INVALID));
	end process;
		
end architecture;
 