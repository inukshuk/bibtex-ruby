Feature: Parse BibTeX files and convert LaTeX to Unicode
	As a hacker who works with bibliographies
	I want to be able to parse BibTeX files containing LaTeX strings and
	convert them to Unicode

	@latex
	Scenario: A BibTeX file containing a LaTeX umlaut
		When I parse the following file:
		"""
		@misc{issue16,
		  author = {rbq},
		  title  = {An umlaut: \"u!},
		  year   = 2011,
		}
		"""
		Then my bibliography should contain an entry with key "issue16"
		When I convert all entries using the filter "latex"
		Then the entry with key "issue16" should have a field "title" with the value "An umlaut: ü!"
