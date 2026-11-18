# frozen_string_literal: true

# Top-level convenience methods for opening and parsing bibliographies
# and names.
module BibTeX
  class << self
    # Opens a BibTeX file or URI and returns a corresponding +Bibliography+
    # object or, if a block is given, yields the Bibliography to the block,
    # ensuring that the file is saved.
    def open(file, options = {}, &)
      Bibliography.open(file, options, &)
    end

    # Parses the given string and returns a corresponding +Bibliography+ object.
    # Delegates to BibTeX.open if the string is a filename or URI.
    def parse(string, options = {}, &)
      if string.length < 260 && File.exist?(string)
        Bibliography.open(string, options, &)
      elsif %r{\A[a-z]+://}i.match?(string)
        Bibliography.open(string, options)
      else
        Bibliography.parse(string, options)
      end
    end

    # Returns true if the given file is a valid BibTeX bibliography.
    def valid?(file)
      Bibliography.open(file).valid?
    end

    # Parses the given string as a BibTeX name value and returns a Names object.
    def names(string)
      Names.parse(string)
    end

    alias name names
    alias parse_name names
    alias parse_names names
  end
end
