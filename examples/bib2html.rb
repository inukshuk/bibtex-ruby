require 'rubygems'
require 'bibtex'


# Open a bibliography file
bib = BibTeX.open File.expand_path('../markdown.bib',__FILE__),
  :include => [:meta_content]


# Replaces all strings in the Bibliography and then
# converts each BibTeX entries to a string using Chicago style
# (all other elements are mapped to simple strings)

begin
  require 'citeproc'
rescue LoadError
  puts 'this example depends on the citeproc-ruby gem'
  exit
end

content = bib.replace.q('@entry, @meta_content').map do |b|
  if b.entry?  
    CiteProc.process b.to_citeproc
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
