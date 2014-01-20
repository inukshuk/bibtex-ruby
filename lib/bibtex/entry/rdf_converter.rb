require 'uri/common'

class BibTeX::Entry::RDFConverter
  BIBO_TYPES = Hash[*%w{
    article        Article
    book           Book
    booklet        Book
    collection     Collection
    conference     AcademicArticle
    inbook         BookSection
    incollection   BookSection
    inproceedings  AcademicArticle
    journal        Journal
    manual         Manual
    mastersthesis  Thesis
    online         Website
    patent         Patent
    periodical     Periodical
    phdthesis      Thesis
    proceedings    Proceedings
    standard       Standard
    techreport     Report
    thesis         Thesis
    unpublished    Manuscript
  }.map(&:intern)].freeze

  # converts a BibTeX entry to RDF
  # @return [RDF::Graph] the RDF graph of this entry
  def self.convert(bibtex)
    new(bibtex).convert!
  end

  # @param [BibTeX::Entry] the entry to convert
  def initialize(bibtex, graph = RDF::Graph.new)
    @bibtex = bibtex
    @graph = graph
  end

  # @return [RDF::Graph] the RDF graph of this entry
  def convert!
    bibtex.parse_names
    bibtex.parse_month

    methods = self.class.instance_methods(false) - [:convert!]
    methods.each { |m| send(m) }
    run_fallback

    graph
  end

  def abstract
    return unless bibtex.field?(:abstract)
    remove_from_fallback(:abstract)

    graph << [entry, RDF::DC.abstract, bibtex[:abstract].to_s]
    graph << [entry, bibo[:abstract], bibtex[:abstract].to_s]
  end

  def author
    return unless bibtex.field?(:author)
    remove_from_fallback(:author)

    seq = RDF::Node.new

    graph << [seq, RDF.type, RDF[:Seq]]
    graph << [entry, bibo[:authorList], seq]

    bibtex[:author].each do |name|
      node = agent(name) { create_agent(name, :Person) }

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

    series = RDF::Node.new
    graph << [series, RDF.type, bibo[:Document]]
    graph << [series, RDF::DC.title, bibtex[:booktitle].to_s]

    graph << [entry, RDF::DC.isPartOf, series]
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

  def copyright
    return unless bibtex.field?(:copyright)
    remove_from_fallback(:copyright)

    graph << [entry, RDF::DC.rightsHolder, bibtex[:copyright].to_s]
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
      node = agent(name) { create_agent(name, :Person) }

      graph << [entry, bibo.name, node]
      graph << [seq, RDF.li, node]
    end
  end

  def howpublished
    return unless bibtex.field?(:howpublished)
    return unless bibtex[:howpublished] =~ /^#{URI::regexp}$/

    remove_from_fallback(:howpublished)
    graph << [entry, RDF::DC.URI, bibtex[:howpublished].to_s]
    graph << [entry, bibo[:uri], bibtex[:howpublished].to_s]
  end

  def institution
    return unless bibtex.field?(:institution)
    remove_from_fallback(:institution)

    org = agent(bibtex[:institution]) { create_agent(bibtex[:institution].to_s, :Organization) }

    graph << [entry, RDF::DC.contributor, org]
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
    remove_from_fallback(:journal)

    source = []
    source << bibtex[:journal].to_s
    source << "Vol. #{bibtex[:volume].to_s}" if bibtex.field?(:volume)
    source << "No. #{bibtex[:number].to_s}" if bibtex.field?(:number)
    pagination = bibtex[:pagination] || 'pp.'
    source << "#{pagination.to_s} #{bibtex[:pages].to_s}" if bibtex.field?(:pages)
    graph << [entry, RDF::DC.source, source.join(', ')]

    return if bibtex.has_parent? && bibtex.parent[:title] == bibtex[:journal]
    return if bibtex.has_parent? && bibtex.parent[:issn] == bibtex[:issn]

    journal = RDF::Node.new
    graph << [journal, RDF.type, bibo[:Journal]]
    graph << [journal, RDF::DC.title, bibtex[:journal].to_s]

    graph << [entry, RDF::DC.isPartOf, journal]
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

  def location
    return unless bibtex.field?(:location)
    remove_from_fallback(:location)

    graph << [entry, RDF::DC.Location, bibtex[:location].to_s]
    if [:proceedings, :inproceedings, :conference].include?(bibtex.type)
      event = RDF::Vocabulary.new('http://purl.org/NET/c4dm/event.owl')
      graph << [entry, event[:place], org]
    end
  end

  def lccn
    return unless bibtex.field?(:lccn)
    remove_from_fallback(:lccn)

    graph << [entry, bibo[:lccn], bibtex[:lccn].to_s]
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

    org = agent(bibtex[:organization]) { create_agent(bibtex[:organization].to_s, :Organization) }

    graph << [entry, RDF::DC.contributor, org]
    graph << [entry, bibo[:organizer], org] if [:proceedings, :inproceedings, :conference].include?(bibtex.type)
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

  def pagetotal
    return unless bibtex.field?(:pagetotal)
    remove_from_fallback(:pagetotal)

    graph << [entry, bibo[:numPages], bibtex[:pagetotal].to_s]
  end

  def parent
    return unless bibtex.has_parent?
    remove_from_fallback(:crossref)

    graph << [entry, RDF::DC.isPartOf, bibtex.parent.to_rdf]
  end

  def publisher
    return unless bibtex.field?(:publisher) || bibtex.field?(:organization) || bibtex.field?(:school)
    remove_from_fallback(:publisher, :address)

    org =
      case
      when bibtex.field?(:publisher)
        agent(bibtex[:publisher]) { create_agent(bibtex[:publisher].to_s, :Organization) }
      when bibtex.field?(:organization)
        agent(bibtex[:organization]) { create_agent(bibtex[:organization].to_s, :Organization) }
      when bibtex.field?(:school)
        agent(bibtex[:school]) { create_agent(bibtex[:school].to_s, :Organization) }
      end

    if bibtex.field?(:address)
      address = RDF::Vocabulary.new('http://schemas.talis.com/2005/address/schema#')
      graph << [org, address[:localityName], bibtex[:address]]
    end

    graph << [entry, RDF::DC.publisher, org]
    graph << [entry, bibo[:publisher], org]
  end

  def school
    return unless bibtex.field?(:school)
    remove_from_fallback(:school)

    org = agent(bibtex[:school]) { create_agent(bibtex[:school].to_s, :Organization) }

    graph << [entry, RDF::DC.contributor, org]
  end

  def series
    return unless bibtex.field?(:series)
    remove_from_fallback(:series)
    return if bibtex.has_parent? && bibtex.parent[:title] == bibtex[:series]
    return if bibtex.has_parent? && bibtex.parent[:series] == bibtex[:series]
    return if bibtex.has_parent? && bibtex.parent[:issn] == bibtex[:issn]

    series = RDF::Node.new
    graph << [series, RDF.type, bibo[:MultiVolumeBook]]
    graph << [series, RDF::DC.title, bibtex[:series].to_s]

    graph << [entry, RDF::DC.isPartOf, series]
  end

  def thesis_degree
    return unless bibo_class == :Thesis

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
    return unless bibtex.field?(:title)
    remove_from_fallback(:title)

    title = [bibtex[:title].to_s, bibtex[:subtitle].to_s].join(': ')
    graph << [entry, RDF::DC.title, title]
    graph << [entry, bibo[:shortTitle], bibtex[:title].to_s] if bibtex.field?(:subtitle)
  end

  def translator
    return unless bibtex.field?(:translator)
    remove_from_fallback(:translator)

    node = agent(bibtex[:translator]) { create_agent(bibtex[:translator].to_s, :Person) }

    graph << [entry, RDF::DC.contributor, node]
    graph << [entry, bibo[:translator], node]
  end

  def type
    graph << [entry, RDF.type, bibo_class]

    case bibtex.type
    when :proceedings, :journal
      graph << [entry, RDF::DC.type, 'Collection']
    else
      graph << [entry, RDF::DC.type, 'Text']
    end
  end

  def url
    return unless bibtex.field?(:url)
    remove_from_fallback(:url)

    graph << [entry, RDF::DC.URI, bibtex[:url].to_s]
    graph << [entry, bibo[:uri], bibtex[:url].to_s]
  end

  def volume
    return unless bibtex.field?(:volume)
    remove_from_fallback(:volume)

    graph << [entry, bibo[:volume], bibtex[:volume].to_s]
  end

  def volumes
    return unless bibtex.field?(:volumes)
    remove_from_fallback(:volumes)

    graph << [entry, bibo[:numVolumes], bibtex[:volumes].to_s]
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

  attr_reader :bibtex, :graph

  def bibo
    @bibo ||= RDF::Vocabulary.new('http://purl.org/ontology/bibo/')
  end

  def bibo_class
    BIBO_TYPES[bibtex[:type]] || BIBO_TYPES[bibtex.type] || :Document
  end

  def entry
    @entry ||= RDF::URI.new(bibtex.identifier)
  end

  def agent(key, &block)
    @agent ||= {}
    @agent[key] ||= yield
  end

  def create_agent(name, type)
    node = RDF::Node.new

    graph << [node, RDF.type, RDF::FOAF[type]]
    graph << [node, RDF::FOAF.name, name.to_s]

    if name.is_a?(BibTeX::Name)
      [:given, :family, :prefix, :suffix].each do |part|
        graph << [node, bibo["#{part}Name"], name.send(part).to_s] unless name.send(part).nil?
      end
    end

    node
  end

  def fallback
    @fallback ||= bibtex.fields.keys
  end

  def remove_from_fallback(*fields)
    fields.each { |field| fallback.delete(field) }
  end

  def run_fallback
    return if fallback.empty?

    ml = RDF::Vocabulary.new('http://bibtexml.sf.net/')
    fallback.each do |field|
      graph << [entry, ml[field], bibtex[field]]
    end
  end
end
