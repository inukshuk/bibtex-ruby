require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/rdoctask'
require 'rake/testtask'
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
  s.name = "bibtex-ruby"
  s.summary = "Parse BibTeX files"
  s.description = File.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
  s.requirements << 'racc (for parser generation)'
  s.version = '0.0.1'
  s.author = "Sylvester Keil"
  s.email = "sylvester@keil.or.at"
  s.homepage = "http://sylvester.keil.or.at"
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.8.1'
  s.files = Dir['**/**']
  s.test_files = Dir['test/test*.rb']
  s.has_rdoc = true
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar_bz2
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
