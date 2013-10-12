source 'https://rubygems.org'
gemspec

# RDF Export
gem 'rdf', '~>0.3'


group :debug do
	gem 'debugger', :require => false, :platforms => [:mri_19, :mri_20]
	gem 'ruby-debug', :require => false, :platforms => [:mri_18]
end

group :test do
	gem 'minitest', '~>4.0'
  gem 'minitest-colorize'
  gem 'cucumber', ['~>1.0']
  gem 'unicode', :platforms => [:rbx, :mswin, :mingw, :mri_19, :mri_20]
end

group :extra do
	gem 'rb-fsevent', :require => false if RUBY_PLATFORM =~ /darwin/i
	gem 'guard-minitest'
	gem 'guard-cucumber'
	gem 'redcarpet', :platforms => [:rbx, :mri_20, :mri_19]
end

group :profile do
	gem 'ruby-prof', ['~>0.10'], :platforms => [:mri_19, :mri_20]
	gem 'gnuplot', ['~>2.4']
	gem 'simplecov'
end

group :development do
  gem 'rake'
  gem 'racc'
  gem 'yard'	
  gem 'iconv'
end
