
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

package nonogram_package is

	--CONSTANTS
	constant MAX_LINE					: integer := 10;
	constant MAX_CLUE_LINE			: integer := 5; -- CEIL(MAX_LINE / 2)
	
	constant MAX_CLUE					: integer := 19;
	constant MAX_LEVEL				: integer := 4;
	constant MAX_ITERATION			: integer := 30;
	constant W_PERIOD					: integer := 4;
	
	--TYPES
	attribute enum_encoding	: string;
	
	type status_type is (IDLE, LOAD, SOLVE_ITERATION, SOLVE_ALL, WON, LOST);
	
	--cells
	type cell_type is (INVALID, UNDEFINED, EMPTY, FULL);
	attribute enum_encoding of cell_type : type is "sequential";
	
	type cell_position_type is record
		x				: integer range -1 to (MAX_LINE - 1); -- -1 for invalid cell position
		y				: integer range -1 to (MAX_LINE - 1); -- -1 for invalid cell position
	end record;
	
	type cell_array_position_type is array(integer range <>) of cell_position_type;
	
	--board
	type board_type is array(integer range 0 to MAX_LINE - 1, integer range 0 to MAX_LINE - 1) of cell_type;
	
	--lines
	type line_type is array(0 to (MAX_LINE - 1)) of cell_type;
	
	--clues
	subtype clue_type is integer range -1 to MAX_CLUE; -- -1 for invalid clue
	type clue_matrix_type is array(integer range <>, integer range <>, integer range <>) of clue_type; 

	--constraints
	type constraint_type is record
		size				: integer range -1 to MAX_CLUE;
		min_start		: integer range 0 to MAX_LINE - 1;
		max_end			: integer range 0 to MAX_LINE - 1;
	end record;
	type constraint_line_type is array(integer range 0 to MAX_CLUE_LINE - 1) of constraint_type;
	type constraint_matrix_type is array(integer range 0 to 1, integer range 0 to MAX_LINE - 1, integer range 0 to MAX_CLUE_LINE) of constraint_type;
	
	--levels
	type dim_type is array(integer range <>) of integer range 0 to MAX_LINE - 1;
	type level_type is record
		dim				: 	dim_type(0 to 1); --Be careful. Max real dimension is 30x40.
		clues				:	clue_matrix_type(0 to 1, 0 to MAX_LINE - 1, 0 to MAX_CLUE_LINE - 1);
		full_cells		:	cell_array_position_type(0 to MAX_LINE * MAX_LINE - 1);
		empty_cells		:	cell_array_position_type(0 to MAX_LINE * MAX_LINE - 1);
	end record;
	type level_array_type is array(integer range 0 to MAX_LEVEL - 1) of level_type;
	
	--queries
	type query_type is record
		transposed		:	integer range 0 to 1;
		index				: 	integer range -1 to MAX_LINE - 1;
	end record;
	
	--FUNCTIONS
	function load_board_row(level : integer range -1 to MAX_LEVEl - 1; index : integer range 0 to MAX_LINE - 1) return line_type;
	function load_constraint_line(level : integer range 0 to MAX_LEVEL - 1; transposed : integer range 0 to 1; index : integer range 0 to MAX_LINE - 1) return constraint_line_type;
	
	--CONSTANTS
	constant EMPTY_LEVEL : level_type :=
	(
		dim 				=> (0,0),
		clues				=> 
		(
			(others => (others => -1)),
			(others => (others => -1))
		),
		full_cells		=>
		(
			others => (-1, -1)
		),
		empty_cells		=>
		(
			others => (-1, -1)
		)
	);

	constant LEVEL_INPUT : level_array_type :=
	(
		(
			dim 				=> (5,4),
			clues				=> 
			(
				(
					(5, others => -1),
					(1,1, others => -1),
					(1,1, others => -1),
					(1,1, others => -1),
					others => (others => -1)
				),
				(
					(1, others => -1),
					(4, others => -1),
					(1, others => -1),
					(4, others => -1),
					(1, others => -1),
					others => (others => -1)
				)
			),
			full_cells		=>
			(
				others => (-1, -1)
			),
			empty_cells		=>
			(
				others => (-1, -1)
			)
		),
		(
			dim 				=> (3,3),
			clues				=> 
			(
				(
					(1,1, others => -1),
					(1, others => -1),
					(1,1, others => -1),
					others => (others => -1)
				),
				(
					(1,1, others => -1),
					(1, others => -1),
					(1,1, others => -1),
					others => (others => -1)
				)
			),
			full_cells		=>
			(
				(0,0),
				others => (-1, -1)
			),
			empty_cells		=>
			(
				(1,2),
				others => (-1, -1)
			)
		),
		(
			dim 				=> (9,10),
			clues				=> 
			(
				(
					(1,1, others => -1),
					(3,3, others => -1),
					(1,1,1, others => -1),
					(1,1, others => -1),
					(1,1, others => -1),
					(1,1, others => -1),
					(1,1, others => -1),
					(1,1, others => -1),
					(3, others => -1),
					(1, others => -1),
					others => (others => -1)
				),
				(
					(4, others => -1),
					(1,1, others => -1),
					(2,1, others => -1),
					(1,1, others => -1),
					(1,2, others => -1),
					(1,1, others => -1),
					(2,1, others => -1),
					(1,1, others => -1),
					(4, others => -1),
					others => (others => -1)
				)
			),
			full_cells		=>
			(
				others => (-1, -1)
			),
			empty_cells		=>
			(
				others => (-1, -1)
			)
		),
		others => EMPTY_LEVEL
	);
	
end package;

package body nonogram_package is
	
	--FUNCTIONS
	function load_board_row(level : integer range -1 to MAX_LEVEl - 1; index : integer range 0 to MAX_LINE - 1) return line_type is
		variable result : line_type := (others => INVALID);
	begin
		if(level > -1 and index < LEVEL_INPUT(level).dim(1)) then
			for i in 0 to MAX_LINE - 1 loop
				if(i < LEVEL_INPUT(level).dim(0)) then 
					result(i) := UNDEFINED;
				end if;
			end loop;
			
			for i in 0 to MAX_LINE * MAX_LINE - 1 loop
				if(LEVEL_INPUT(level).empty_cells(i).x /= -1 and LEVEL_INPUT(level).empty_cells(i).y = index) then
					result(LEVEL_INPUT(level).empty_cells(i).x) := EMPTY;
				end if;
			end loop;
			
			for i in 0 to MAX_LINE * MAX_LINE - 1 loop
				if(LEVEL_INPUT(level).full_cells(i).x /= -1 and LEVEL_INPUT(level).full_cells(i).y = index) then
					result(LEVEL_INPUT(level).full_cells(i).x) := FULL;
				end if;
			end loop;
		end if;	
		return result;
	end function;
	
	function load_constraint_line(level : integer range 0 to MAX_LEVEL - 1; transposed : integer range 0 to 1; index : integer range 0 to MAX_LINE - 1) return constraint_line_type is
		variable result : constraint_line_type := (others => (-1,0,0));
		variable left_clues_sum : integer;
		variable right_clues_sum : integer;
		variable clue_line_length : integer;
	begin
		if(index < LEVEL_INPUT(level).dim(1 - transposed)) then

			left_clues_sum := 0;
			right_clues_sum := 0;
			
			for i in 0 to MAX_CLUE_LINE -1 loop
			if(LEVEL_INPUT(level).clues(transposed, index, i) /= -1) then
				right_clues_sum := right_clues_sum + LEVEL_INPUT(level).clues(transposed, index, i) + 1;
			end if;
			end loop;
				
			for i in 0 to MAX_CLUE_LINE -1 loop
			if(LEVEL_INPUT(level).clues(transposed, index, i) /= -1) then
				right_clues_sum := right_clues_sum - LEVEL_INPUT(level).clues(transposed, index, i) - 1;
				
				result(i).size := LEVEL_INPUT(level).clues(transposed, index, i);
				result(i).min_start := left_clues_sum;
				result(i).max_end := LEVEL_INPUT(level).dim(transposed) - 1 - right_clues_sum;
				
				left_clues_sum := left_clues_sum + LEVEL_INPUT(level).clues(transposed, index, i) + 1;
			end if;
			end loop;	
		end if;
		return result;
	end function;
end package body;