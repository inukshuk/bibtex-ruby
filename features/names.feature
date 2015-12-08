Feature: BibTeX Names
	As a hacker who works with bibliographies
	I want to be able to access individual parts of names in a BibTeX file
	
	Scenario Outline: Name splitting
		When I parse the name "<name>"
		Then the parts should be:
			|  first  |  von  |  last  |  jr  |
			| <first> | <von> | <last> | <jr> |
	
	@names @display
	Scenarios: Decoret test suite (display order)
		| name            | first      | von        | last    | jr |
		| AA BB           | AA         |            | BB      |    |
		| AA BB CC        | AA BB      |            | CC      |    |
		| AA              |            |            | AA      |    |
		| AA bb           | AA         |            | bb      |    |
		| aa              |            |            | aa      |    |
		| aa bb           |            | aa         | bb      |    |
		| aa BB           |            | aa         | BB      |    |
		| AA bb CC        | AA         | bb         | CC      |    |
		| AA bb CC dd EE  | AA         | bb CC dd   | EE      |    |
		| AA 1B cc dd     | AA 1B      | cc         | dd      |    |
		| AA 1b cc dd     | AA         | 1b cc      | dd      |    |
		| AA {b}B cc dd   | AA {b}B    | cc         | dd      |    |
		| AA {b}b cc dd   | AA         | {b}b cc    | dd      |    |
		| AA {B}b cc dd   | AA         | {B}b cc    | dd      |    |
		| AA {B}B cc dd   | AA {B}B    | cc         | dd      |    |
		| AA \BB{b} cc dd | AA \\BB{b} | cc         | dd      |    |
		| AA \bb{b} cc dd | AA         | \\bb{b} cc | dd      |    |
		| AA {bb} cc DD   | AA {bb}    | cc         | DD      |    |
		| AA bb {cc} DD   | AA         | bb         | {cc} DD |    |
		| AA {bb} CC      | AA {bb}    |            | CC      |    |

	@names @sort
	Scenarios: Decoret test suite (sort order)
		| name            | first      | von        | last    | jr |
		| bb CC, AA       | AA         | bb         | CC      |    |
		| bb CC, aa       | aa         | bb         | CC      |    |
		| bb CC dd EE, AA | AA         | bb CC dd   | EE      |    |
		| bb, AA          | AA         |            | bb      |    |
		| BB,             |            |            | BB      |    |
		| bb CC,XX, AA    | AA         | bb         | CC      | XX |
		| bb CC,xx, AA    | AA         | bb         | CC      | xx |
		| BB,, AA         | AA         |            | BB      |    |
		| CC dd BB, AA    | AA         | CC dd      | BB      |    |
		| BB, AA          | AA         |            | BB      |    |
	
	@names @sort
	Scenarios: Long von parts
		| name            | first      | von        | last    | jr |
		| bb cc dd CC, AA | AA         | bb cc dd   | CC      |    |
		| bb CC dd CC, AA | AA         | bb CC dd   | CC      |    |
		| BB cc dd CC, AA | AA         | BB cc dd   | CC      |    |
		| BB CC dd CC, AA | AA         | BB CC dd   | CC      |    |

	@names 
	Scenarios: Decoret further remarks
		| name                              | first                | von            | last                    | jr |
		# | Paul \'Emile Victor               | Paul \'Emile        |                | Victor                  |    |
		# | Paul {\'E}mile Victor             | Paul {\'E}mile      |                | Victor                  |    |
		# | Paul \'emile Victor               | Paul \'emile        |                | Victor                  |    |
		# | Paul {\'e}mile Victor             | Paul {\'e}mile      |                | Victor                  |    |
		# | Victor, Paul \'Emile              | Paul \'Emile        |                | Victor                  |    |
		# | Victor, Paul {\'E}mile            | Paul {\'E}mile      |                | Victor                  |    |
		# | Victor, Paul \'emile              | Paul \'emile        |                | Victor                  |    |
		# | Victor, Paul {\'e}mile            | Paul {\'e}mile      |                | Victor                  |    |
		| Dominique Galouzeau de Villepin    | Dominique Galouzeau  | de             | Villepin                |    |
		| Dominique {G}alouzeau de Villepin  | Dominique            | {G}alouzeau de | Villepin                |    |
		| Galouzeau {de} Villepin, Dominique | Dominique            |                | Galouzeau {de} Villepin |    |

  @names 
	Scenarios: Some actual names
		| name                              | first                   | von            | last                           | jr  |
		| John Paul Jones                   | John Paul               |                | Jones                          |     |
		| Ludwig von Beethoven              | Ludwig                  | von            | Beethoven                      |     |
		| von Beethoven, Ludwig             | Ludwig                  | von            | Beethoven                      |     |
		| {von Beethoven}, Ludwig           | Ludwig                  |                | {von Beethoven}                |     |
		| {{von} Beethoven}, Ludwig         | Ludwig                  |                | {{von} Beethoven}              |     |
		| John {}Paul Jones                 | John {}Paul             |                | Jones                          |     |
		| Ford, Jr., Henry                  | Henry                   |                | Ford                           | Jr. |
    | Brinch Hansen, Per                | Per                     |                | Brinch Hansen                  |     |
    | {Barnes and Noble, Inc.}          |                         |                | {Barnes and Noble, Inc.}       |     |
    | {Barnes and} {Noble, Inc.}        | {Barnes and}            |                | {Noble, Inc.}                  |     |
    | {Barnes} {and} {Noble,} {Inc.}    | {Barnes} {and} {Noble,} |                | {Inc.}                         |     |
    | Charles Louis Xavier Joseph de la Vallee Poussin | Charles Louis Xavier Joseph | de la | Vallee Poussin       |     |

	@names @display
	Scenarios: Some Japanese names
		| name          | first  | von | last   | jr |
		| 田中          |        |     | 田中   |    |
		| 田中 花子     | 花子   |     | 田中   |    |
		| たなか はなこ | はなこ |     | たなか |    |
		| タナカ ハナコ | ハナコ |     | タナカ |    |
		| 山田 太郎     | 太郎   |     | 山田   |    |
		| 鈴木 Alice    | Alice  |     | 鈴木   |    |
		| Alice {鈴木}  | Alice  |     | {鈴木} |    |

	@names @display
	Scenarios: A Korean name
		| name          | first  | von | last   | jr |
		| 이 승만       | 승만   |     | 이     |    |

	@names @display
	Scenarios: Artificial names with Asian letters to cover all parsing cases
		| name             | first     | von  | last        | jr |
		| 大君 ズム 慈恩   | ズム 慈恩 |      | 大君        |    |
		| 大君{ }ズム 慈恩 | 慈恩      |      | 大君{ }ズム |    |
		| 紅玉ruby         |           |      | 紅玉ruby    |    |
		| 紅玉 ruby        | ruby      |      | 紅玉        |    |
		| あbC 出 位       | 位        | あbC | 出          |    |
		| a ほげfuga       |           | a    | ほげfuga    |    |
		| a ほげふが       |           | a    | ほげふが    |    |
		| a ほげ ふが      | ふが      | a    | ほげ        |    |
		| a ほげ fuga      | fuga      | a    | ほげ        |    |
		| A b ほげfuga     |           | A b  | ほげfuga    |    |
		| A b ほげふが     |           | A b  | ほげふが    |    |
		| A b ほげ ふが    | ふが      | A b  | ほげ        |    |
		| A b ほげ fuga    | fuga      | A b  | ほげ        |    |

	@names @sort
	Scenarios: In sorted name, Asian letters has no effect
		| name                 | first | von         | last | jr  |
		| 山崎, 渉             | 渉    |             | 山崎 |     |
		| 山崎, 2世, 渉        | 渉    |             | 山崎 | 2世 |
		| びb C詩,x掛, エA     | エA   | びb         | C詩  | x掛 |
		| ビB c氏 出d シC, A만 | A만   | ビB c氏 出d | シC  |     |
