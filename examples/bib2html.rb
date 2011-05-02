require 'rubygems'
require 'bibtex'


# Open a bibliography file
bib = BibTeX.open(File.expand_path('../markdown.bib',__FILE__),
  :include => [:meta_content])


# Convert the BibTeX entries into a simple text format
content = bib.data.map do |d|
  result = ''
  
  if d.class == BibTeX::Entry
    d.replace!(bib.strings)
    result = [d.author, '. ', d.title, '. ', d.publisher, ': ', d.address, ', ', d.year, '.'].join
  end
  
  if d.class == BibTeX::MetaContent
    result = d.to_s
  end
  
  result
end

# Convert all non BibTeX text (i.e., the `meta content') using the maruku gem
require 'maruku'
puts Maruku.new(content.join).to_html_document
