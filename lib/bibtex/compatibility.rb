module BibTeX
  def self.transliterate(str)
    str.unicode_normalize(:nfkd).encode('ASCII', replace: '')
  rescue
    str.encode('ASCII', replace: '')
  end
end
