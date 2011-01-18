# -*- ruby -*-

require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/rdoctask'
require 'rake/testtask'
require 'echoe'

Echoe.new('bibtex-ruby', '1.0.0') do |p|
  p.description    = "A BibTeX parser written in Ruby"
  p.url            = "http://github.com/inukshuk/bibtex-ruby"
  p.author         = "Sylvester Keil"
  p.email          = "http://sylvester.keil.or.at"
  p.ignore_pattern = []
  p.development_dependencies = [['racc', '>=1.4.6']]
  p.need_tgz       = true
  p.rdoc_options   = ["--line-numbers", "--inline-source", "--title", "BibTeX-Ruby Documentation", "--main", "README.rdoc"]
end

Rake::RDocTask.new(:rdoc_task) do |rd|
  rd.main = 'README.rdoc'
  rd.title = "BibTeX-Ruby Documentation"
  rd.rdoc_files.include('README.rdoc',"lib/**/*.rb")
  rd.rdoc_dir = "doc/html"
  rd.options << '--webcvs=http://github.com/inukshuk/bibtex-ruby/tree/master/'
end

Rake::TestTask.new(:test_task) do |t|
  t.libs << "test"
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end

task :default => ['racc']

desc 'Generates the BibTeX parser'
task :racc => ['lib/bibtex/parser.rb']

desc 'Generates RDoc documentation for BibTeX-Ruby'
task :rdoc => ['clean','racc','rdoc_task']

task :test => ['racc','test_task']

file 'lib/bibtex/parser.rb' => ['lib/bibtex/bibtex.y'] do
  sh 'racc -v -g -o lib/bibtex/parser.rb lib/bibtex/bibtex.y'
end

CLEAN.include('lib/bibtex/parser.rb')
CLEAN.include('lib/bibtex/parser.output')
CLEAN.include('doc/html')


# vim: syntax=ruby