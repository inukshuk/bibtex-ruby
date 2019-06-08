source 'https://rubygems.org'
gemspec

gem 'json', '~>1.8', platforms: %i[mri_18 jruby rbx]

if RUBY_VERSION >= '2.0'
  gem 'rdf', '~>2.0.0'
  gem 'rdf-vocab', '~>2.0.0'
else
  gem 'rdf', '~>1.1'
end

gem 'rubysl', '~>2.0', platforms: :rbx

group :debug do
  if RUBY_VERSION >= '2.0'
    gem 'byebug', require: false, platforms: :mri
  else
    gem 'debugger', require: false, platforms: :mri
  end

  gem 'ruby-debug', require: false, platforms: :jruby

  gem 'rubinius-compiler', require: false, platforms: :rbx
  gem 'rubinius-debugger', require: false, platforms: :rbx
end

group :test do
  gem 'cucumber', '~>1.3'
  gem 'minitest', '~>4.7', require: false
  gem 'minitest-ansi'
  gem 'rubysl-test-unit', '~>2.0', platforms: :rbx
  gem 'unicode', '~>0.4', platforms: %i[rbx mswin mingw mri]
end

group :extra do
  gem 'rb-fsevent', require: false if RUBY_PLATFORM =~ /darwin/i

  gem 'guard-cucumber', platforms: [:ruby]
  gem 'guard-minitest', platforms: [:ruby]
  gem 'redcarpet', platforms: [:ruby]
end

group :profile do
  gem 'gnuplot', '~>2.4', platforms: [:mri]
  gem 'ruby-prof', '~>0.14', platforms: [:mri]
end

group :coverage do
  gem 'coveralls', '~>0.7', require: false
  gem 'rubinius-coverage', require: false, platforms: :rbx
  gem 'simplecov', '~>0.8', require: false, platforms: [:ruby]
end

group :development do
  gem 'iconv', platforms: [:ruby]
  gem 'rake'
  gem 'rubocop', '~> 0.71.0', require: false
  gem 'yard'
end

group :travis do
  # Gem is required at runtime for RBX!
  gem 'racc', platforms: [:ruby]
end
