require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require 'rake/testtask'
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
  s.name = "bibtex-ruby"
  s.summary = "Parse BibTeX files"
  s.description = File.read(File.join(File.dirname(__FILE__), 'README.textile'))
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
