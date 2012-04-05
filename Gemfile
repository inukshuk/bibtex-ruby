source :rubygems
gemspec

group :debug do
	gem 'debugger', :platforms => [:mri_19]
	gem 'ruby-debug', :platforms => [:mri_18]
	gem 'rbx-trepanning', :platforms => [:rbx]
end

group :test do
	gem 'minitest', :platforms => [:ruby_18, :jruby, :rbx]
  gem 'mynyml-redgreen', ['~>0.7']
  gem 'autowatchr', ['~>0.1']
  gem 'cucumber', ['~>1.0']
end

group :profile do
	gem 'ruby-prof', ['~>0.10'], :platforms => [:mri_19, :mri_19]
	gem 'gnuplot', ['~>2.3']
end