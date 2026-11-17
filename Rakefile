# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/clean'
require 'rake/testtask'
require 'cucumber/rake/task'

Rake::TestTask.new(:test) do |t|
  t.deps = [:racc]
  t.libs << 'lib' << 'test'
  t.test_files = FileList['test/**/test_*.rb']
end

Cucumber::Rake::Task.new(:features)

task default: %i[test features]

desc 'Generates the BibTeX parser'
task racc: ['lib/bibtex/parser.rb', 'lib/bibtex/name_parser.rb']

task build: %w[clean racc]

file 'lib/bibtex/parser.rb' => ['lib/bibtex/bibtex.y'] do
  sh 'bundle exec racc -F -l -o lib/bibtex/parser.rb lib/bibtex/bibtex.y'
end

file 'lib/bibtex/name_parser.rb' => ['lib/bibtex/names.y'] do
  sh 'bundle exec racc -F -l -o lib/bibtex/name_parser.rb lib/bibtex/names.y'
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

CLEAN.include('lib/bibtex/parser.rb')
CLEAN.include('lib/bibtex/parser.output')
CLEAN.include('lib/bibtex/name_parser.rb')
CLEAN.include('lib/bibtex/name_parser.output')
CLEAN.include('pkg')
