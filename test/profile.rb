require File.expand_path('../../lib/bibtex.rb', __FILE__)

require 'rubygems'
require 'bundler/setup'

require 'ruby-prof'

data = File.open(BibTeX::Test.fixtures(:bibdesk)).read

data = <<-END
@book{pickaxe,
	Address = {Raleigh, North Carolina},
	Author = {Thomas, Dave, and Fowler, Chad, and Hunt, Andy},
	Date-Added = {2010-08-05 09:54:07 +0200},
	Date-Modified = {2010-08-05 10:07:01 +0200},
	Keywords = {ruby},
	Publisher = {The Pragmatic Bookshelf},
	Series = {The Facets of Ruby},
	Title = {Programming Ruby 1.9: The Pragmatic Programmer's Guide},
	Year = {2009}
}
END

data = data * 50

result = RubyProf.profile do
  BibTeX.parse(data)
end

printer = RubyProf::DotPrinter.new(result)
printer.print(File.open(File.expand_path('../../profile.dot', __FILE__), 'w'), :min_percent => 5)
