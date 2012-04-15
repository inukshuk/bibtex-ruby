#--
# BibTeX-Ruby
# Copyright (C) 2010-2011 Sylvester Keil <sylvester.keil.or.at>
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

module BibTeX
  #
  # Represents a regular BibTeX entry.
  #
  class Entry < Element
    extend Forwardable    
    include Enumerable

    # Defines the required fields of the standard entry types
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

    # Defines the default fallbacks for values defined in cross-references
    FIELD_ALIASES = {
      :booktitle => :title,
      # :editor => :author
    }.freeze
    
    
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
      article        article-journal
    }.map(&:intern)]).freeze

    
    attr_reader :fields, :type
    
    def_delegators :@fields, :empty?

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
  
    # call-seq:
    #   entry.each      { |key, value| block } -> entry
    #   entry.each_pair { |key, value| block } -> entry
    #   entry.each                             -> an_enumerator
    #   entry.each_pair                        -> an_enumerator
    #
    # Calls block once for each key in entry, passing the key-value
    # pair as parameters.
    #
    # If no block is given, an enumerator is returned instead.
    def each
      if block_given?
        fields.each(&Proc.new)
        self
      else
        to_enum
      end
    end
    
    alias each_pair each
    
  
    # Returns the Entry's field name aliases.
    def aliases
      @aliases ||= FIELD_ALIASES.dup
    end
    
    # Sets the Entry's key. If the Entry is currently registered with a
    # Bibliography, re-registers the Entry with the new key; note that this
    # may change the key value if another Entry is already regsitered with
    # the same key.
    #
    # Returns the new key.
    def key=(key)
      key = key.to_s
      
      if registered?
        bibliography.entries.delete(@key)
        key = register(key)
      end

      @key = key
    rescue => e
      raise BibTeXError, "failed to set key to #{key.inspect}: #{e.message}"
    end
    
    def key
      @key ||= default_key
    end

    alias id key
    alias id= key=

    # Sets the type of the entry.
    def type=(type)
      @type = type.to_sym
    end
    
    def has_type?(type)
      type.to_s.match(/^(?:entry|\*)$/i) || @type == type.to_sym || super
    end
    
    alias type? has_type?
    
    
    def has_field?(name)
      name.respond_to?(:to_sym) ? fields.has_key?(name.to_sym) : false
    end

    alias field? has_field?

    def inherits?(name)
      !has_field(name) && has_parent? && parent.provides?(name)
    end
    
    # Returns true if the Entry has a field (or alias) for the passed-in name.
    def provides?(name)
      return nil unless name.respond_to?(:to_sym)
      has_field?(name) || has_field?(aliases[name.to_sym])
    end
    
    # Returns the field value referenced by the passed-in name.
    # For example, this will return the 'title' value for 'booktitle' if a
    # corresponding alias is defined.
    def provide(name)
      return nil unless name.respond_to?(:to_sym)
      name = name.to_sym      
      fields[name] || fields[aliases[name]]
    end
    
    # If the Entry has a cross-reference, copies all referenced all inherited
    # values from the parent.
    #
    # Returns the Entry.
    def save_inherited_fields
      inherited_fields.each do |name|
        fields[name] = parent.provide(name)
      end
      
      self
    end
    
    # Returns a sorted list of the Entry's field names. If a +filter+ is passed
    # as argument, returns all field names that are also defined by the filter.
    # If the +filter+ is empty, returns all field names.
    #
    # If the second optional argument is true (default) and the Entry contains
    # a cross-reference, the list will include all inherited fields.
    def field_names(filter = [], include_inherited = true)
      names = fields.keys
      
      if include_inherited && has_parent?
        names.concat(inherited_fields)
      end
      
      unless filter.empty?
        names = names & filter.map(&:to_sym)
      end
      
      names.sort!
      names
    end

    # Returns a sorted list of all field names referenced by this Entry's cross-reference.
    def inherited_fields
      return [] unless has_parent?
      
      names = parent.fields.keys - fields.keys
      names.concat(parent.aliases.reject { |k,v| !parent.has_field?(v) }.keys)
      names.sort!
      
      names
    end
    
    
    def method_missing(name, *args, &block)
      case
      when fields.has_key?(name)
        fields[name]
      when name.to_s =~ /^(.+)=$/
        send(:add, $1.to_sym, args[0])      
      when name =~ /^(?:convert|from)_([a-z]+)(!)?$/
        $2 ? convert!($1, &block) : convert($1, &block)
      when has_parent? && parent.provides?(name)
        parent.provide(name)
      else
        super
      end
    end

    def respond_to?(method)
      provides?(method.to_sym) || method.to_s.match(/=$/) ||
        method =~ /^(?:convert|from)_([a-z]+)(!)?$/ || (has_parent? && parent.respond_to?(method)) || super
    end
    
    # Returns a copy of the Entry with all the field names renamed.
    def rename(*arguments)
      dup.rename!(*arguments)
    end
    
    # Renames the given field names unless a field with the new name already
    # exists.
    def rename!(*arguments)
      Hash[*arguments.flatten].each_pair do |from,to|
        if fields.has_key?(from) && !fields.has_key?(to)
          fields[to] = fields[from]
          fields.delete(from)
        end
      end
      self
    end

    alias rename_fields rename
    alias rename_fields! rename!
    
    # Returns the value of the field with the given name. If the value is not
    # defined and the entry has cross-reference, returns the cross-referenced
    # value instead.
    def [](name)
      fields[name.to_sym] || parent && parent.provide(name)
    end
    
    alias get []
    
    def fetch(name, default = nil)
      get(name) || block_given? ? yield(name) : default
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
    # add(:author => Names.new(Name.new(:first => 'Edgar A.', :last => 'Poe')))
    def add(*arguments)
      Hash[*arguments.flatten].each_pair do |name, value|
        fields[name.to_sym] = Value.create(value)
      end
      
      self
    end
    
    alias << add

    # Removes the field with a given name from the entry.
    # Returns the value of the deleted field; nil if the field was not set.
    def delete(name)
      fields.delete(name.to_sym)
    end

    # Returns false if the entry is one of the standard entry types and does not have
    # definitions of all the required fields for that type.
    def valid?
      REQUIRED_FIELDS[@type].all? do |f|
        f.is_a?(Array) ? !(f & fields.keys).empty? : !fields[f].nil?
      end
    end

    def generate_hash(filter = [])
      Digest::MD5.hexdigest(field_names(filter).map { |k| [k, fields[k]] }.flatten.join)
    end
    
    # Called when the element was added to a bibliography.
    def added_to_bibliography(bibliography)
      super

      @key = register(key)
      
      [:parse_names, :parse_months].each do |parser|
        send(parser) if bibliography.options[parser]
      end
      
      if bibliography.options.has_key?(:filter)
        convert!(bibliography.options[:filter])
      end
      
      self
    end

    # Called when the element was removed from a bibliography.
    def removed_from_bibliography(bibliography)
      super
      bibliography.entries.delete(key)
      self
    end

    # Returns true if the Entry is currently registered with the associated Bibliography.
    def registered?
      !!(bibliography && bibliography.entries[key].equal?(self))
    end
    
    # Registers this Entry in the associated Bibliographies entries hash.
    # This method may change the Entry's key, if another entry is already
    # registered with the current key.
    #
    # Returns the key or nil if the Entry is not associated with a Bibliography.
    def register(key)
      return nil if bibliography.nil?
      
      k = key.dup
      k.succ! while bibliography.has_key?(k)
      bibliography.entries[k] = self
      k
    end
    
    def replace(*arguments)
      arguments = bibliography.q('@string') if arguments.empty?
      fields.values.each { |v| v.replace(*arguments) }
      self
    end

    def join
      fields.values.each(&:join)
      self
    end

    def month=(month)
      fields[:month] = MONTHS_FILTER[month]
    end
    
    def parse_month
      fields[:month] = MONTHS_FILTER[fields[:month]] if has_field?(:month)
      self
    end
    
    alias parse_months parse_month
    
    
    # Parses all name values of the entry. Tries to replace and join the
    # value prior to parsing.
    def parse_names
      strings = bibliography ? bibliography.strings.values : []

      NAME_FIELDS.each do |key|
        if name = fields[key]
          name = name.dup.replace(strings).join.to_name
          fields[key] = name unless name.nil?
        end
      end

      self
    end
    
    # Returns a list of all names (authors, editors, translators).
    def names
      NAME_FIELDS.map { |k| has_field?(k) ? @fields[k].tokens : nil }.flatten.compact
    end
      
    
    # Returns true if the Entry has a valid cross-reference in the Bibliography.
    def has_parent?
      !parent.nil?
    end

    alias has_cross_reference? has_parent?    

    # Returns true if the Entry cross-references an Entry which is not
    # registered in the current Bibliography.
    def parent_missing?
      has_field?(:crossref) && !has_parent?
    end
  
    alias cross_reference_missing? parent_missing?
    
    # Returns the cross-referenced Entry from the Bibliography or nil if this
    # Entry does define a cross-reference.
    def parent
      bibliography && bibliography[fields[:crossref]]
    end
    
    alias cross_reference parent


    # Returns true if the entry is cross-referenced by another entry in the
    # Bibliography.
    def has_children?
      !children.empty?
    end
    
    alias cross_referenced? has_children?
    
    # Returns a list of all entries in the Bibliography containing a
    # cross-reference to this entry or [] if there are no references to this
    # entry.
    def children
      bibliography && bibliography.q("@entry[crossref=#{key}]") or []
    end

    alias cross_referenced_by children
    
    
    # Returns a string of all the entry's fields.
    def content(options = {})
      fields.map { |k,v| "#{k} = #{ fields[k].to_s(options) }" }.join(",\n")
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
    
      parse_names
      parse_month
      
      hash = { 'id' => key.to_s, 'type' => CSL_TYPES[type].to_s }
    
      each_pair do |k,v|
        hash[CSL_FILTER[k].to_s] = v.to_citeproc(options) unless DATE_FIELDS.include?(k)
      end
    
      hash['issued'] = citeproc_date
      hash
    end
    
    def issued
      m = MONTHS.find_index(fields[:month].to_s.intern)
      m = m + 1 unless m.nil?
      
      Hash['date-parts', [[fields[:year],m].compact.map(&:to_i)]]
    end
    
    alias citeproc_date issued
    
    def to_xml(options = {})
      require 'rexml/document'
      
      xml = REXML::Element.new('bibtex:entry')
      xml.attributes['id'] = key

      entry = REXML::Element.new("bibtex:#{type}")

      fields.each do |key, value|
        field = REXML::Element.new("bibtex:#{key}")
        
        if options[:extended] && value.name?
          value.each { |n| entry.add_element(n.to_xml) }
        else
          field.text = value.to_s(options)
        end
        
        entry.add_element(field)
      end

      xml.add_element(entry)
      xml
    end
    
    # Returns a duplicate entry with all values converted using the filter.
    # If an optional block is given, only those values will be converted where
    # the block returns true (the block will be called with each key-value pair).
    #
    # @see #convert!
    def convert(filter)
      block_given? ? dup.convert!(filter, &Proc.new) : dup.convert!(filter)
    end
    
    # In-place variant of @see #convert
    def convert!(filter)
      fields.each_pair { |k,v| !block_given? || yield(k,v) ? v.convert!(filter) : v }
      self
    end
    
    def <=>(other)
      type != other.type ? type <=> other.type : key != other.key ? key <=> other.key : to_s <=> other.to_s
    end

    private
    
    # Returns a default key for this entry.
    def default_key
      k = names[0]
      k = k.respond_to?(:family) ? k.family : k.to_s
      k = k[/[A-Za-z]+/] || 'unknown'
      k << (has_field?(:year) ? year : '-')
      k << 'a'      
      k.downcase!
      k
    end
    
  end
end
