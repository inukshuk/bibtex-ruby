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
	# Represents a regular BibTeX entry.
	#
	class Entry < Element
	  
		attr_reader :type, :fields

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

		# Creates a new instance. If a hash is given, the entry is populated accordingly.
		def initialize(hash = {})
			@fields = {}
		  
		  self.type = hash.delete(:type) if hash.has_key?(:type)
		  self.key = hash.delete(:key) if hash.has_key?(:key)
						
			hash.each { |k,v| add(k.to_sym, v) }
			
			yield self if block_given?
		end

		# Sets the key of the entry
		def key=(key)
			raise(ArgumentError, "keys must be convertible to Symbol; was: #{type.class.name}.") unless type.respond_to?(:to_sym)
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
      type.to_s.match(/^entry$/i) || self.type == type.to_sym || super
    end
    
		def method_missing(name, *args)
		  return self[name] if @fields.has_key?(name)
		  return self.send(:add, name.to_s.chop.to_sym, args[0]) if name.to_s.match(/=$/)		  
		  super
		end
		
		def respond_to?(method)
		  @fields.has_key?(method.to_sym) || method.to_s.match(/=$/) || super
		end
		
		# Returns the value of the field with the given name.
		def [](name)
			@fields[name.to_sym].to_s
		end

		# Adds a new field (name-value pair) to the entry.
		# Returns the new value.
		def []=(name, value)
			add(name.to_sym, value)
		end

		# Adds a new field (name-value pair) to the entry.
		# Returns the new value.
		def add(name, value)
			raise(ArgumentError, "BibTeX::Entry field name must be of type Symbol; was: #{name.class.name}.") unless name.is_a?(Symbol)
			raise(ArgumentError, "BibTeX::Entry field value must be of type Array, Symbol, or String; was: #{value.class.name}.") unless [Array,::String,Symbol].map { |k| value.is_a?(k) }.inject { |sum,n| sum || n }
			@fields[name] = Extensions.string_replacement(value.is_a?(Array) ? value : [value])
		end

		# Removes the field with a given name from the entry.
		# Returns the value of the deleted field; nil if the field was not set.
		def delete(name)
			@fields.delete(name.to_sym)
		end

		# Adds all the fields contained in a given hash to the entry.
		def <<(fields)
			raise(ArgumentError, "BibTeX::Entry fields must be of type Hash; was: #{fields.class.name}.") unless fields.is_a?(Hash)
			fields.each { |n,v| add(n,v) }
			self
		end

		# Returns true if the entry currently contains no field.
		def empty?
			@fields.empty?
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

		# Replaces all constants in this entry's field values which are defined in +hash+.
		def replace!(hash)
			@fields.keys.each { |k| @fields[k] = @fields[k].replace_strings(hash) }
		end

    def join!
			@fields.keys.each { |k| @fields[k] = @fields[k].join_strings }
    end

		# Returns a string of all the entry's fields.
		def content
			@fields.keys.map { |k| "#{k} = #{ @fields[k].to_s(:quotes => %w({ })) }" }.join(",\n")
		end

		# Returns a string representation of the entry.
		def to_s
			["@#{type}{#{key},",content.gsub(/^/,'  '),"}\n"].join("\n")
		end
		
		def to_hash(options = {})
		  options[:quotes] ||= %w({ })
		  @fields.keys.map { |k| { k.to_s => @fields[k].to_s(options) } }.inject({ 'key' => @key, 'type' => @type.to_s }) { |sum,n| sum.merge(n) }
		end
		
		def to_xml
  		xml = REXML::Element.new(@type.to_s)
  		xml.attributes['key'] = @key
      @fields.each do |k,v|
        e = REXML::Element.new(k.to_s)
        e.text = v.to_s
        xml.add_element(e)
      end
      xml
		end
		
		def <=>(other)
		  self.type != other.type ? self.type <=> other.type : self.key != other.key ? self.key <=> other.key : self.to_s <=> other.to_s
		end
		
		protected
		
		def default_key
		  object_id.to_s.to_sym
		end
		
	end
end
