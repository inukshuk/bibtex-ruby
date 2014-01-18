begin
  require 'rdf'
rescue LoadError
  BibTeX.log.error 'Please gem install rdf for RDF support.'
end

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
    methods = self.class.instance_methods(false) - [:output]
    methods.each { |m| send(m) }

    graph
  end

  def abstract
    graph << [entry, RDF::DC.abstract, bibtex[:abstract].to_s] if bibtex.field?(:abstract)
  end

  def author
    return unless bibtex.field?(:author)

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

  def doi
    graph << [entry, bibo[:doi], bibtex[:doi].to_s] if bibtex.field?(:doi)
  end

  def edition
    graph << [entry, bibo[:edition], bibtex[:edition].to_s] if bibtex.field?(:edition)
  end

  def editor
    return unless bibtex.field?(:editor)

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
    graph << [entry, bibo[:isbn], bibtex[:isbn].to_s] if bibtex.field?(:isbn)
  end

  def issn
    graph << [entry, bibo[:issn], bibtex[:issn].to_s] if bibtex.field?(:issn)
  end

  def language
    bibtex[:language] = 'german' if bibtex[:language] == 'ngerman'

    graph << [entry, RDF::DC.language, bibtex[:language].to_s] if bibtex.field?(:language)
  end

  def note
    return unless bibtex.field?(:note)

    pub = RDF::Node.new
    graph << [pub, RDF.type, bibo[:Note]]
    graph << [pub, bibo[:content], bibtex[:note]]


    graph << [entry, bibo[:annotates], pub]
  end

  def number
    return unless bibtex.field?(:number)

    case bibtex.type
    when :techreport || :manual || :unpublished
      graph << [entry, bibo[:number], bibtex[:number].to_s]
    else
      graph << [entry, bibo[:issue], bibtex[:number].to_s]
    end
  end

  def pages
    return unless bibtex.field?(:pages)

    if bibtex[:pages].to_s =~ /^\s*(\d+)\s*-+\s*(\d+)\s*$/
      graph << [entry, bibo[:pageStart], $1]
      graph << [entry, bibo[:pageEnd], $2]
    else
      graph << [entry, bibo[:pages], bibtex[:pages].to_s]
    end
  end

  def publisher
    return unless bibtex.field?(:publisher)

    pub = RDF::Node.new
    graph << [pub, RDF.type, RDF::FOAF[:Organization]]
    graph << [pub, RDF::FOAF.name, bibtex[:publisher]]

    if bibtex.field?(:address)
      address = RDF::Vocabulary.new('http://schemas.talis.com/2005/address/schema#')
      graph << [pub, address[:localityName], bibtex[:address]]
    end

    graph << [entry, RDF::DC.publisher, pub]
  end

  def thesis_degree
    return unless BIBO_TYPES[bibtex.type] == :Thesis

    case bibtex.type
    when :mastersthesis
      # ms = masters degree in science
      # Only ma and ms available. We simply chose one.
      graph << [entry, bibo[:degree], bibo['degrees/ms']]
    when :phdthesis
      graph << [entry, bibo[:degree], bibo['degrees/phd']]
    end
  end

  def title
    return unless bibtex.field?(:title) || bibtex.field?(:subtitle)

    title = [bibtex[:title].to_s, bibtex[:subtitle].to_s].join(': ')
    graph << [entry, RDF::DC.title, title]
  end

  def type
    graph << [entry, RDF.type, bibo[BIBO_TYPES[bibtex.type]]]
  end

  def volume
    graph << [entry, bibo[:volume], bibtex[:volume].to_s] if bibtex.field?(:volume)
  end

  def year
    return unless bibtex.field?(:year)

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
end
