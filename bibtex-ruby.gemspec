# frozen_string_literal: true

require_relative 'lib/bibtex/version'

Gem::Specification.new do |s|
  s.name        = 'bibtex-ruby'
  s.version     = BibTeX::Version::STRING.dup
  s.required_ruby_version = '>= 3.3'
  s.authors     = ['Sylvester Keil']
  s.email       = ['sylvester@keil.or.at']
  s.homepage    = 'http://inukshuk.github.com/bibtex-ruby'
  s.license     = 'GPL-3.0-or-later'

  s.summary     = 'A BibTeX parser, converter and API for Ruby.'
  s.description = <<-END_DESCRIPTION.gsub(/^\s+/, '')
    BibTeX-Ruby is the Rubyist's swiss-army-knife for all things BibTeX.
    It includes a parser for all common BibTeX objects
    (@string, @preamble, @comment and regular entries)
    and a sophisticated name parser that tokenizes correctly formatted names;
    BibTeX-Ruby recognizes BibTeX string replacements,
    joins values containing multiple strings or variables,
    supports cross-references,
    and decodes common LaTeX formatting instructions to unicode;
    if you are in a hurry, it also allows for easy export/conversion
    to formats such as YAML, JSON, CSL, and XML (BibTeXML).
  END_DESCRIPTION

  s.add_dependency('latex-decode', ['~>0.0'])
  s.add_dependency('logger', ['~>1.7'])
  s.add_dependency('racc', ['~>1.7'])

  s.files = Dir[
    'lib/**/*.{rb,y}',
    'History.txt',
    'LICENSE',
    'README.md'
  ]

  s.metadata = {
    'source_code_uri' => 'https://github.com/inukshuk/bibtex-ruby',
    'bug_tracker_uri' => 'https://github.com/inukshuk/bibtex-ruby/issues',
    'changelog_uri' => 'https://github.com/inukshuk/bibtex-ruby/blob/master/History.txt',
    'rubygems_mfa_required' => 'true'
  }
end

# vim: syntax=ruby
