Feature: BibTeX Braced Strings
	As a hacker who works with bibliographies
	I want to be able to parse BibTeX files containing string definitions using braced expressions
	Because applications such as BibDesk produce that format

	Scenario: A BibTeX file with string assignments
		When I parse the following file:
		"""
		Simple strings:
		@string{ foo1 = {foo} }
		@string{ foo2 = {foo}}
		@string{ foo3 ={foo}}
		@string{foo4={foo}}
		@string{ foo5 = {"foo" bar} }
		@string{ foo6 = {"foo" bar{"}} }
		@string{ foo7 = {"foo" bar\} foo} }
		@string{ foo8 = {"foo" bar\{ foo} }
		
		Compound strings:
		@string{ foo8 = foo1 }
		@string{ foo9 = foo1 # {bar} }
		@string{ foo10 = {foo } # {bar} }
		
		"""
		Then my bibliography should contain 9 strings
		And my bibliography should contain these strings:
			| value            |
			| foo              |
			| foo              |
			| foo              |
			| foo              |
			| "foo" bar        |
			| "foo" bar{"}     |
			| "foo" bar\} foo  |
			| "foo" bar\{ foo  |
			| foo              |
			| foo1 # "bar"     |
			| "foo " # "bar"   |
		When I replace all strings in my bibliography
		Then the string "foo9" should be "foobar"
		And the string "foo10" should be "foo bar"
		
