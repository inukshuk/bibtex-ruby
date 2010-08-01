module BibTeX
  class Entry < Element
    attr_reader :key, :type, :values
    
    def initialize(type, key)
      self.key = key
      self.type = type
      @values = {}
    end

    def key=(key)
      raise(ArgumentError, "BibTeX::Entry key must be of type String; was: #{key.class.name}.") unless key.kind_of?(::String)
      @key = key
    end

    def type=(type)
      raise(ArgumentError, "BibTeX::Entry type must be of type Symbol; was: #{type.class.name}.") unless type.kind_of?(Symbol)
      @type = type
    end
    
    def <<(value)
      @values = @values.merge(value)
      self
    end

    def empty?
      @values.empty?
    end

    def valid?
    end

    def content
      "@#{type}{#{key}\n" + values.keys.map { |k| "#{k} = {#{values[k]}}" }.join(",\n") + "\n}"
    end
  end
end
