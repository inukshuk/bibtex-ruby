require 'rubygems'
require 'bibtex'


# Open a bibliography file
bib = BibTeX.open File.expand_path('../markdown.bib',__FILE__),
  :include => [:meta_content]


# Replaces all strings in the Bibliography and then
# converts each BibTeX entries to a string using Chicago style
# (all other elements are mapped to simple strings)

# TODO 1.3.1
# begin
#   require 'citeproc'
# rescue LoadError
#   puts 'this example depends on the citeproc-ruby gem'
#   exit
# end

content = bib.replace.q('@entry, @meta_content').map do |b|
  if b.entry?  
    [b.author, '. ', b.title, '. ', b.publisher, ': ', b.address, ', ', b.year, '.'].join
  else
    b.to_s
  end
end


begin
  require 'redcarpet'
rescue LoadError
  puts 'this example depends on the redcarpet gem'
  exit
end

puts Redcarpet.new(content.join).to_html
