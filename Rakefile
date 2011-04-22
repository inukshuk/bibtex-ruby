# -*- ruby -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rake/rdoctask'

require 'bibtex/version'

Rake::RDocTask.new(:rdoc_task) do |rd|
  rd.main = 'README.md'
  rd.title = "BibTeX-Ruby Documentation"
  rd.rdoc_files.include('README.md',"lib/**/*.rb")
  rd.rdoc_dir = "doc/html"
  rd.options << '--webcvs=http://github.com/inukshuk/bibtex-ruby/tree/master/'
end

Rake::TestTask.new(:test_task) do |t|
  t.libs << 'lib' << 'test'
  t.test_files = FileList['test/test_*.rb']
  t.verbose = true
end

task :default => ['racc']

desc 'Generates the BibTeX parser'
task :racc => ['lib/bibtex/parser.rb']

desc 'Generates RDoc documentation for BibTeX-Ruby'
task :rdoc => ['clean','racc','rdoc_task']

task :test => ['racc','test_task']

file 'lib/bibtex/parser.output' => ['lib/bibtex/parser.rb']
file 'lib/bibtex/parser.rb' => ['lib/bibtex/bibtex.y'] do
  sh 'racc -v -g -o lib/bibtex/parser.rb lib/bibtex/bibtex.y'
end

desc 'Updates the Manifest file'
task :manifest => ['clean', 'racc'] do
  m = File.open('Manifest', 'w')
  m.print FileList['**/*'].join("\n")
  m.close
end

desc 'Builds the gem file'
task :build => ['manifest'] do
  system 'gem build bibtex-ruby.gemspec'
end

desc 'Pushes the gem file to rubygems.org'
task :release => ['build'] do
  system "gem push bibtex-ruby-#{BibTeX::Version::STRING}"
end

CLEAN.include('lib/bibtex/parser.rb')
CLEAN.include('lib/bibtex/parser.output')
CLEAN.include('doc/html')
CLEAN.include('*.gem')

# vim: syntax=ruby