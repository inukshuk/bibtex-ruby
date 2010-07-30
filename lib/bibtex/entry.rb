module BibTeX
  class Entry
    attr_reader :values
    attr_accessor :id, :type
    
    def initialize
      @id = 0
      @type = ''
      @values = {}
    end
    
    def to_s
      "@#{type}{#{id}\n" + values.keys.map { |k| "#{k} = {#{values[k]}}" }.join(',\n') + "\n}"
    end
  end
end
