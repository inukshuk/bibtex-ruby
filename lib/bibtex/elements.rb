#--
# BibTeX-Ruby
# Copyright (C) 2010	Sylvester Keil <sylvester.keil.or.at>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.	If not, see <http://www.gnu.org/licenses/>.
#++

module BibTeX

	#
	# The base class for BibTeX objects.
	#
	class Element
    include Comparable
    
		attr_reader :bibliography
		
		# Returns an array of BibTeX elements.
    def self.parse(string, options={})
      BibTeX::Parser.new(options).parse(string).to_a
    end
    
		def initialize
			@bibliography = nil
		end
		
		# Returns a string containing the object's content.
		def content
			""
		end

		# Returns a string representation of the object.
		def to_s
			self.content
		end
		
		def to_hash
		  { self.class.name.downcase => content }
	  end
	  
	  def to_yaml
	    require 'yaml'
      self.to_hash.to_yaml
	  end
	  
	  def to_json
	    require 'json'
	    self.to_hash.to_json
	  end
	  
	  def to_xml
	    require 'rexml/document'
	    xml = REXML::Element.new(self.class.name.downcase)
	    xml.text = self.content
	    xml
	  end

		# Called when the element was added to a bibliography.
		def added_to_bibliography(bibliography)
			@bibliography = bibliography
			self
		end
		
		# Called when the element was removed from a bibliography.
		def removed_from_bibliography(bibliography)
			@bibliography = nil
			self
		end
		
		def <=>(other)
		  (type_comparison = self.class.name <=> other.class.name) == 0 ? self.to_s <=> other.to_s : type_comparison
		end
		
	end

 
	#
	# Represents a @string object.
	#
	# In BibTeX @string objects contain a single string constant
	# assignment. For example, @string{ foo = "bar" } defines the
	# constant `foo'; this constant can be used (using BibTeX's
	# string concatenation syntax) in susbsequent
	# @string and @preamble objects, as well as in field values
	# of regular entries.
	#
	class String < Element	  
		attr_reader :key

		# Creates a new instance.
		def initialize(key=nil,value=nil)
			self.key = key.to_sym unless key.nil?
			self.value = value unless value.nil?
		end

		# Sets the string's key (i.e., the name of the constant)
		def key=(key)
			raise(ArgumentError, "BibTeX::String key must be of type Symbol; was: #{key.class.name}.") unless key.is_a?(Symbol)
			@key = key
		end

		# Sets the string's value (i.e., the string literal defined by the constant)
		def value=(value)
			raise(ArgumentError, "BibTeX::String value must be of type Array, Symbol, or String; was: #{value.class.name}.") unless [Array,::String,Symbol].map { |k| value.is_a?(k) }.inject { |sum,n| sum || n }
			@value = Extensions.string_replacement(value.is_a?(Array) ? value : [value])
		end
    
    def value
      @value.to_s(:quotes => %w(" "))
    end
    
		# Replaces all constants in this string's value which are defined in +hash+.
		# Returns the new value (the @string object itself remains unchanged).
		#
		# call-seq:
		# s.to_s
		# => "@string{ foobar = foo # "bar"}"
		# s.replace({:foo => 'bar'})
		# => "\"bar\" # \"bar\""
		# s.to_s
		# => "@string{ foobar = foo # "bar"}"
		def replace(hash)
		  @value.replace_strings(hash)
		end

		# Replaces all constants in this string's value which are defined in +hsh+.
		# Returns the new value (the @string object itself is changed as well).
		#
		# call-seq:
		# s.to_s
		# => "@string{ foobar = foo # "bar"}"
		# s.replace({:foo => 'bar'})
		# => ["bar","bar"]
		# s.to_s
		# => "@string{ foobar = "bar" # "bar"}"
		def replace!(hash)
			@value = @value.replace_strings(hash)
			@bibliography.strings[@key] = @value unless @bibliography.nil?
		end

    def join!
			@value = @value.join_strings
			@bibliography.strings[@key] = @value unless @bibliography.nil?      
    end

		# Adds either a string constant or literal to the current value. The
		# values will be concatenated using the `#' symbol.
		def <<(value)
			raise(ArgumentError, "BibTeX::String value can contain only instances of Symbol or String; was: #{value.class.name}.") unless [::String,Symbol].map { |k| value.is_a?(k) }.inject { |sum,n| sum || n }
			@value << value
		end

		# Called when the element was added to a bibliography.
		def added_to_bibliography(bibliography)
			super(bibliography)
			bibliography.strings[@key] = @value
			self
		end
		
		# Called when the element was removed from a bibliography.
		def removed_from_bibliography(bibliography)
			super(bibliography)
			bibliography.strings[@key] = nil
			self
		end

		# Returns a string representation of the @string's content.
		def content
			[@key.to_s, value].join(' = ')
		end

		# Returns a string representation of the @string object.
		def to_s
			"@string{ #{content} }"
		end
		
		def to_hash
		  { 'string' => { @key.to_s => @value.to_s(:quotes => %w(" ")) } }
		end
		
		def to_xml
		  xml = REXML::Element.new('string')
		  key = REXML::Element.new('key')
		  val = REXML::Element.new('value')
		  key.text = @key.to_s
		  val.text = @value.to_s(:quotes => %w(" "))
		  xml
		end
	end

	#
	# Represents a @preamble object.
	#
	# In BibTeX an @preamble object contains a single string literal,
	# a single constant, or a concatenation of string literals and
	# constants.
	class Preamble < Element
    
		# Creates a new instance.
		def initialize(value=[])
			self.value = value
		end

		def value=(value)
			raise(ArgumentError, "BibTeX::Preamble value must be of type Array, Symbol, or String; was: #{value.class.name}.") unless [Array,::String,Symbol].map { |k| value.is_a?(k) }.inject { |sum,n| sum || n }
			@value = Extensions.string_replacement(value.is_a?(Array) ? value : [value])
		end

		def replace(hash)
			@value.replace_strings(hash)
		end

		def replace!(hash)
			@value = @value.replace_strings(hash)
		end

    def join!
      @value = @value.join_strings
    end

    def value
      content
    end
    
		# Returns a string representation of the @preamble's content.
		def content
			@value.to_s(:quotes => %w(" "))
		end

		# Returns a string representation of the @preamble object
		def to_s
			"@preamble{ #{ content } }"
		end
		
	end

	# Represents a @comment object.
	class Comment < Element

		def initialize(content='')
			self.content = content
		end

		def content=(content)
			raise(ArgumentError, "BibTeX::#{self.class.name} content must be of type String; was: #{content.class.name}.") unless content.is_a?(::String)
			@content = content
		end

		def content
			@content
		end

		def to_s
			['@comment{ ',content,'}'].join
		end
		
	end

	# Represents text in a `.bib' file, but outside of an
	# actual BibTeX object; typically, such text is treated
	# as a comment and is ignored by the parser. 
	# BibTeX-Ruby offers this class to allows for
	# post-processing of this type of `meta' comment. If you
	# want the parser to include +MetaComment+ objects, you
	# need to add +:meta_comments+ to the parser's +:include+
	# option.
	class MetaComment < Comment
		def to_s
			@content
		end
	end

end
