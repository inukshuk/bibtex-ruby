#--
# BibTeX-Ruby
# Copyright (C) 2010-2012 Sylvester Keil <sylvester.keil.or.at>
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
      :article       => %w(author title journal year),
      :book          => [%w(author editor), *%w(title publisher year)],
      :booklet       => %w(title),
      :conference    => %w(author title booktitle year),
      :inbook        => [%w(author editor), %w(chapter pages), *%w(title publisher year)],
      :incollection  => %w(author title booktitle publisher year),
      :inproceedings => %w(author title booktitle year),
      :manual        => %w(title),
      :mastersthesis => %w(author title school year),
      :misc          => [],
      :phdthesis     => %w(author title school year),
      :proceedings   => %w(title year),
      :techreport    => %w(author title institution year),
      :unpublished   => %w(author title note)
    }).freeze

    # Defines the default fallbacks for values defined in cross-references
    FIELD_ALIASES = {
      'booktitle' => 'title',
      # 'editor' => 'author'
    }.freeze


    NAME_FIELDS = %w(author editor translator).freeze
    DATE_FIELDS = %w(year month).freeze

    MONTHS = [:jan,:feb,:mar,:apr,:may,:jun,:jul,:aug,:sep,:oct,:nov,:dec].freeze

    MONTHS_FILTER = Hash.new do |h,k|
      case k.to_s.strip
      when /\A(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)/i
        h[k] = k.to_s[0,3].downcase.to_sym
      when /\A\d\d?\Z/
        h[k] = MONTHS[k.to_i - 1] || k
      else
        h[k] = k
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
      type      genre
    }]).freeze

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
    }.freeze

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
    }]).freeze

    BIBO_FIELDS = Hash[*%w{
      pages      pages
      number     issue
      isbn       isbn
      issn       issn
      doi        doi
      edition    edition
      abstract   abstract
      volume     volume
    }].freeze

    BIBO_TYPES = Hash.new(:Document).merge(Hash[*%w{
      booklet        Book
      book           Book
      conference     Conference
      inbook         Article
      incollection   Article
      inproceedings  Article
      manual         Manual
      mastersthesis  Thesis
      phdthesis      Thesis
      proceedings    Proceedings
      techreport     Report
      journal        Journal
      periodical     Periodical
      unpublished    Manuscript
      article        Article
    }]).freeze

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

    def initialize_copy(other)
      @fields = {}

      self.type = other.type
      self.key = other.key

      add(other.fields)
    end

    def merge(other, filter = field_names)
      dup.merge!(other, filter)
    end

    def merge!(other, filter = field_names)
      raise InvalidArgument, "failed to merge entries: type mismatch: #{type} #{other.type}" unless
        type == other.type

      other.each do |name, value|
        if has_field?(name)
          get(name).merge!(value) if filter.include?(name)
        else
          add name, value.dup
        end
      end

      self
    end

    # Generate Accessors for required fields (#52)

    REQUIRED_FIELDS.values.flatten.uniq.each do |name|

      define_method(name) do
        case
        when fields.has_key?(name)
          fields[name]
        when has_parent? && parent.provides?(name)
          parent.provide(name)
        else
          nil
        end
      end

      define_method("#{name}=") do |value|
        self[name] = value
      end
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


    def has_field?(*names)
      names.flatten.any? do |name|
        fields.has_key?(name.to_s)
      end
    end

    alias field? has_field?

    def inherits?(*names)
      names.flatten.any? do |name|
        !has_field(name) && has_parent? && parent.provides?(name)
      end
    end

    # Returns true if the Entry has a field (or alias) for any of the passed-in names.
    def provides?(*names)
      names.flatten.any? do |name|
        has_field?(name) || has_field?(aliases[name.to_s])
      end
    end

    def provides_or_inherits?(*names)
      provides?(names) || inherits?(names)
    end

    # Returns the field value referenced by the passed-in name.
    # For example, this will return the 'title' value for 'booktitle' if a
    # corresponding alias is defined.
    def provide(name)
      name = name.to_s
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
        names = names & filter.map(&:to_s)
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
      name = name.to_s
      case
      when fields.has_key?(name)
        fields[name]
      when name =~ /^(.+)=$/
        self[$1] = args[0]
      when name =~ /^(?:convert|from)_([a-z]+)(!)?$/
        $2 ? convert!($1, &block) : convert($1, &block)
      when has_parent? && parent.provides?(name)
        parent.provide(name)
      else
        super
      end
    end

    def respond_to?(method)
      method = method.to_s
      provides?(method) || method.match(/=$/) ||
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
        from, to = from.to_s, to.to_s
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
      fields[name.to_s] || parent && parent.provide(name)
    end

    alias get []

    def fetch(name, default = nil)
      get(name) || block_given? ? yield(name) : default
    end

    # Adds a new field (name-value pair) to the entry.
    # Returns the new value.
    def []=(name, value)
      fields[name.to_s] = Value.create(value)
    end

    # Author, Editor and Translator readers
    NAME_FIELDS.each do |contributor|
      define_method(contributor) do
        get(contributor)
      end

      alias_method "#{contributor}s", contributor
    end


    # call-seq:
    #   add(:author, "Edgar A. Poe")
    #   add(:author, "Edgar A. Poe", :title, "The Raven")
    #   add([:author, "Edgar A. Poe", :title, "The Raven"])
    #   add(:author => "Edgar A. Poe", :title => "The Raven")
    #   add(:author => Names.new(Name.new(:first => 'Edgar A.', :last => 'Poe')))
    #
    # Adds a new field (name-value pair) or multiple fields to the entry.
    # Returns the entry for chainability.
    def add(*arguments)
      Hash[*arguments.flatten].each_pair do |name, value|
        self[name] = value
      end

      self
    end

    alias << add

    # Removes the field with a given name from the entry.
    # Returns the value of the deleted field; nil if the field was not set.
    def delete(name)
      fields.delete(name.to_s)
    end

    # Returns false if the entry is one of the standard entry types and does not have
    # definitions of all the required fields for that type.
    def valid?
      REQUIRED_FIELDS[@type].all? do |f|
        f.is_a?(Array) ? !(f & fields.keys).empty? : !fields[f].nil?
      end
    end

    # Creates the entry's digest based on the passed-in filters.
    #
    # The digest contains the type and all key-value pairs based
    # on the passed in filter.
    #
    # If a block is given, the computed digest will be passed to
    # the block for post-processing (the entry itself will be passed
    # as the second parameter).
    #
    # @see #field_names
    #
    # @param [<Symbol>] the field names to use
    # @return [String] the digest string
    def digest(filter = [])
      names = field_names(filter)
      digest = type.to_s

      names.zip(values_at(*names)).each do |key, value|
        digest << "|#{key}:#{value}"
      end

      digest = yield(digest, self) if block_given?
      digest
    end

    def identifier
      case
      when provides?(:doi)
        "info:doi/#{get(:doi)}"
      when provides?(:isbn)
        "urn:isbn:#{get(:isbn)}"
      when provides?(:issn)
        "urn:issn:#{get(:issn)}"
      else
        "urn:bibtex:#{key}"
      end
    end

    # Called when the element was added to a bibliography.
    def added_to_bibliography(bibliography)
      super

      @key = register(key)

      [:parse_names, :parse_months].each do |parser|
        send(parser) if bibliography.options[parser]
      end

      if bibliography.options.has_key?(:filter)
        [*bibliography.options[:filter]].each do |filter|
          convert!(filter)
        end
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
      self['month'] = MONTHS_FILTER[month]
    end

    def parse_month
      self['month'] = MONTHS_FILTER[fields['month']] if has_field?('month')
      self
    end

    alias parse_months parse_month

    def date
      get(:date) || get(:year)
    end

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
      bibliography && bibliography[fields['crossref']]
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

    def container_title
      get(:booktitle) || get(:journal) || get(:container)
    end

    def pages_from
      fetch(:pages, '').split(/\D+/)[0]
    end

    def pages_to
      fetch(:pages, '').split(/\D+/)[-1]
    end

    # Returns true if this entry is published inside a book, collection or journal
    def contained?
      has_field?(:booktitle, :container, :journal)
    end

    # Returns an array containing the values associated with the given keys.
    def values_at(*arguments)
      arguments.map do |key|
        get key
      end
    end

    # Returns a duplicate entry with all values converted using the filter(s).
    # If an optional block is given, only those values will be converted where
    # the block returns true (the block will be called with each key-value pair).
    #
    # @see #convert!
    def convert(*filters)
      block_given? ? dup.convert!(*filters, &Proc.new) : dup.convert!(*filters)
    end

    # In-place variant of @see #convert
    def convert!(*filters)
      filters = filters.flatten.map { |f| Filters.resolve!(f) }

      fields.each_pair do |k, v|
        (!block_given? || yield(k, v)) ? v.convert!(*filters) : v
      end

      self
    end

    def <=>(other)
      type != other.type ? type <=> other.type : key != other.key ? key <=> other.key : to_s <=> other.to_s
    end


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

      hash = {}

      each_pair do |k,v|
        hash[CSL_FILTER[k].to_s] = v.to_citeproc(options) unless DATE_FIELDS.include?(k)
      end

      hash['id'] = key.to_s
      hash['type'] = CSL_TYPES[type].to_s

      case type
      when :mastersthesis
        hash['genre'] = "Master's thesis"
      when :phdthesis
        hash['genre'] = 'PhD thesis'
      else
        # empty
      end unless hash.key?('genre')

      hash['issued'] = citeproc_date

      hash
    end

    def issued
      m = MONTHS.find_index(fields['month'].to_sym) unless !has_field?(:month)
      m = m + 1 unless m.nil?

      Hash['date-parts', [[fields['year'],m].compact.map(&:to_i)]]
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

    # Returns a RDF::Graph representation of the entry using the BIBO ontology.
    # TODO: improve level of detail captured by export
    def to_rdf(options = {})
      require 'rdf'

      bibo = RDF::Vocabulary.new('http://purl.org/ontology/bibo/')

      graph = RDF::Graph.new
      entry = RDF::URI.new(identifier)

      graph << [entry, RDF.type, bibo[BIBO_TYPES[type]]]

      [:title, :language].each do |key|
        graph << [entry, RDF::DC[key], get(key).to_s] if field?(key)
      end

      graph << [entry, RDF::DC.date, get(:year).to_s] if field?(:year)

      if field?(:publisher)
        address = RDF::Vocabulary.new('http://schemas.talis.com/2005/address/schema#')
        pub = RDF::Node.new

        graph << [pub, RDF.type, RDF::FOAF[:Organization]]
        graph << [pub, RDF::FOAF.name, get(:publisher)]

        graph << [pub, address[:localityName], get(:address)] if field?(:address)

        graph << [entry, RDF::DC.published, pub]
      end

      [:doi, :edition, :volume].each do |key|
        graph << [entry, bibo[key], get(key).to_s] if field?(key)
      end

      if has_field?(:pages)
        if get(:pages).to_s =~ /^\s*(\d+)\s*-+\s*(\d+)\s*$/
          graph << [entry, bibo[:pageStart], $1]
          graph << [entry, bibo[:pageEnd], $2]
        else
          graph << [entry, bibo[:pages], get(:pages).to_s]
        end
      end

      if has_field?(:author)
        seq = RDF::Node.new

        graph << [seq, RDF.type, RDF[:Seq]]
        graph << [entry, bibo[:authorList], seq]

        authors.each do |author|
          a = RDF::Node.new

          graph << [a, RDF.type, RDF::FOAF[:Person]]

          if author.is_a?(Name)
            [:given, :family, :prefix, :suffix].each do |part|
              graph << [a, bibo["#{part}Name"], author.send(part).to_s]
            end
          else
            graph << [a, RDF::FOAF.name, author.to_s]
          end

          graph << [entry, RDF::DC.creator, a]
          graph << [seq, RDF.li, a]
        end
      end

      if has_field?(:editor)
        seq = RDF::Node.new

        graph << [seq, RDF.type, RDF[:Seq]]
        graph << [entry, bibo[:editorList], seq]

        editors.each do |editor|
          e = RDF::Node.new

          graph << [e, RDF.type, RDF::FOAF[:Person]]

          if editor.is_a?(Name)
            [:given, :family, :prefix, :suffix].each do |part|
              graph << [e, bibo["#{part}Name"], editor.send(part).to_s]
            end
          else
            graph << [e, RDF::FOAF.name, editor.to_s]
          end

          graph << [entry, bibo.editor, a]
          graph << [seq, RDF.li, e]
        end
      end

      graph
    rescue LoadError
      BibTeX.log.error "Please gem install rdf for RDF support."
    end

    alias to_bibo to_rdf




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
