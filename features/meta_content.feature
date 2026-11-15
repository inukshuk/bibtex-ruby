Feature: Text between BibTeX objects
	As a hacker who works with bibliographies
	I want to keep the text between BibTeX objects
	So that a bibliography can also be a document, like written in Markdown

	Scenario: A Markdown document with strings and entries
		When I parse the following file keeping the text between objects:
		"""
		Bibliography
		============
		Here we define a string:

		@string{ thoreau = "Thoreau, Henry David" }

		And here we add a book:

		@book{walden,
		  author = thoreau,
		  title = {Walden; or Life in the Woods},
		  year = 1995
		}

		Neat, huh?
		"""
		And I replace all strings in my bibliography
		And I search for "@entry, @meta_content"
		Then there should be exactly 4 matches
		And my bibliography should contain these books:
			| key    | author               | title                        |
			| walden | Thoreau, Henry David | Walden; or Life in the Woods |
