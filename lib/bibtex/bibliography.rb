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
require 'open-uri'

module BibTeX

  #
  # The Bibliography class models a BibTeX bibliography;
  # typically, it corresponds to a `.bib' file.
  #
  class Bibliography
    extend Forwardable
    
    include Enumerable
    include Comparable
    
    DEFAULTS = { :parse_names => true, :parse_months => true }.freeze
    
    class << self    

      # Opens and parses the `.bib' file at the given +path+. Returns
      # a new Bibliography instance corresponding to the file, or, if a block
      # is given, yields the instance to the block, ensuring that the file
      # is saved after the block's execution (use the :out option if you want
      # to specify a save path other than the path from where the file is
      # loaded).
      #
      # The options argument is passed on to BibTeX::Parser.new. Additional
      # option parameters are:
      #
      # -:parse_names: set to false to disable automatic name parsing
      # -:parse_months: set to false to disable automatic month conversion
      # -:filter: convert all entries using the sepcified filter (not set by default)
      #
      def open(path, options = {})
        b = parse(Kernel.open(path).read, options)
        return b unless block_given?

        begin
          yield b
        ensure
          b.save_to(options[:out] || path)
        end
      end

      # Parses the given string and returns a corresponding Bibliography instance.
      def parse(bibtex, options = {})
        Parser.new(options).parse(bibtex) || Bibliography.new(options)
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
    attr_reader :data, :strings, :entries, :errors, :options

    attr_by_type :article, :book, :journal, :collection, :preamble, :comment, :meta_content
    
    def_delegators :@data, :length, :size, :each, :empty?

    
    #
    # Creates a new bibliography.
    #
    def initialize(options = {})
      @options = DEFAULTS.merge(options)
      @data, @strings, @entries = [], {}, {}

      yield self if block_given?
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
    
    alias << add
    alias push add
    
    # Saves the bibliography to the current path.
    def save(options = {})
      save_to(@path, options)
    end
    
    # Saves the bibliography to a file at the given path. Returns the bibliography.
    def save_to(path, options = {})
      options[:quotes] ||= %w({ })
      File.open(path, "w") { |f| f.write(to_s(options)) }
      self
    end
    
    def parse_names
      @entries.each_value { |e| e.parse_names }
      self
    end
    
    def parse_months
      @entries.each_value { |e| e.parse_month }
      self
    end
    
    # Converts all enties using the given filter. If an optional block is given
    # the block is used as a condition (the block will be called with each
    # entry). @see Entry#convert!
    def convert (filter)
      @entries.each_value { |e| e.convert!(filter) if !block_given? || yield(e) }
      self
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
    
    alias remove delete
    alias rm delete

    #
    # Returns an element or a list of elements according to the given index,
    # range, or query. Contrary to the Bibliography#query this method does
    # not yield to a block for additional refinement of the query.
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
    # valid BibTeX objects (meta content is ignored).
    def valid?
      !errors? && @entries.values.all?(&:valid?)
    end
    
    # Replaces all string symbols which are defined in the bibliography.
    #
    # By default symbols in @string, @preamble and entries are replaced; this
    # behaviour can be changed using the optional query parameter.
    #
    # Note that strings are replaced in the order in which they occur in the
    # bibliography.
    #
    # call-seq:
    # bib.replace #=> replaces all symbols
    # bib.replace('@string, @preamble')
    # #=> replaces only symbols in @string and @preamble objects
    #
    def replace(filter = '')
      q(filter) { |e| e.replace(@strings.values) }
      self
    end
    
    alias :replace_strings :replace

    def join(filter = '')
      q(filter, &:join)
      self
    end
    
    alias join_strings join

    def rename(*arguments, &block)
      q('@entry') { |e| e.rename(*arguments, &block) }
      self
    end
    
    def sort(*arguments, &block)
      @data.sort(*arguments, &block)
      self
    end
    
    # Returns a string representation of the bibliography.
    def to_s(options = {})
      map { |o| o.to_s(options) }.join
    end

    def to_a(options = {})
      map { |o| o.to_hash(options) }
    end
    
    # Returns a Ruby hash representation of the bibliography.
    def to_hash(options = {})
      { :bibliography => map { |o| o.to_hash(options) } }
    end
    
    # Returns a YAML representation of the bibliography.
    def to_yaml(options = {})
      to_a(options).to_yaml
    end
    
    # Returns a JSON representation of the bibliography.
    def to_json(options = {})
      to_a(options).to_json
    end
    
    # Returns a CiteProc JSON representation of the bibliography. Only BibTeX enrties are exported.
    def to_citeproc(options = {})
      q('@entry').map { |o| o.to_citeproc(options) }
    end
    
    # Returns an XML representation of the bibliography. Only BibTeX entries are exported.
    def to_xml
      require 'rexml/document'
	    
      xml = REXML::Document.new
      xml << REXML::XMLDecl.new('1.0','UTF-8')
      root = REXML::Element.new('bibliography')
      each { |e| root.add_element(e.to_xml) }
      xml << root
      xml
    end

    # Returns objects in the Bibliography which match the given selector and,
    # optionally, the conditions specified in the given block.
    #
    # call-seq:
    # bib.query()        #=> returns all objects
    # bib.query(:all)    #=> returns all objects
    # bib.query(:first)  #=> returns the first object
    # bib.query('@book') #=> returns all books
    # bib.query(:first, '@book, @article')
    # #=> returns the first book or article
    # bib.query('@book[year=2011], @article)
    # #=> returns all books published in 2011 and all articles
    # bib.query('@book, @article) { |o| o.year == '2011' }
    # #=> returns all books and articles published in 2011
    # bib.query('@book[year=2011], @article[year=2011])
    # #=> same as above without using a block
    #
    def query(*arguments, &block)
      raise(ArgumentError, "wrong number of arguments (#{arguments.length} for 0..2)") unless arguments.length.between?(0,2)

      q, selector = arguments.reverse
      filter = block ? Proc.new { |e| e.match?(q) && block.call(e) } : Proc.new { |e| e.match?(q) }

      send(query_handler(selector), &filter)
    end
    
    alias q query
        
    def find_by_type(*types, &block)
      q(types.flatten.compact.map { |t| "@#{t}" }.join(', '), &block)
    end
    
    alias find_by_types find_by_type

    def <=>(other)
      other.respond_to?(:to_a) ? to_a <=> other.to_a : nil
    end
    
    private
    
    def query_handler(selector)
      case selector.to_s
      when /first|distinct|detect/i
        :detect
      when /none|reject|not/i
        :reject
      else
        :select
      end
    end
    
  end
end
