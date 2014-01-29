source 'https://rubygems.org'
gemspec

gem 'rdf', '~>1.1'
gem 'json', '~>1.8', :platforms => [:mri_18, :jruby, :rbx]

gem 'rubysl', '~>2.0', :platforms => :rbx

group :debug do
	gem 'debugger', :require => false, :platforms => [:mri_19, :mri_20, :mri_21]
	gem 'ruby-debug', :require => false, :platforms => [:mri_18]
  gem 'rubinius-debugger', :require => false, :platforms => :rbx
  gem 'rubinius-compiler', :require => false, :platforms => :rbx
end

group :test do
	gem 'minitest', '~>4.7', :require => false
  gem 'rubysl-test-unit', '~>2.0', :platforms => :rbx
  gem 'minitest-ansi'
  gem 'cucumber', '~>1.3'
  gem 'unicode', '~>0.4', :platforms => [:rbx, :mswin, :mingw, :mri_19, :mri_20, :mri_21]
	gem 'simplecov', '~>0.8', :require => false, :platforms => [:ruby_21, :ruby_20]
  gem 'rubinius-coverage', :require => false, :platforms => :rbx
  gem 'coveralls', '~>0.7', :require => false
end

group :extra do
  if RUBY_PLATFORM =~ /darwin/i
	  gem 'rb-fsevent', :require => false
  end

	gem 'guard-minitest', :platforms => [:ruby_21, :ruby_20, :ruby_19]
	gem 'guard-cucumber', :platforms => [:ruby_21, :ruby_20, :ruby_19]
	gem 'redcarpet', :platforms => [:ruby_21, :ruby_20, :ruby_19]
end

group :profile do
	gem 'ruby-prof', '~>0.14', :platforms => [:mri_19, :mri_20, :mri_21]
	gem 'gnuplot', '~>2.4', :platforms => [:mri_19, :mri_20, :mri_21]
end

group :development do
  gem 'rake'
  gem 'yard'
  gem 'iconv', :platforms => [:ruby_20, :ruby_21]
end

group :travis do
  # Gem is required at runtime for RBX!
  gem 'racc', :platforms => [:ruby_21, :ruby_20, :ruby_19]
end
