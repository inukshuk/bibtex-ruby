# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'bibtex/version'

Gem::Specification.new do |s|
  s.name        = 'bibtex-ruby'
  s.version     = BibTeX::Version::STRING.dup
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Sylvester Keil']
  s.email       = ['http://sylvester.keil.or.at']
  s.homepage    = 'http://inukshuk.github.com/bibtex-ruby'
  s.license     = 'GPL-3'

  s.summary     = 'A BibTeX parser, converter and API for Ruby.'
  s.description = <<-END_DESCRIPTION
		BibTeX-Ruby is the Rubyist's swiss-army-knife for all things BibTeX. It
    includes a parser for all common BibTeX objects (@string, @preamble,
    @comment and regular entries) and a sophisticated name parser that
    tokenizes correctly formatted names; BibTeX-Ruby recognizes BibTeX string
    replacements, joins values containing multiple strings or variables,
    supports cross-references, and decodes common LaTeX formatting
    instructions to unicode; if you are in a hurry, it also allows for easy
    export/conversion to formats such as YAML, JSON, CSL, and XML (BibTeXML).
	END_DESCRIPTION
	
  s.add_runtime_dependency('latex-decode', ['>=0.0.3'])
  s.add_runtime_dependency('multi_json', ['~>1.0'])

  s.add_development_dependency('rake', ['~>0.9'])
  s.add_development_dependency('racc', ['~>1.4'])
  s.add_development_dependency('rdoc', ['~>3.9'])

  s.files        = File.open('Manifest').readlines.map(&:chomp)
  s.test_files   = Dir.glob('test/**/test*.rb')
  s.executables  = []
  s.require_path = 'lib'

  s.rdoc_options      = %w{--line-numbers --inline-source --title "BibTeX-Ruby\ Documentation" --main README.md --webcvs=http://github.com/inukshuk/bibtex-ruby/tree/master/}
  s.extra_rdoc_files  = %w{README.md}
  
end

# vim: syntax=ruby