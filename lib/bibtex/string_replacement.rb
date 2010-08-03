module BibTeX
  # This module contains functions to manipulate BibTeX
  # string literals.
  module StringReplacement
    
    # Returns a string representation of the literal.
    def self.to_s(value,options={})
      return if value.nil?
      options[:delimiter] ||= ['"','"']
      #options[:delimiter] ||= ['{','}']

      if value.empty? || (value.length == 1 && !value[0].kind_of?(Symbol))
        [options[:delimiter][0],value,options[:delimiter][1]].join
      else
        value.map { |s| s.kind_of?(Symbol) ? s.to_s : s.inspect}.join(' # ')
      end
    end

    # Replaces all string constants in +value+ which are defined in +hsh+.
    def self.replace(value,hsh)
      return if value.nil?
      value.map { |s| s.kind_of?(Symbol) && hsh.has_key?(s) ? hsh[s] : s }.flatten
    end
  end
end
