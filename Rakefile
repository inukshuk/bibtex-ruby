# encoding: utf-8

begin
  require 'bundler'
  Bundler.setup
rescue => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

$:.unshift(File.join(File.dirname(__FILE__), './lib'))


require 'rake/clean'
require 'rake/testtask'

require 'bibtex/version'

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  puts 'You need YARD to compile the documentation'
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
    abort 'Cucumber rake task is not available. Please install cucumber as a gem or plugin'
  end
end


task :default => %w(test features)

desc 'Generates the BibTeX parser'
task :racc => %w(lib/bibtex/parser.rb lib/bibtex/name_parser.rb)

task :test => %w(racc test_task)

file 'lib/bibtex/parser.output' => 'lib/bibtex/parser.rb'
file 'lib/bibtex/parser.rb' => 'lib/bibtex/bibtex.y' do
  # sh 'racc -v -g -o lib/bibtex/parser.rb lib/bibtex/bibtex.y'
  sh 'bundle exec racc -o lib/bibtex/parser.rb lib/bibtex/bibtex.y'
end

file 'lib/bibtex/name_parser.rb' => 'lib/bibtex/names.y' do
  # sh 'racc -v -g -o lib/bibtex/name_parser.rb lib/bibtex/names.y'
  sh 'bundle exec racc -o lib/bibtex/name_parser.rb lib/bibtex/names.y'
end

desc 'Run an IRB session with BibTeX-Ruby loaded'
task :console, [:script] do |t,args|
  ARGV.clear

  require 'irb'
  require 'bibtex'

  IRB.conf[:SCRIPT] = args.script
  IRB.start
end


desc 'Runs the benchmarks (and plots the results)'
task :benchmark => :racc do
  require File.expand_path('../test/benchmark.rb', __FILE__)
end
task :bm => :benchmark

desc 'Runs the profiler'
task :profile => :racc do
  require File.expand_path('../test/profile.rb', __FILE__)
end


desc 'Updates the Manifest file'
task :manifest => ['clean', 'racc'] do
  m = File.open('Manifest', 'w')
  m.print FileList['**/*'].reject{ |f|
    f.start_with?('coverage') || f.end_with?('rbc')
  }.join("\n")
  m.close
end

desc 'Builds the gem file'
task :build => ['manifest'] do
  system 'gem build bibtex-ruby.gemspec'
end

desc 'Pushes the gem file to rubygems.org'
task :release => ['build'] do
  system %Q{git tag "#{BibTeX::Version::STRING}"}
  system "git push --tags"
  system "gem push bibtex-ruby-#{BibTeX::Version::STRING}.gem"
end

CLEAN.include('lib/bibtex/parser.rb')
CLEAN.include('lib/bibtex/parser.output')
CLEAN.include('lib/bibtex/name_parser.rb')
CLEAN.include('lib/bibtex/name_parser.output')
CLEAN.include('*.gem')
