require 'rubygems'
require 'bibtex'


# Open a bibliography file
bib = BibTeX::Bibliography.open(File.expand_path('../markdown.bib',__FILE__),
  :include => [:meta_comments])


# Convert the BibTeX entries into a simple text format
content = bib.data.map do |d|
  result = ''
  
  if d.class == BibTeX::Entry
    d.replace!(bib.strings)
    result = [d.author, '. ', d.title, '. ', d.publisher, ': ', d.address, ', ', d.year, '.'].join
  end
  
  if d.class == BibTeX::MetaComment
    result = d.to_s
  end
  
  result
end

# Convert all non BibTeX text (i.e., the `meta comments') using the maruku gem
require 'maruku'
puts Maruku.new(content.join).to_html_document
