module BibTeX
  def self.transliterate(str)
    str.unicode_normalize(:nfkd).encode('ASCII', replace: '')
  rescue
    puts "DEBUG: #{str.inspect}"
    puts "DEBUG: #{str.unicode_normalize(:nfkd).inspect}"
    puts "DEBUG: #{str.unicode_normalize(:nfkd).encode('ASCII', replace: '').inspect}"
    'key'
  end
end
