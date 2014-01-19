class BibTeX::Entry::RDFConverter
  BIBO_TYPES = Hash.new(:Document).merge(Hash[*%w{
    article        Article
    booklet        Book
    book           Book
    conference     AcademicArticle
    inbook         BookSection
    incollection   BookSection
    inproceedings  AcademicArticle
    manual         Manual
    mastersthesis  Thesis
    phdthesis      Thesis
    thesis         Thesis
    patent         Patent
    collection     Collection
    online         Website
    proceedings    Proceedings
    techreport     Report
    journal        Journal
    periodical     Periodical
    unpublished    Manuscript
  }.map(&:intern)]).freeze

  # converts a BibTeX entry to RDF
  # @return [RDF::Graph] the RDF graph of this entry
  def self.convert(bibtex)
    new(bibtex).convert!
  end

  # @param [BibTeX::Entry] the entry to convert
  def initialize(bibtex)
    @bibtex = bibtex
  end

  # @return [RDF::Graph] the RDF graph of this entry
  def convert!
    methods = self.class.instance_methods(false) - [:convert!]
    methods.each { |m| send(m) }
    fallback

    graph
  end

  def abstract
    return unless bibtex.field?(:abstract)
    remove_from_fallback(:abstract)

    graph << [entry, RDF::DC.abstract, bibtex[:abstract].to_s]
  end

  def author
    return unless bibtex.field?(:author)
    remove_from_fallback(:author)

    seq = RDF::Node.new

    graph << [seq, RDF.type, RDF[:Seq]]
    graph << [entry, bibo[:authorList], seq]

    bibtex[:author].each do |name|
      node = RDF::Node.new

      graph << [node, RDF.type, RDF::FOAF[:Person]]

      if name.is_a?(BibTeX::Name)
        [:given, :family, :prefix, :suffix].each do |part|
          graph << [node, bibo["#{part}Name"], name.send(part).to_s] unless name.send(part).nil?
        end
      else
        graph << [node, RDF::FOAF.name, name.to_s]
      end

      graph << [entry, RDF::DC.creator, node]
      graph << [seq, RDF.li, node]
    end
  end

  def booktitle
    return unless bibtex.field?(:booktitle)
    remove_from_fallback(:booktitle)
    return if bibtex.has_parent? && bibtex.parent[:title] == bibtex[:booktitle]
    return if bibtex.has_parent? && bibtex.parent[:booktitle] == bibtex[:booktitle]
    return if bibtex.has_parent? && bibtex.parent[:isbn] == bibtex[:isbn]

    graph << [entry, RDF::DC.isPartOf, bibtex[:booktitle].to_s]
  end

  def chapter
    return unless bibtex.field?(:chapter)
    remove_from_fallback(:chapter)

    graph << [entry, bibo[:chapter], bibtex[:chapter].to_s]
  end

  def children
    return unless bibtex.has_children?

    bibtex.children.each do |child|
      graph << [entry, RDF::DC.hasPart, child.to_rdf]
    end
  end

  def doi
    return unless bibtex.field?(:doi)
    remove_from_fallback(:doi)

    graph << [entry, bibo[:doi], bibtex[:doi].to_s]
    graph << [entry, RDF::DC.identifier, "doi:#{bibtex[:doi].to_s}"]
  end

  def edition
    return unless bibtex.field?(:edition)
    remove_from_fallback(:edition)

    graph << [entry, bibo[:edition], bibtex[:edition].to_s]
  end

  def editor
    return unless bibtex.field?(:editor)
    remove_from_fallback(:editor)

    seq = RDF::Node.new

    graph << [seq, RDF.type, RDF[:Seq]]
    graph << [entry, bibo[:editorList], seq]

    bibtex[:editor].each do |name|
      node = RDF::Node.new

      graph << [node, RDF.type, RDF::FOAF[:Person]]

      if name.is_a?(BibTeX::Name)
        [:given, :family, :prefix, :suffix].each do |part|
          graph << [node, bibo["#{part}Name"], name.send(part).to_s] unless name.send(part).nil?
        end
      else
        graph << [node, RDF::FOAF.name, name.to_s]
      end

      graph << [entry, bibo.name, node]
      graph << [seq, RDF.li, node]
    end
  end

  def isbn
    return unless bibtex.field?(:isbn)
    remove_from_fallback(:isbn)

    graph << [entry, bibo[:isbn], bibtex[:isbn].to_s]

    if bibtex.contained?
      graph << [entry, RDF::DC.isPartOf, "urn:isbn:#{bibtex[:isbn].to_s}"]
    else
      graph << [entry, RDF::DC.identifier, "urn:isbn:#{bibtex[:isbn].to_s}"]
    end
  end

  def issn
    return unless bibtex.field?(:issn)
    remove_from_fallback(:issn)

    graph << [entry, bibo[:issn], bibtex[:issn].to_s]
    if bibtex.contained?
      graph << [entry, RDF::DC.isPartOf, "urn:issn:#{bibtex[:issn].to_s}"]
    else
      graph << [entry, RDF::DC.identifier, "urn:issn:#{bibtex[:issn].to_s}"]
    end
  end

  def journal
    return unless bibtex.field?(:journal)

    source = []
    source << bibtex[:journal].to_s
    source << "Vol. #{bibtex[:volume].to_s}" if bibtex.field?(:volume)
    source << "No. #{bibtex[:number].to_s}" if bibtex.field?(:number)
    pagination = bibtex[:pagination] || 'pp.'
    source << "#{pagination.to_s} #{bibtex[:pages].to_s}" if bibtex.field?(:pages)
    graph << [entry, RDF::DC.source, source.join(', ')]
  end

  def key
    graph << [entry, RDF::DC.identifier, "urn:bibtex:#{bibtex.key}"]
  end

  def keywords
    return unless bibtex.field?(:keywords)
    remove_from_fallback(:keywords)

    bibtex[:keywords].to_s.split(/\s*,\s*/).each do |keyword|
      graph << [entry, RDF::DC.subject, keyword]
    end
  end

  def language
    return unless bibtex.field?(:language)
    remove_from_fallback(:language)

    bibtex[:language] = 'german' if bibtex[:language] == 'ngerman'

    graph << [entry, RDF::DC.language, bibtex[:language].to_s]
  end

  def note
    return unless bibtex.field?(:note)
    remove_from_fallback(:note)

    pub = RDF::Node.new
    graph << [pub, RDF.type, bibo[:Note]]
    graph << [pub, bibo[:content], bibtex[:note]]


    graph << [entry, bibo[:annotates], pub]
  end

  def number
    return unless bibtex.field?(:number)
    remove_from_fallback(:number)

    case bibtex.type
    when :techreport || :manual || :unpublished
      graph << [entry, bibo[:number], bibtex[:number].to_s]
    else
      graph << [entry, bibo[:issue], bibtex[:number].to_s]
    end
  end

  def organization
    return unless bibtex.field?(:organization)
    remove_from_fallback(:organization)

    org = RDF::Node.new
    graph << [org, RDF.type, RDF::FOAF[:Organization]]
    graph << [org, RDF::FOAF.name, bibtex[:organization].to_s]

    graph << [entry, RDF::DC.contributor, org]
    if [:proceedings, :inproceedings, :conference].any?(bibtex.type)
      event = RDF::Vocabulary.new('http://purl.org/NET/c4dm/event.owl')
      graph << [entry, event[:hasAgent], org]
    end
  end

  def pages
    return unless bibtex.field?(:pages)
    remove_from_fallback(:pages)

    if bibtex[:pages].to_s =~ /^\s*(\d+)\s*-+\s*(\d+)\s*$/
      graph << [entry, bibo[:pageStart], $1]
      graph << [entry, bibo[:pageEnd], $2]
    else
      graph << [entry, bibo[:pages], bibtex[:pages].to_s]
    end
  end

  def parent
    return unless bibtex.has_parent?

    graph << [entry, RDF::DC.isPartOf, bibtex.parent.to_rdf]
  end

  def publisher
    return unless bibtex.field?(:publisher)
    remove_from_fallback(:publisher, :address)

    pub = RDF::Node.new
    graph << [pub, RDF.type, RDF::FOAF[:Organization]]
    graph << [pub, RDF::FOAF.name, bibtex[:publisher]]

    if bibtex.field?(:address)
      address = RDF::Vocabulary.new('http://schemas.talis.com/2005/address/schema#')
      graph << [pub, address[:localityName], bibtex[:address]]
    end

    graph << [entry, RDF::DC.publisher, pub]
    graph << [entry, bibo[:publisher], pub]
  end

  def series
    return unless bibtex.field(:series)
    remove_from_fallback(:series)
    return if bibtex.has_parent? && bibtex.parent[:title] == bibtex[:series]
    return if bibtex.has_parent? && bibtex.parent[:series] == bibtex[:series]
    return if bibtex.has_parent? && bibtex.parent[:issn] == bibtex[:issn]

    graph << [entry, RDF::DC.isPartOf, bibtex[:series].to_s]
  end

  def thesis_degree
    return unless BIBO_TYPES[bibtex.type] == :Thesis

    case bibtex.type
    when :mastersthesis
      # ms = masters degree in science
      # Only ma and ms available. We simply chose one.
      degree = bibo['degrees/ms']
    when :phdthesis
      degree = bibo['degrees/phd']
    end
    case bibtex[:type]
    when 'mathesis'
      degree = bibo['degrees/ma']
    when 'phdthesis'
      degree = bibo['degrees/phd']
    when /Bachelor['s]{0,2} Thesis/i
      degree = "Bachelor's Thesis"
    when /Diplomarbeit/i
      degree = bibo['degrees/ms']
    when /Magisterarbeit/i
      degree = bibo['degrees/ma']
    end

    graph << [entry, bibo[:degree], degree] unless degree.nil?
  end

  def title
    return unless bibtex.field?(:title) || bibtex.field?(:subtitle)
    remove_from_fallback(:title)

    title = [bibtex[:title].to_s, bibtex[:subtitle].to_s].join(': ')
    graph << [entry, RDF::DC.title, title]
    graph << [entry, bibo[:shortTitle], bibtex[:title].to_s]
  end

  def type
    graph << [entry, RDF.type, bibo[BIBO_TYPES[bibtex.type]]]

    case bibtex.type
    when :proceedings, :journal
      graph << [entry, RDF::DC.type, 'Collection']
    else
      graph << [entry, RDF::DC.type, 'Text']
    end
  end

  def volume
    return unless bibtex.field?(:volume)
    remove_from_fallback(:volume)

    graph << [entry, bibo[:volume], bibtex[:volume].to_s]
  end

  def year
    return unless bibtex.field?(:year)
    remove_from_fallback(:year, :month)

    date = [bibtex[:year].to_s, bibtex[:month].to_s].join('-')

    if bibtex.type == :unpublished
      graph << [entry, RDF::DC.created, date]
      graph << [entry, bibo[:created], date]
    else
      graph << [entry, RDF::DC.issued, date]
      graph << [entry, bibo[:issued], date]
    end
  end

  private

  attr_reader :bibtex

  def bibo
    @bibo ||= RDF::Vocabulary.new('http://purl.org/ontology/bibo/')
  end

  def entry
    @entry ||= RDF::URI.new(bibtex.identifier)
  end

  def graph
    @graph ||= RDF::Graph.new
  end

  def remove_from_fallback(*fields)
    @fallback ||= bibtex.fields.keys

    fields.each { |field| @fallback.delete(field) }
  end

  def fallback
    return if @fallback.empty?

    ml = RDF::Vocabulary.new('http://bibtexml.sf.net/')
    @fallback.each do |field|
      graph << [entry, ml[field], bibtex[field]]
    end
  end
end
