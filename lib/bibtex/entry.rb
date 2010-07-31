module BibTeX
  class Entry
    attr_reader :values
    attr_accessor :key, :type
    
    def initialize(type, key)
      @key = key
      @type = type
      @values = {}
    end
    
    def <<(value)
      @values.merge{value}
    end

    def to_s
      "@#{type}{#{key}\n" + values.keys.map { |k| "#{k} = {#{values[k]}}" }.join(',\n') + "\n}"
    end
  end
end
