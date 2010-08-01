module BibTeX

  #
  # The base class for BibTeX objects.
  #
  class Element
    include Comparable

    # Returns a string containing the object's content.
    def content
      ""
    end

    def to_s
      self.content
    end

    def <=>(other)
      self.to_s <=> other.to_s
    end

  end

  class RepString
    attr_reader :value

    def initialize(value=[])
      self.value = value
    end

    def value=(value)
      raise(ArgumentError, "BibTeX::RepString value must be of type Array, Symbol, String, or RepString; was: #{value.class.name}.") unless [Array,::String,Symbol,RepString].map { |k| value.kind_of?(k) }.inject { |sum,n| sum || n }
      @value = value.kind_of?(RepString) ? value.value : value.kind_of?(Array) ? value : [value]
    end

    def <<(value)
      raise(ArgumentError, "BibTeX::RepString value can contain only instances of Symbol or String; was: #{value.class.name}.") unless [::String,Symbol].map { |k| value.kind_of?(k) }.inject { |sum,n| sum || n }
      @value << value
    end

    def replace(hsh)
      @value.map { |s| s.kind_of?(Symbol) && hsh.has_key?(s) ? hsh[s] : s }
    end

    def replace!(hsh)
      @value = replace(hsh)
    end

    def to_s
      @value.map { |s| s.kind_of?(Symbol) ? s.to_s : s.inspect}.join(' # ')
    end
  end

  class String < Element
    attr_reader :key, :value

    def initialize(key=:'',value=[])
      self.key = key
      self.value = value
    end

    def key=(key)
      raise(ArgumentError, "BibTeX::String key must be of type Symbol; was: #{key.class.name}.") unless key.kind_of?(Symbol)
      @key = key
    end

    def value=(value)
      @value = RepString.new(value)
    end

    def content
      [@key.to_s,' = ',@value.to_s].join
    end

    def to_s
      ['@string{ ',content,'}'].join
    end
  end

  class Preamble < Element
    attr_reader :value

    def initialize(value=[])
      self.value = value
    end

    def value=(value)
      @value = RepString.new(value)
    end

    def content
      @value.to_s
    end

    def to_s
      ['@preamble{ ',content,'}'].join
    end
  end

  class Comment < Element

    def initialize(content='')
      self.content = content
    end

    def content=(content)
      raise(ArgumentError, "BibTeX::#{self.class.name} content must be of type String; was: #{content.class.name}.") unless content.kind_of?(::String)
      @content = content
    end

    def content
      @content
    end

    def to_s
      ['@comment{ ',content,'}'].join
    end
  end

  class MetaComment < Comment
    def to_s
      @content
    end
  end

  class BadObject < Comment
    def to_s
      @content
    end
  end
end
