# -*- ruby -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'rake/clean'
require 'rake/testtask'

require 'rdoc/task'

require 'bibtex/version'

RDoc::Task.new(:rdoc => ['clean','racc']) do |rd|
  rd.main = 'README.md'
  rd.title = "BibTeX-Ruby Documentation"
  rd.rdoc_files.include('README.md',"lib/**/*.rb")
  rd.rdoc_dir = "doc/html"
  rd.options << '--webcvs=http://github.com/inukshuk/bibtex-ruby/tree/master/'
end

Rake::TestTask.new(:test_task) do |t|
  t.libs << 'lib' << 'test'
  t.test_files = FileList['test/**/test_*.rb']
  t.verbose = true
end

begin
  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new(:features) do |t|
    t.cucumber_opts = "--format progress"
  end
rescue LoadError
  desc 'Cucumber rake task not available'
  task :features do
    abort 'Cucumber rake task is not available. Be sure to install cucumber as a gem or plugin'
  end
end


task :default => ['racc']

desc 'Generates the BibTeX parser'
task :racc => ['lib/bibtex/parser.rb','lib/bibtex/name_parser.rb']

task :test => ['racc','test_task']

file 'lib/bibtex/parser.output' => ['lib/bibtex/parser.rb']
file 'lib/bibtex/parser.rb' => ['lib/bibtex/bibtex.y'] do
  # sh 'racc -v -g -o lib/bibtex/parser.rb lib/bibtex/bibtex.y'
  sh 'bundle exec racc -o lib/bibtex/parser.rb lib/bibtex/bibtex.y'
end

file 'lib/bibtex/name_parser.rb' => ['lib/bibtex/names.y'] do
  # sh 'racc -v -g -o lib/bibtex/name_parser.rb lib/bibtex/names.y'
  sh 'bundle exec racc -o lib/bibtex/name_parser.rb lib/bibtex/names.y'
end

desc 'Runs the benchmarks (and plots the results)'
task :benchmark => ['racc'] do
  require File.expand_path('../test/benchmark.rb', __FILE__)
end
task :bm => ['benchmark']

desc 'Runs the profiler'
task :profile => ['racc'] do
  require File.expand_path('../test/profile.rb', __FILE__)
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
  system "gem push bibtex-ruby-#{BibTeX::Version::STRING}.gem"
end

CLEAN.include('lib/bibtex/parser.rb')
CLEAN.include('lib/bibtex/parser.output')
CLEAN.include('lib/bibtex/name_parser.rb')
CLEAN.include('lib/bibtex/name_parser.output')
CLEAN.include('doc/html')
CLEAN.include('*.gem')

# vim: syntax=ruby