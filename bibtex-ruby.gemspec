# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'bibtex/version'

Gem::Specification.new do |s|
  s.name              = 'bibtex-ruby'
  s.version           = BibTeX::Version::STRING.dup
  s.platform          = Gem::Platform::RUBY
  s.authors           = ['Sylvester Keil']
  s.email             = 'http://sylvester.keil.or.at'
  s.homepage          = 'http://inukshuk.github.com/bibtex-ruby'
  s.summary           = 'A BibTeX parser and converter written in Ruby.'
  s.description       = 'A (fairly complete) BibTeX parser written in Ruby. Supports regular BibTeX entries, @comments, string replacement via @string. Allows for easy export/conversion to formats such as YAML, JSON, and XML.'
  s.date              = Time.now

  s.required_rubygems_version = '>= 1.3.6'
  s.rubyforge_project = s.name

  s.add_development_dependency('racc', ['>= 1.4'])
  s.add_development_dependency('minitest', ['>= 2.0'])
  s.add_development_dependency('shoulda', ['>= 2.11'])
  s.add_development_dependency('json', ['>= 1.5'])

  s.files             = File.open('Manifest').readlines.map(&:chomp)
  s.test_files        = Dir.glob('test/test*.rb')
  s.executables       = []
  s.require_path      = 'lib'

  s.has_rdoc          = true
  s.rdoc_options      = %w{--line-numbers --inline-source --title "BibTeX-Ruby Documentation" --main README.md --webcvs=http://github.com/inukshuk/bibtex-ruby/tree/master/}
  s.extra_rdoc_files  = %w{README.md}
  
end

# vim: syntax=ruby