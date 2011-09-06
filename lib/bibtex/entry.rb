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

require 'forwardable'

module BibTeX
	#
	# Represents a regular BibTeX entry.
	#
	class Entry < Element
	  extend Forwardable	  
	  include Enumerable

		# Hash containing the required fields of the standard entry types
		REQUIRED_FIELDS = Hash.new([]).merge({
			:article       => [:author,:title,:journal,:year],
			:book          => [[:author,:editor],:title,:publisher,:year],
			:booklet       => [:title],
			:conference    => [:author,:title,:booktitle,:year],
			:inbook        => [[:author,:editor],:title,[:chapter,:pages],:publisher,:year],
			:incollection  => [:author,:title,:booktitle,:publisher,:year],
			:inproceedings => [:author,:title,:booktitle,:year],
			:manual        => [:title],
			:mastersthesis => [:author,:title,:school,:year],
			:misc          => [],
			:phdthesis     => [:author,:title,:school,:year],
			:proceedings   => [:title,:year],
			:techreport    => [:author,:title,:institution,:year],
			:unpublished   => [:author,:title,:note]
		}).freeze

    NAME_FIELDS = [:author,:editor,:translator].freeze
    DATE_FIELDS = [:year,:month].freeze
    
    MONTHS = [:jan,:feb,:mar,:apr,:may,:jun,:jul,:aug,:sep,:oct,:nov,:dec].freeze

    MONTHS_FILTER = Hash.new do |h,k|
      case k.to_s.strip
      when /^(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)/i
        h[k] = Value.new(k.to_s[0,3].downcase.to_sym)
      when /^\d\d?$/
        h[k] = Value.new(MONTHS[k.to_i - 1] || k)
      else
        h[k] = Value.new(k)
      end
    end
    
    CSL_FILTER = Hash.new {|h,k|k}.merge(Hash[*%w{
      date      issued
      isbn      ISBN
      booktitle container-title
      journal   container-title
      series    collection-title
      address   publisher-place
      pages     page
      number    issue
      url       URL
      doi       DOI
      year      issued
    }.map(&:intern)]).freeze

    CSL_FIELDS = %w{ abstract annote archive archive_location archive-place
      authority call-number chapter-number citation-label citation-number
      collection-title container-title DOI edition event event-place
      first-reference-note-number genre ISBN issue jurisdiction keyword locator 
      medium note number number-of-pages number-of-volumes original-publisher
      original-publisher-place original-title page page-first publisher
      publisher-place references section status title URL version volume
      year-suffix accessed container event-date issued original-date
      author editor translator recipient interviewer publisher composer
      original-publisher original-author container-author collection-editor
    }.map(&:intern).freeze
    
    CSL_TYPES = Hash.new {|h,k|k}.merge(Hash[*%w{
      booklet        pamphlet
      conference     paper-conference
      inbook         chapter
      incollection   chapter
      inproceedings  paper-conference
      manual         book
      mastersthesis  thesis
      misc           article
      phdthesis      thesis
      proceedings    paper-conference
      techreport     report
      unpublished    manuscript
    }.map(&:intern)]).freeze

	  
		attr_reader :fields, :type		
    def_delegators :@fields, :empty?, :each, :each_pair

		# Creates a new instance. If a hash is given, the entry is populated accordingly.
		def initialize(attributes = {})
			@fields = {}
		  
		  self.type = attributes.delete(:type) if attributes.has_key?(:type)
		  self.key = attributes.delete(:key) if attributes.has_key?(:key)
			
			add(attributes)
			
			yield self if block_given?
		end

    def initialize_copy (other)
      @fields = {}
      
      self.type = other.type
      self.key = other.key
      
      add(other.fields)
    end
    
		# Sets the key of the entry
		def key=(key)
			raise(ArgumentError, "keys must be convertible to Symbol; was: #{type.class.name}.") unless type.respond_to?(:to_sym)

      unless @bibliography.nil?
  			@bibliography.entries.delete(@key)
  			@bibliography.entries[key] = self
      end

			@key = key.to_sym
		end
		
		def key
		  @key ||= default_key
		end

		alias id key
		alias id= key=

		# TODO we should be more lenient: allow strings as key or don't check at all
		# Sets the type of the entry.
		def type=(type)
			raise(ArgumentError, "types must be convertible to Symbol; was: #{type.class.name}.") unless type.respond_to?(:to_sym)
			@type = type.to_sym
		end
		
		def has_type?(type)
			type.to_s.match(/^entry$/i) || @type == type.to_sym || super
		end
    
    def has_field?(field)
      @fields.has_key?(field)
    end
    
		def method_missing(name, *args, &block)
			case
			when @fields.has_key?(name)
				@fields[name]
			when name.to_s =~ /^(.+)=$/
				send(:add, $1.to_sym, args[0]) 		  
			when name =~ /^(?:convert|from)_([a-z]+)(!)?$/
				$2 ? convert!($1, &block) : convert($1, &block)
			else
				super
			end
		end

		def respond_to?(method)
		  @fields.has_key?(method.to_sym) || method.to_s.match(/=$/) || method =~ /^(?:convert|from)_([a-z]+)(!)?$/ || super
		end
		
		# Returns a copy of the Entry with all the field names renamed.
		def rename(*arguments)
		  dup.rename!(*arguments)
		end
		
		# Renames the given field names unless a field with the new name already
		# exists.
		def rename!(*arguments)
			Hash[*arguments.flatten].each_pair do |from,to|
				if @fields.has_key?(from) && !@fields.has_key?(to)
					@fields[to] = @fields[from]
					@fields.delete(from)
				end
			end
			self
		end

		alias :rename_fields :rename
		alias :rename_fields! :rename!
		
		# Returns the value of the field with the given name.
		def [](name)
			@fields[name.to_sym]
		end

		# Adds a new field (name-value pair) to the entry.
		# Returns the new value.
		def []=(name, value)
			add(name.to_sym, value)
		end

		# Adds a new field (name-value pair) or multiple fields to the entry.
		# Returns the entry for chainability.
		#
		# call-seq:
		# add(:author, "Edgar A. Poe")
		# add(:author, "Edgar A. Poe", :title, "The Raven")
		# add([:author, "Edgar A. Poe", :title, "The Raven"])
		# add(:author => "Edgar A. Poe", :title => "The Raven")
		#
		def add(*arguments)
		  Hash[*arguments.flatten].each_pair do |name, value|
			  @fields[name.to_sym] = Value.new(value)
			end
			self
		end
		
		alias << add

		# Removes the field with a given name from the entry.
		# Returns the value of the deleted field; nil if the field was not set.
		def delete(name)
			@fields.delete(name.to_sym)
		end

		# Returns false if the entry is one of the standard entry types and does not have
		# definitions of all the required fields for that type.
		def valid?
			REQUIRED_FIELDS[@type].all? do |f|
				f.is_a?(Array) ? !(f & @fields.keys).empty? : !@fields[f].nil?
			end
		end

		# Called when the element was added to a bibliography.
		def added_to_bibliography(bibliography)
			super
			bibliography.entries[key] = self
			parse_names if bibliography.options[:parse_names]
			parse_months if bibliography.options[:parse_months]
			convert(bibliography.options[:filter]) if bibliography.options[:filter]
			self
		end
				
		# Called when the element was removed from a bibliography.
		def removed_from_bibliography(bibliography)
			super
			bibliography.entries[key] = nil
			self
		end

		def replace(*arguments)
		  arguments = bibliography.q('@string') if arguments.empty?
			@fields.values.each { |v| v.replace(*arguments) }
			self
		end

    def join
			@fields.values.each(&:join)
      self
    end

    def month=(month)
      @fields[:month] = MONTHS_FILTER[month]
    end
    
    def parse_month
      @fields[:month] = MONTHS_FILTER[@fields[:month]] if @fields.has_key?(:month)
      self
    end
    
    alias parse_months parse_month
    
    # Parses all name values of the entry. Tries to replace and join the
    # value prior to parsing.
    def parse_names
      strings = bibliography ? bibliography.strings.values : []
      NAME_FIELDS.each do |key|
        if name = @fields[key]
          name.replace(strings).join
          name = name.to_name
          @fields[key] = name
        end
      end
      self
    end
    
		# Returns a string of all the entry's fields.
		def content(options = {})
			@fields.map { |k,v| "#{k} = #{ @fields[k].to_s(options) }" }.join(",\n")
		end

		# Returns a string representation of the entry.
		def to_s(options = {})
		  options[:quotes] ||= %w({ })
			["@#{type}{#{key},", content(options).gsub(/^/,'  '), "}\n"].join("\n")
		end
		
		def to_hash(options = {})
		  options[:quotes] ||= %w({ })
		  hash = { :key => key, :type => type }
		  each_pair { |k,v| hash[k] = v.to_s(options) }
		  hash
		end

		def to_citeproc(options = {})
		  options[:quotes] ||= []
		  hash = { 'id' => key.to_s, 'type' => CSL_TYPES[type].to_s }
      each_pair do |k,v|
		    hash[CSL_FILTER[k].to_s] = v.to_citeproc(options) unless DATE_FIELDS.include?(k)
		  end
		  hash['issued'] = citeproc_date
		  hash
		end
		
		def issued
		  m = MONTHS.find_index(@fields[:month] && @fields[:month].v)
		  m = m + 1 unless m.nil?
		  { 'date-parts' => [[@fields[:year],m].compact.map(&:to_i)] }
		end
		
		alias citeproc_date issued
		
		def to_xml(options = {})
		  require 'rexml/document'
	    
  		xml = REXML::Element.new(type)
  		xml.attributes['key'] = key
      @fields.each do |k,v|
        e = REXML::Element.new(k.to_s)
        e.text = v.to_s(options)
        xml.add_element(e)
      end
      xml
		end
		
		# Returns a duplicate entry with all values converted using the filter.
		# If an optional block is given, only those values will be converted where
		# the block returns true (the block will be called with each key-value pair).
		#
		# @see convert!
		#
		def convert (filter)
		  block_given? ? dup.convert!(filter, &Proc.new) : dup.convert!(filter)
		end
		
		# In-place variant of @see convert
		def convert! (filter)
		  @fields.each_pair { |k,v| !block_given? || yield(k,v) ? v.convert!(filter) : v }
		  self
		end
		
		def <=>(other)
		  type != other.type ? type <=> other.type : key != other.key ? key <=> other.key : to_s <=> other.to_s
		end
		
		protected
		
		def default_key
			a = case fields[:author]
			when Names
				author[0].last
			when Value
				author.to_s[/\w+/]
			else
				nil
			end
			
			case
			when a && has_field?(:year) && has_field?(:title)
				[a,year,title.to_s[/\w{4,}/]].join.downcase.to_sym
			when a && has_field?(:year)
				[a,year].join.downcase.to_sym
			when has_field?(:year) && has_field?(:title)
				[year,title.to_s[/\w{4,}/]].join.downcase.to_sym
			else
		  	object_id.to_s
			end
		end
		
	end
end
