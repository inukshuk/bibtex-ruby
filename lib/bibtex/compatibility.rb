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
