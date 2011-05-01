#--
# BibTeX-Ruby
# Copyright (C) 2010-2011  Sylvester Keil <sylvester.keil.or.at>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

require 'forwardable'

module BibTeX

  #
  # The Bibliography class models a BibTeX bibliography;
  # typically, it corresponds to a `.bib' file.
  #
  class Bibliography
    extend Forwardable
    
    include Enumerable
    include Comparable
        
    class << self    
      #
      # Opens and parses the `.bib' file at the given +path+. Returns
      # a new Bibliography instance corresponding to the file.
      #
      # The options argument is passed on to BibTeX::Parser.new.
      #
      def open(path, options = {})
        BibTeX.log.debug("Opening file #{path}")
        Parser.new(options).parse(File.read(path))
      end
      
      #
      # Defines a new accessor that selects elements by type.
      #
      def attr_by_type(*arguments)
        arguments.each do |type|
          method_id = "#{type}s"
          define_method(method_id) { find_by_type(type) } unless respond_to?(method_id)
        end
      end
    end
  
    attr_accessor :path
    attr_reader :data, :strings, :entries, :errors

    alias :to_a :data
    attr_by_type :article, :book, :journal, :collection, :preamble, :comment, :meta_comment
    
    def_delegators :@data, :length, :size, :each, :empty?, :select, :detect, :find, :find_all, :sort

    
    #
    # Creates a new bibliography; empty if no data attribute is specified.
    #
    def initialize(data = [])
      @data = []
      @strings = {}
      @entries = {}
      add(data)
    end
    
    # Adds a new element, or a list of new elements to the bibliography.
    # Returns the Bibliography for chainability.
    def add(*arguments)
      arguments.flatten.each do |element|
        raise(ArgumentError, "Failed to add #{ element.inspect } to Bibliography; instance of BibTeX::Element expected.") unless element.is_a?(Element)
        @data << element.added_to_bibliography(self)
      end
      self
    end
    
    alias :<< :add
    
    # Saves the bibliography to the current path.
    def save
      save_to(@path)
    end
    
    # Saves the bibliography to a file at the given path.
    def save_to(path)
      File.open(path, "w") { |f| f.write(to_s) }
    end
    
    #
    # Deletes an object, or a list of objects from the bibliography.
    # If a list of objects is to be deleted, you can either supply the list
    # of objects or use a query or block to define the list.
    #
    # Returns the object (or the list of objects) that were deleted; nil
    # if the object was not part of the bibliography.
    #
    def delete(*arguments, &block)
      objects = q(*arguments, &block).map { |o| o.removed_from_bibliography(self) }
      @data = @data - objects
      objects.length == 1 ? objects[0] : objects
    end
    
    alias :remove :delete

    #
    # call-seq:
    # >> bib[-1]
    # => Returns the last element of the Bibliography or nil
    # >> bib[1,2]
    # => Returns the second and third elements or nil
    # >> bib[1..2]
    # >> Same as above
    # >> bib[:key]
    # => Returns the first entry with key 'key' or nil
    # >> bib['key']
    # => Returns all entries with key 'key' or []
    # >> bib['@article']
    # => Returns all entries of type 'article' or []
    # >> bib['@preamble']
    # => Returns all preamble objects (this is the same as Bibliography#preambles) or []
    # >> bib[/ruby/]
    # => Returns all objects that match 'ruby' anywhere or []
    # >> bib['@book[keywords=ruby]']
    # => Returns all books whose keywords attribute equals 'ruby' or []
    #
    # Returns an element or a list of elements according to the given index,
    # range, or query. Contrary to the Bibliography#query this method does
    # not yield to a block for additional refinement of the query.
    #
    def [](*arguments)
      raise(ArgumentError, "wrong number of arguments (#{arguments.length} for 1..2)") unless arguments.length.between?(1,2)

      case
      when !([Range, Numeric] & arguments[0].class.ancestors).empty?
        @data[*arguments] 
      when arguments.length == 1 && arguments[0].is_a?(Symbol)
        @entries[arguments[0]]
      else
        query(*arguments)
      end
    end

    # Returns all objects which could not be parsed successfully.
    def errors
      @errors ||= []
    end

    # Returns true if there are object which could not be parsed.
    def errors?
      !errors.empty?
    end

    # Returns true if the +Bibliography+ contains no errors and only
    # valid BibTeX objects (meta comments are ignored).
    def valid?
      !errors? && @entries.values.all?(&:valid?)
    end
    
    # Replaces all string constants which are defined in the bibliography.
    #
    # By default constants in @string, @preamble and entries are defined; this
    # behaviour can be changed using the options argument by setting
    # the :include option to a list of types.
    #
    # Note that strings are replaced in the order in which they occur in the
    # bibliography.
    #
    # call-seq:
    # replace_strings
    # replace_strings({ :filter => [:string, :preamble]})
    #
    def replace_strings(options = {})
      options[:filter] ||= %w{ string preamble entry }
      find_by_type(options[:filter]).each { |e| e.replace!(@strings.values) if e.respond_to?(:replace!)}
    end

    def join_strings(options = {})
      options[:filter] ||= %w{ string preamble entry }
      find_by_type(options[:filter]).each { |e| e.join! if e.respond_to?(:join!)}
    end
    
    # Returns a string representation of the bibliography.
    def to_s
      @data.map(&:to_s).join
    end

    # Returns a Ruby hash representation of the bibliography. Only BibTeX entries are exported.
    def to_hash
      @entries.values.map(&:to_hash)
    end
    
    # Returns a YAML representation of the bibliography. Only BibTeX entries are exported.
    def to_yaml
      to_hash.to_yaml
    end
    
    # Returns a JSON representation of the bibliography. Only BibTeX entries are exported.
    def to_json
      to_hash.to_json
    end
    
    # Returns an XML representation of the bibliography. Only BibTeX entries are exported.
    def to_xml
      xml = REXML::Document.new
      xml << REXML::XMLDecl.new('1.0','UTF-8')
      root = REXML::Element.new('bibliography')
      @entries.values.each { |e| root.add_element(e.to_xml) }
      xml << root
      xml
    end

    def query(*arguments, &block)
      raise(ArgumentError, "wrong number of arguments (#{arguments.length} for 0..2)") unless arguments.length.between?(0,2)

      q, selector = arguments.reverse
      filter = block ? Proc.new { |e| e.match?(q) && block.call(e) } : Proc.new { |e| e.match?(q) }

      send(query_handler(selector), &filter)
    end
    
    alias :q :query
        
    def find_by_type(type)
      return @data if type.nil? || type.respond_to?(:empty?) && type.empty?
      @data.select do |element|
        [type].flatten.any? { |t| element.has_type?(t) }
      end
    end
    
    alias :find_by_types :find_by_type

    def <=>(other)
      other.respond_to?(:to_a) ? other.to_a <=> to_a : nil
    end
    
    private
    
    def query_handler(selector)
      selector && selector.match(/first|distinct|detect/i) ? :detect : :select
    end
    
  end
end
