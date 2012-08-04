source :rubygems
gemspec

# RDF Export
gem 'rdf', '~>0.3'

group :debug do
	gem 'debugger', :platforms => [:mri_19]
end

group :test do
	gem 'minitest', :platforms => [:ruby_18, :jruby, :rbx]
  gem 'autowatchr', ['~>0.1']
  gem 'cucumber', ['~>1.0']
end

group :profile do
	gem 'ruby-prof', ['~>0.10'], :platforms => [:mri_19, :mri_19]
	gem 'gnuplot', ['~>2.4']
	gem 'simplecov'
end
