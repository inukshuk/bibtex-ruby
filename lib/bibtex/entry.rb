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

    NAME_FIELDS = [:author, :editor, :translator].freeze
	  
		attr_reader :type, :fields
    def_delegators :@fields, :empty?, :each

		# Creates a new instance. If a hash is given, the entry is populated accordingly.
		def initialize(attributes = {})
			@fields = {}
		  
		  self.type = attributes.delete(:type) if attributes.has_key?(:type)
		  self.key = attributes.delete(:key) if attributes.has_key?(:key)
			
			add(attributes)
			
			yield self if block_given?
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

		alias :id :key		
		alias :id= :key=
		
		# Sets the type of the entry.
		def type=(type)
			raise(ArgumentError, "types must be convertible to Symbol; was: #{type.class.name}.") unless type.respond_to?(:to_sym)
			@type = type.to_sym
		end
		
		def has_type?(type)
      type.to_s.match(/^entry$/i) || @type == type.to_sym || super
    end
    
		def method_missing(name, *args)
		  return self[name] if @fields.has_key?(name)
		  return self.send(:add, name.to_s.chop.to_sym, args[0]) if name.to_s.match(/=$/)		  
		  super
		end
		
		def respond_to?(method)
		  @fields.has_key?(method.to_sym) || method.to_s.match(/=$/) || super
		end
		
		# Renames the given field names unless a field with the new name already
		# exists.
		def rename(*arguments)
		  Hash[*arguments.flatten].each_pair do |from,to|
		    if @field.has_key?(from) && !@field.has_key?(to)
		      @field[to] = @field[from]
		      @field.delete(from)
	      end
		  end
		  self
		end
		
		alias :rename_fields :rename
		
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
		
		alias :<< :add

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
			self
		end
				
		# Called when the element was removed from a bibliography.
		def removed_from_bibliography(bibliography)
			super
			bibliography.entries[key] = nil
			self
		end

		def replace(*arguments)
			@fields.values.each { |v| v.replace(*arguments) }
			self
		end

    def join
			@fields.values.each(&:join)
      self
    end

    # Parses all name values of the entry. Tries to replace and join the
    # value prior to parsing.
    def parse_names
      NAME_FIELDS.each do |key|
        if name = @fields[key]
          name.replace(bibliography.q('@string')) unless bibliography.nil?
          name.join
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
		  Hash[*([:key, key, :type, type] + @fields.map { |k,v| [k, v.to_s(options)] }.flatten)]
		end

		def to_citeproc(options = {})
		  to_hash(options)
		end
		
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
		
		def <=>(other)
		  type != other.type ? type <=> other.type : key != other.key ? key <=> other.key : to_s <=> other.to_s
		end
		
		protected
		
		def default_key
		  object_id.to_s.to_sym
		end
		
	end
end
