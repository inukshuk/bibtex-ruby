module BibTeX
  def self.transliterate(str)
    str.unicode_normalize(:nfkd).encode('ASCII', replace: '')
  rescue
    puts "DEBUG: #{str.inspect}"
    'key'
  end
end
