# coding: utf-8

module BibTeX
  begin
    require 'iconv'

    @iconv = Iconv.new('ascii//translit//ignore', 'utf-8')

    def self.transliterate(str)
      @iconv.iconv(str)
    end
  rescue LoadError

    @iconv_replacements = Hash[*%w(ä ae ö oe ü ue Ä Ae Ö Oe Ü Ue ß ss)]

    # Returns +str+ transliterated containing only ASCII characters.
    def self.transliterate(str)
      str.gsub(/[äöüÄÖÜß]/, @iconv_replacements)
    end
  end
end
