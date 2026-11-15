# frozen_string_literal: true

require 'helper'

module BibTeX
  class BibliographyRDFConverterTest < Minitest::Spec
    before do
      skip 'RDF support not available' unless defined?(::RDF)
    end

    let(:bibliography) do
      BibTeX.parse <<~BIB
        @book{a, author = {Doe, Jane}, title = {First}, year = {2001}}
        @article{b, author = {Doe, Jane and Roe, Rick}, title = {Second}, journal = {J}, year = {2002}}
        @string{foo = "bar"}
      BIB
    end

    describe '.convert' do
      it 'returns an RDF graph with one statement set per entry' do
        graph = BibTeX::Bibliography::RDFConverter.convert(bibliography)

        assert_kind_of ::RDF::Graph, graph
        refute_empty graph
        titles = graph.query([nil, ::RDF::Vocab::DC.title, nil]).map { |s| s.object.to_s }

        assert_includes titles, 'First'
        assert_includes titles, 'Second'
      end

      it 'returns an empty graph for an empty bibliography' do
        assert_empty BibTeX::Bibliography::RDFConverter.convert(BibTeX::Bibliography.new)
      end

      it 'adds to a supplied graph' do
        graph = ::RDF::Graph.new
        result = BibTeX::Bibliography::RDFConverter.new(bibliography, graph).convert!

        assert_same graph, result
        refute_empty graph
      end
    end

    describe 'Bibliography#to_rdf' do
      it 'returns a graph' do
        assert_kind_of ::RDF::Graph, bibliography.to_rdf
      end
    end
  end
end
