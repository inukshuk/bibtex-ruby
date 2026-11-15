# frozen_string_literal: true

require 'bundler'
begin
  Bundler.setup
rescue Bundler::BundlerError => e
  warn e.message
  warn 'Run `bundle install` to install missing gems'
  exit e.status_code
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), './lib'))

require 'rake/clean'
require 'rake/testtask'

require 'bibtex/version'

Rake::TestTask.new(:test_task) do |t|
  t.libs << 'lib' << 'test'
  t.test_files = FileList['test/**/test_*.rb']
  # t.verbose = true
end

begin
  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new(:features) do |t|
    t.cucumber_opts = ['--format progress']
  end
rescue LoadError
  desc 'Cucumber rake task not available'
  task :features do
    abort 'Cucumber rake task is not available. Please install cucumber as a gem or plugin'
  end
end

task default: %i[test features]

desc 'Generates the BibTeX parser'
task racc: ['lib/bibtex/parser.rb', 'lib/bibtex/name_parser.rb']

task test: %w[racc test_task]

file 'lib/bibtex/parser.output' => ['lib/bibtex/parser.rb']
file 'lib/bibtex/parser.rb' => ['lib/bibtex/bibtex.y'] do
  # sh 'racc -v -g -o lib/bibtex/parser.rb lib/bibtex/bibtex.y'
  sh 'bundle exec racc -F -l -o lib/bibtex/parser.rb lib/bibtex/bibtex.y'
end

file 'lib/bibtex/name_parser.rb' => ['lib/bibtex/names.y'] do
  # sh 'racc -v -g -o lib/bibtex/name_parser.rb lib/bibtex/names.y'
  sh 'bundle exec racc -F -l -o lib/bibtex/name_parser.rb lib/bibtex/names.y'
end

desc 'Run an IRB session with BibTeX-Ruby loaded'
task :console, [:script] do |_t, args|
  ARGV.clear

  require 'irb'
  require 'bibtex'

  IRB.conf[:SCRIPT] = args.script
  IRB.start
end

desc 'Loads BibTeX-Ruby with warnings enabled and prints its version'
task :check_warnings do
  $VERBOSE = true
  require 'bibtex'

  puts BibTeX::Version::STRING
end

desc 'Benchmarks speed and allocations (N=1000 ITERATIONS=5 WORKLOADS=a,b MEM=1 JSON=out.json COMPARE=base.json)'
task bench: ['racc'] do
  sh Gem.ruby, '-W0', 'benchmark/run.rb'
end
task benchmark: ['bench']
task bm: ['bench']

namespace :bench do
  desc 'Benchmarks the lib/ of another git ref (default: origin/master) and compares it with the working tree'
  task :compare, [:ref] => ['racc'] do |_t, args|
    require 'tmpdir'
    require 'shellwords'
    ref = args[:ref] || 'origin/master'
    abort "bench:compare: #{ref} is not a valid git ref" unless system('git', 'rev-parse', '--verify', '--quiet', "#{ref}^{commit}", out: File::NULL)

    Dir.mktmpdir('bibtex-bench') do |dir|
      sh "git archive #{ref.shellescape} lib | tar -x -C #{dir.shellescape}"
      baseline = File.join(dir, 'baseline.json')
      sh({ 'BIBTEX_LIB' => File.join(dir, 'lib'), 'LABEL' => ref, 'JSON' => baseline }, Gem.ruby, '-W0', 'benchmark/run.rb')
      puts
      sh({ 'BIBTEX_LIB' => nil, 'LABEL' => nil, 'COMPARE' => baseline }, Gem.ruby, '-W0', 'benchmark/run.rb')
    end
  end
end

desc 'Builds the gem file'
task build: %w[clean racc] do
  system 'gem build bibtex-ruby.gemspec'
end

desc 'Pushes the gem file to rubygems.org'
task release: ['build'] do
  system %(git tag "#{BibTeX::Version::STRING}")
  system 'git push --tags'
  system "gem push bibtex-ruby-#{BibTeX::Version::STRING}.gem"
end

CLEAN.include('lib/bibtex/parser.rb')
CLEAN.include('lib/bibtex/parser.output')
CLEAN.include('lib/bibtex/name_parser.rb')
CLEAN.include('lib/bibtex/name_parser.output')
CLEAN.include('*.gem')
