#--
# BibTeX-Ruby
# Copyright (C) 2010-2011	Sylvester Keil <sylvester.keil.or.at>
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
    
    attr_writer :id
		attr_reader :bibliography
		
		# Returns an array of BibTeX elements.
    def self.parse(string, options = {})
      elements = BibTeX::Parser.new(options).parse(string).data
      elements.each do |e|
        e.parse_names unless !e.respond_to?(:parse_names) || options[:parse_names] == false
        e.parse_month unless !e.respond_to?(:parse_month) || options[:parse_months] == false
      end
      elements
    end
    
		# Returns a string containing the object's content.
		def content(options = {}); ''; end

    # Invokes BibTeX string replacement on this element.
    def replace(*arguments); self; end

    # Invokes BibTeX string joining on this element.
    def join; self; end
    
    # Returns the element's id.
    def id; @id ||= object_id.to_s.intern; end
    
    # Returns the BibTeX type (if applicable) or the normalized class name.
    def type
      self.class.name.split(/::/).last.gsub(/([[:lower:]])([[:upper:]])/) { "#{$1}_#{$2}" }.downcase.intern
    end
  
    def has_type?(type)
      self.type == type.intern || defined?(type) == 'constant' && is_a?(type)
    end
    
    [:entry, :book, :article, :collection, :string, :preamble, :comment]. each do |type|
      method_id = "#{type}?"
      unless method_defined?(method_id)
        define_method(method_id) { has_type?(type) }
        alias_method("is_#{method_id}", method_id)
      end
    end
    
    # Returns true if the element matches the given query.
    def matches?(query)
      return true if !query || query.respond_to?(:empty?) && query.empty?
      
      case query
      when Symbol
        query == id
      when Element
        query == self
      when Regexp
        to_s.match(query)
      when /@(\w+)(?:\[([^\]]*)\])?/
        query.scan(/@(\w+)(?:\[([^\]]*)\])?/).any? do |type, condition|
          has_type?(type) && ( condition.nil? || meets?(condition.split(/,\s*/)) )
        end
      when /^\/(.+)\/$/
        to_s.match(Regexp.new($1))
      else
        id == query.to_sym
      end      
    end
    
    alias === matches?
    alias match? matches?
    
    # Returns true if the element meets all of the given conditions.
    def meets?(*conditions)
      conditions.flatten.all? do |condition|
        property, value = condition.split(/\s*=\s*/)
        property.nil? || send(property).to_s == value
      end
    end
    
    alias meet? meets?
    
		alias to_s content
		
		def to_hash(options = {})
		  { type => content }
	  end
	  
	  def to_yaml(options = {})
	    require 'yaml'
      to_hash.to_yaml
	  end
	  
	  def to_json(options = {})
	    require 'json'
	    to_hash.to_json
	  end
	  
	  def to_xml(options = {})
	    require 'rexml/document'
	    xml = REXML::Element.new(type)
	    xml.text = content
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
		  return nil unless other.respond_to? :type and other.respond_to? :to_s
		  [type, to_s] <=> [other.type, other.to_s]
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
    include Replaceable
    
		attr_reader :key

		# Creates a new instance.
		def initialize(key = nil, value = nil)
		  @key, @value = key.to_sym, Value.new(value)
			yield self if block_given?
		end

		# Sets the string's key (i.e., the symbol identifying the constant).
		def key=(key)
		  raise(ArgumentError, "keys must be convertible to Symbol; was: #{type.class.name}.") unless type.respond_to?(:to_sym)
			
      unless @bibliography.nil?
  			@bibliography.strings.delete(@key)
  			@bibliography.strings[key.to_sym] = self
  		end
  		
			@key = key.to_sym
		end

    # Retuns the string's value if parameter matches the key; nil otherwise.
    def [](key)
      @key == key ? @value : nil
    end
    

		# Called when the element was added to a bibliography.
		def added_to_bibliography(bibliography)
			super
			bibliography.strings[@key] = self
			self
		end
		
		# Called when the element was removed from a bibliography.
		def removed_from_bibliography(bibliography)
			super
			bibliography.strings[@key] = nil
			self
		end

		# Returns a string representation of the @string's content.
		def content
			"#@key = #{@value.to_s(:quotes => '"')}"
		end

		# Returns a string representation of the @string object.
		def to_s(options = {})
			"@string{ #{content} }"
		end
		
		def to_hash(options = {})
		  { :string => { @key => @value.to_s(:quotes => '"') } }
		end
		
		def to_xml(options = {})
		  require 'rexml/document'
	    
		  xml = REXML::Element.new(:string)
		  key = REXML::Element.new(:key)
		  val = REXML::Element.new(:value)
		  key.text = @key.to_s
		  val.text = @value.to_s(:quotes => '"')
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
	  include Replaceable

		# Creates a new instance.
		def initialize(value = '')
      @value = Value.new(value)
		end
    
		# Returns a string representation of the @preamble's content.
		def content
			@value.to_s(:quotes => '"')
		end

		# Returns a string representation of the @preamble object
		def to_s(options = {})
			"@preamble{ #{content} }"
		end
	end

	# Represents a @comment object.
	class Comment < Element
    attr_accessor :content
    
		def initialize(content = '')
			@content = content
		end

		def to_s(options = {})
			"@comment{ #@content }"
		end
	end

	# Represents text in a `.bib' file, but outside of an
	# actual BibTeX object; typically, such text is treated
	# as a comment and is ignored by the parser. 
	# BibTeX-Ruby offers this class to allows for
	# post-processing of this type of `meta' content. If you
	# want the parser to include +MetaComment+ objects, you
	# need to add +:meta_content+ to the parser's +:include+
	# option.
	class MetaContent < Element
	  attr_accessor :content
	  
		def initialize(content = '')
			@content = content
		end

		def to_s(options = {}); @content; end
	end

end
