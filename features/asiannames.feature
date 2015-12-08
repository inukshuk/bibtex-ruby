Feature: BibTeX Asian Names
	As a hacker who works with bibliographies
	I want to be able to access individual parts of Asian names in a BibTeX file

	Scenario Outline: Name splitting
		When I parse the name "<name>"
		Then the parts should be:
			|  first  |  von  |  last  |  jr  |
			| <first> | <von> | <last> | <jr> |

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
