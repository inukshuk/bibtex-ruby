Feature: BibTeX Names
	As a hacker who works with bibliographies
	I want to be able to access individual parts of names in a BibTeX file
	
	Scenario Outline: Name splitting
		When I parse the name "<name>"
		Then the parts should be:
			|  first  |  von  |  last  |  jr  |
			| <first> | <von> | <last> | <jr> |
		
		# Then the First part should be "<first>"
		# And the von part should be "<von>"
		# And the Last part should be "<last>"
		# And the jr part should be "<jr>"
			
	Scenarios: decoret
		| name            | first     | von       | last    | jr |
		| AA BB           | AA        |           | BB      |    |
		| AA              |           |           | AA      |    |
		| AA bb           | AA        |           | bb      |    |
		| aa              |           |           | aa      |    |
		| AA bb CC        | AA        | bb        | CC      |    |
		| AA bb CC dd EE  | AA        | bb CC dd  | EE      |    |
		| AA 1B cc dd     | AA 1B     | cc        | dd      |    |
		| AA 1b cc dd     | AA        | 1b cc     | dd      |    |
		| AA {b}B cc dd   | AA {b}B   | cc        | dd      |    |
		| AA {b}b cc dd   | AA        | {b}b cc   | dd      |    |
		| AA {B}b cc dd   | AA        | {B}b cc   | dd      |    |
		| AA {B}B cc dd   | AA {B}B   | cc        | dd      |    |
		| AA \BB{b} cc dd | AA \BB{b} | cc        | dd      |    |
		| AA \bb{b} cc dd | AA        | \bb{b} cc | dd      |    |
		| AA {bb} cc DD   | AA {bb}   | cc        | DD      |    |
		| AA bb {cc} DD   | AA        | bb        | {cc} DD |    |
		| AA {bb} CC      | AA {bb}   |           | CC      |    |
		| bb CC, AA       | AA        | bb        | CC      |    |
		| bb CC, aa       | aa        | bb        | CC      |    |
		| bb CC dd EE, AA | AA        | bb CC dd  | EE      |    |
		| bb, AA          | AA        |           | bb      |    |
		| BB,             |           |           | BB      |    |
		| bb CC,XX, AA    | AA        | bb        | CC      | XX |
		| bb CC,xx, AA    | AA        | bb        | CC      | xx |
		| BB,, AA         | AA        |           | BB      |    |