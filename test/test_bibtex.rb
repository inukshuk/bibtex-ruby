# frozen_string_literal: true

require 'helper'
require 'timeout'

module BibTeX
  class TestBibtex < Minitest::Test
    RAILS_BOOK = <<-BIBTEX.freeze
      @book{rails,
        address = {Raleigh, North Carolina},
        author = {Ruby, Sam and Thomas, Dave and Hansson Heinemeier, David},
        booktitle = {Agile Web Development with Rails},
        edition = {third},
        keywords = {ruby, rails},
        publisher = pragprog,
        series = {The Facets of Ruby},
        title = {Agile Web Development with Rails},
        year = {2009}
      }
    BIBTEX

    def setup; end

    def teardown; end

    def test_empty
      bib = BibTeX::Bibliography.open(Test.fixtures(:empty), debug: false)

      refute_nil(bib)
      assert_instance_of(BibTeX::Bibliography, bib)
      assert_empty(bib)
    end

    def test_no_bibtex
      bib = BibTeX::Bibliography.open(Test.fixtures(:no_bibtex), debug: false)

      refute_nil(bib)
      assert_instance_of(BibTeX::Bibliography, bib)
      assert_empty(bib)
    end

    def test_decoret
      bib = BibTeX::Bibliography.open(Test.fixtures(:decoret), debug: false)

      assert_equal(15, bib.length)
      assert_equal([BibTeX::Entry, BibTeX::Comment, BibTeX::String, BibTeX::Preamble], bib.data.map(&:class).uniq)
      assert_equal('py03', bib.data[0].key)
      # TODO: missing assertions
    end

    def test_decoret_py03
      entry = BibTeX::Bibliography.open(Test.fixtures(:decoret), debug: false)[:py03]

      assert_equal(:article, entry.type)
      assert_equal("D\\'ecoret, Xavier", entry[:author].to_s)
      assert_equal('PyBiTex', entry[:title])
      assert_equal('2003', entry[:year])
    end

    def test_decoret_key03
      entry = BibTeX::Bibliography.open(Test.fixtures(:decoret), debug: false)[:key03]

      assert_equal(:article, entry.type)
      assert_equal('A {bunch {of} braces {in}} title', entry[:title])
    end

    # def test_errors
    #   bib = BibTeX.open(Test.fixtures(:errors), :debug => false)
    #   #refute_nil(bib)
    # end

    def test_bibdesk
      bib = BibTeX::Bibliography.open(Test.fixtures(:bibdesk), debug: false)

      assert_equal 3, bib.length
      assert_equal 'rails', bib[0].key
      assert_equal '2010-08-05 10:06:32 +0200', bib[:dragon]['date-modified']
    end

    def test_roundtrip
      # file = File.read(Test.fixtures(:roundtrip))
      # bib = BibTeX.parse(file, :debug => false)
      # assert_equal file.gsub(/[\s]+/, ''), bib.to_s.gsub(/[\s]+/, '')
    end

    def test_construct
      # file = File.read(Test.fixtures(:roundtrip))
      # bib = BibTeX::Bibliography.new
      # bib << BibTeX::Entry.new({
      #   :bibtex_type => :book,
      #   :key => 'rails',
      #   :address => 'Raleigh, North Carolina',
      #   :author => 'Ruby, Sam and Thomas, Dave and Hansson Heinemeier, David',
      #   :booktitle => 'Agile Web Development with Rails',
      #   :edition => 'third',
      #   :keywords => 'ruby, rails',
      #   :publisher => 'The Pragmatic Bookshelf',
      #   :series => 'The Facets of Ruby',
      #   :title => 'Agile Web Development with Rails',
      #   :year => '2009'
      # })
      # assert_equal(file.gsub(/[\s]+/, ''), bib.to_s.gsub(/[\s]+/, ''))
    end

    def test_parse
      bib = BibTeX::Bibliography.new
      bib.add(BibTeX::Element.parse(' @string{ pragprog = "The Pragmatic Bookshelf" } '))
      bib.add(BibTeX::Element.parse(RAILS_BOOK))

      assert_equal(2, bib.length)
      refute_nil(bib[:rails])
      bib.replace_strings

      assert_equal 'The Pragmatic Bookshelf', bib['rails'].publisher
    end

    def test_logger_can_be_assigned
      logger = BibTeX.log
      BibTeX.log = logger
    end

    def test_missing_key
      assert_raises(BibTeX::ParseError) do
        BibTeX.parse(<<-BIBTEX)
          @article{}
        BIBTEX
      end
    end

    def test_missing_key_allowed
      refute_empty BibTeX.parse(<<-BIBTEX, allow_missing_keys: true)
        @article{}
      BIBTEX
      refute_empty BibTeX.parse(<<-BIBTEX, allow_missing_keys: true)
        @article{},
        @article{}
      BIBTEX
    end
  end
end
