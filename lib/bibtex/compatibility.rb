# coding: utf-8

unless Symbol.include?(Comparable)
  class Symbol
    include Comparable
    def <=>(other)
      return nil unless other.is_a?(String) || other.is_a?(Symbol)
      to_s <=> other.to_s
    end
  end
end

if RUBY_VERSION < '1.9'
  $KCODE = 'u'
  require 'jcode'
  
  BibTeX::NameParser.patterns[:upper] = /[[:upper:]ÄÖÜ][^\t\r\n\s\{\}\d\\,]*/o
end

module BibTeX
  begin
    require 'iconv'

    @iconv = Iconv.open('ascii//translit//ignore', 'utf-8')

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
