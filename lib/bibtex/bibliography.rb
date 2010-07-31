module BibTeX

  #
  # The Bibliography class models a BibTeX bibliography;
  # typically, it corresponds to a `.bib' file.
  #
  class Bibliography

    attr_accessor :path
    attr_reader :data

    def initialize(data=[])
      raise(ArgumentError, "BibTeX data must be of type Array, was: #{data.class}") unless data.kind_of? Array
      @path = ''
      @data = data
    end

    def open
      @data = BibTeX::Parser.new.parse(File.open(path).read)
    end

    def strings
      find_by_type(BibTeX::String)
    end

    def apply_strings
    end

    def empty?
      @data.empty?
    end

    private

    def find_by_type(type)
      @data.find_all { |x| x.kind_of? type }
    end
  end
end
