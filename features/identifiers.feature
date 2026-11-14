Feature: Identifier characters in field names, @string names and macro references
	As a hacker who works with bibliographies
	I want to parse every identifier that BibTeX itself accepts
	Because exported bibliographies use field names like "a/b" or "p[1]"

	Scenario Outline: A field name containing <name> (<mode>)
		When I parse the following file with options <options>:
		"""
		@misc{key, <name> = {value}, title = {Title}}
		@misc{other, title = {Other}}
		"""
		Then my bibliography should contain 2 misc
		And the entry with key "key" should have a field "<name>" with the value "value"
		And the entry with key "key" should have a field "title" with the value "Title"

		Examples:
			| name | mode                            | options                             |
			| a/b  | strict                          | strict: true                        |
			| x;y  | strict                          | strict: true                        |
			| p[1] | strict                          | strict: true                        |
			| a\|b | strict                          | strict: true                        |
			| a^b  | strict                          | strict: true                        |
			| a~b  | strict                          | strict: true                        |
			| a<b> | strict                          | strict: true                        |
			| a@b  | strict                          | strict: true                        |
			| a/b  | non-strict                      | strict: false                       |
			| x;y  | non-strict                      | strict: false                       |
			| p[1] | non-strict                      | strict: false                       |
			| a\|b | non-strict                      | strict: false                       |
			| a^b  | non-strict                      | strict: false                       |
			| a~b  | non-strict                      | strict: false                       |
			| a<b> | non-strict                      | strict: false                       |
			| a@b  | non-strict                      | strict: false                       |
			| a/b  | strict with :strip_comments     | strip_comments: true                |
			| a@b  | strict with :strip_comments     | strip_comments: true                |
			| p[1] | non-strict with :strip_comments | strict: false, strip_comments: true |
			| a<b> | non-strict with :strip_comments | strict: false, strip_comments: true |

	Scenario Outline: A @string named <name> and a reference to it (<mode>)
		When I parse the following file with options <options>:
		"""
		@string{ <name> = "Journal of Examples" }
		@article{key, journal = <name>, title = {Title}}
		"""
		And I replace all strings in my bibliography
		Then the string "<name>" should be "Journal of Examples"
		And the entry with key "key" should have a field "journal" with the value "Journal of Examples"

		Examples:
			| name | mode                        | options              |
			| a/b  | strict                      | strict: true         |
			| x;y  | strict                      | strict: true         |
			| p[1] | strict                      | strict: true         |
			| a\|b | strict                      | strict: true         |
			| a^b  | strict                      | strict: true         |
			| a~b  | strict                      | strict: true         |
			| a<b> | strict                      | strict: true         |
			| a@b  | strict                      | strict: true         |
			| a@b  | non-strict                  | strict: false        |
			| x;y  | strict with :strip_comments | strip_comments: true |

	Scenario: Percent signs in names depend on :strip_comments
		When I parse the following file with options strict: true:
		"""
		@string{ a/b%c = "with percent" }
		@misc{key, x%y = a/b%c}
		"""
		And I replace all strings in my bibliography
		Then the entry with key "key" should have a field "x%y" with the value "with percent"

	Scenario: Percent signs start a comment with :strip_comments
		When I parse the following file with options strip_comments: true:
		"""
		@string{ a/b = "no percent" } % a comment
		@misc{key,
		  x;y = a/b % a comment
		}
		"""
		And I replace all strings in my bibliography
		Then the entry with key "key" should have a field "x;y" with the value "no percent"

	Scenario: Field names made of several words in non-strict mode
		When I parse the following file with options strict: false:
		"""
		@misc{key, Early/Access Date[1] = {NOV}}
		"""
		Then the entry with key "key" should have a field "early/access_date[1]" with the value "NOV"

	Scenario Outline: Keys containing '/' with <options>
		When I parse the following file with options <options>:
		"""
		@article{DBLP:journals/dq/RossinK99, title = {Data Errors}}
		"""
		Then my bibliography should contain an article with id "DBLP:journals/dq/RossinK99"

		Examples:
			| options                                   |
			| strict: true                              |
			| strict: false                             |
			| strip_comments: true                      |
			| allow_missing_keys: true                  |
			| strip_comments: true, allow_missing_keys: true |
