# -*- ruby -*-

require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'

require './lib/bibtex/version.rb'


spec = Gem::Specification.new do |s|
  s.platform          = Gem::Platform::RUBY
  s.name              = 'bibtex-ruby'
  s.rubyforge_project = s.name
  s.version           = BibTeX::Version::STRING
  s.summary           = "A BibTeX parser written in Ruby"
  s.description       = "A (fairly complete) BibTeX parser written in Ruby. Supports regular BibTeX entries, @comments, string replacement via @string, and simple export formats (e.g. YAML)."
  s.homepage          = 'http://inukshuk.github.com/bibtex-ruby'
  s.authors           = ["Sylvester Keil"]
  s.email             = 'http://sylvester.keil.or.at'
  s.cert_chain        = ["/Users/sylvester/.gem/keys/gem-public_cert.pem"]
  s.signing_key       = '/Users/sylvester/.gem/keys/gem-private_key.pem'
  s.has_rdoc          = true
  s.rdoc_options      = ["--line-numbers", "--inline-source", "--title", "BibTeX-Ruby Documentation", "--main", "README.rdoc"]
  s.extra_rdoc_files  = ["README.md"]
  s.files             = File.open('Manifest').readlines.map(&:chomp)
  s.test_files        = FileList['test/test*.rb']
  s.require_paths     = ["lib"]
  s.date              = Time.now
  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  
  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency('racc', [">= 1.4.6"])
      s.add_development_dependency('minitest', [">= 2.0.2"])
      s.add_development_dependency('json', [">= 1.5.0"])
    else
      s.add_dependency('racc', [">= 1.4.6"])
      s.add_dependency('minitest', [">= 2.0.2"])
      s.add_dependency('json', [">= 1.5.0"])
    end
  else
    s.add_dependency('racc', [">= 1.4.6"])
    s.add_dependency('minitest', [">= 2.0.2"])
    s.add_dependency('json', [">= 1.5.0"])
  end
  
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
  pkg.package_dir = 'build'
end

Rake::RDocTask.new(:rdoc_task) do |rd|
  rd.main = 'README.md'
  rd.title = "BibTeX-Ruby Documentation"
  rd.rdoc_files.include('README.md',"lib/**/*.rb")
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


CLEAN.include('lib/bibtex/parser.rb')
CLEAN.include('lib/bibtex/parser.output')
CLEAN.include('doc/html')
CLEAN.include('build')


# vim: syntax=ruby