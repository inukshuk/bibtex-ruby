source :rubygems
gemspec

group :debug do
	gem 'ruby-debug19', :require => 'ruby-debug', :platforms => [:mri_19]
	gem 'ruby-debug', :platforms => [:mri_18]
	gem 'rbx-trepanning', :platforms => [:rbx]
end

group :profile do
	gem 'ruby-prof', ['~>0.10']
	gem 'gnuplot', ['~>2.3']
end