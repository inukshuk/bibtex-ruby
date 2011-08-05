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
  s.summary     = 'A BibTeX parser and converter written in Ruby.'
  s.description = 'A (fairly complete) BibTeX library and parser written in Ruby. Includes a name parser and supports regular BibTeX entries, @comments, string replacement via @string. Allows for easy export/conversion to formats such as YAML, JSON, and XML.'
  s.license     = 'GPL-3'

  s.add_runtime_dependency('latex-decode', ['>=0.0.3'])

  s.add_development_dependency('rake', ['~>0.9'])
  s.add_development_dependency('racc', ['~>1.4'])
  s.add_development_dependency('mini_shoulda', ['~>0.3'])
  s.add_development_dependency('mynyml-redgreen', ['~>0.7'])
  s.add_development_dependency('autowatchr', ['~>0.1'])
  s.add_development_dependency('cucumber', ['~>0.10'])
  s.add_development_dependency('json', ['~>1.5'])
  s.add_development_dependency('rdoc', ['~>3.9'])

  s.files        = File.open('Manifest').readlines.map(&:chomp)
  s.test_files   = Dir.glob('test/**/test*.rb')
  s.executables  = []
  s.require_path = 'lib'

  s.rdoc_options      = %w{--line-numbers --inline-source --title "BibTeX-Ruby\ Documentation" --main README.md --webcvs=http://github.com/inukshuk/bibtex-ruby/tree/master/}
  s.extra_rdoc_files  = %w{README.md}
  
end

# vim: syntax=ruby