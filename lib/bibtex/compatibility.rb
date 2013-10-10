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
  # Returns true if Iconv is defined.
  # Tries to load the gem if not. Returns true if successful.
  def self.iconv_defined?
    @@uses_iconv ||= defined?(Iconv) || begin
      require 'iconv'
    rescue LoadError
      BibTeX.log.error "Please gem install iconv for Iconv support."
      false
    end
  end
  
  # Returns +str+ transliterated containing only ASCII characters.
  def self.transliterate(str)
    if self.iconv_defined?
      @@iconv ||= Iconv.open('ascii//translit//ignore', 'utf-8')
      @@iconv.iconv(str)
    else
      @@replacements ||= Hash[*%w(ä ae ö oe ü ue Ä Ae Ö Oe Ü Ue ß ss)]
      str.gsub(/[äöüÄÖÜß]/, @@replacements)
    end
  end
end
