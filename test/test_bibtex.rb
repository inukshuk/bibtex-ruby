# frozen_string_literal: true

require 'helper'
require 'timeout'

module BibTeX
  class TestBibtex < Minitest::Test
    RAILS_BOOK = <<-BIBTEX
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

    # The entry in test/fixtures/roundtrip.bib.
    RAILS_ATTRIBUTES = {
      bibtex_type: :book,
      bibtex_key: 'rails',
      address: 'Raleigh, North Carolina',
      author: 'Ruby, Sam and Thomas, Dave and Hansson Heinemeier, David',
      booktitle: 'Agile Web Development with Rails',
      edition: 'third',
      keywords: 'ruby, rails',
      publisher: 'The Pragmatic Bookshelf',
      series: 'The Facets of Ruby',
      title: 'Agile Web Development with Rails',
      year: '2009'
    }.freeze

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

      with_meta = BibTeX::Bibliography.open(Test.fixtures(:no_bibtex), include: [:meta_content])

      assert_equal([BibTeX::MetaContent], with_meta.data.map(&:class))
    end

    def test_decoret
      bib = BibTeX::Bibliography.open(Test.fixtures(:decoret), debug: false)

      assert_equal(15, bib.length)
      assert_equal([BibTeX::Entry, BibTeX::Comment, BibTeX::String, BibTeX::Preamble], bib.data.map(&:class).uniq)
      assert_equal('py03', bib.data[0].key)
    end

    def test_decoret_objects
      bib = BibTeX::Bibliography.open(Test.fixtures(:decoret), debug: false)

      assert_equal(%w[py03 key03 key01 key02 steward03 sweig42], bib.entries.keys)
      assert_equal(%i[mar firstname lastname email maintainer], bib.strings.keys)
      assert_equal({ BibTeX::Entry => 6, BibTeX::Comment => 2, BibTeX::String => 5, BibTeX::Preamble => 2 },
                   bib.data.map(&:class).tally)
      assert_empty(bib.errors)
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

    def test_bibdesk
      bib = BibTeX::Bibliography.open(Test.fixtures(:bibdesk), debug: false)

      assert_equal 3, bib.length
      assert_equal %w[rails dragon pickaxe], bib.entries.keys
      assert_empty bib.errors
      assert_equal %i[address author booktitle date-added date-modified edition isbn keywords publisher series title year],
                   bib['rails'].fields.keys
      assert_equal '2010-08-05 10:06:32 +0200', bib[:dragon]['date-modified']
    end

    def test_roundtrip
      file = File.read(Test.fixtures(:roundtrip))
      bib = BibTeX.parse(file)

      assert_equal file.gsub(/\s+/, ''), bib.to_s.gsub(/\s+/, '')
    end

    def test_construct
      file = File.read(Test.fixtures(:roundtrip))
      bib = BibTeX::Bibliography.new
      bib << BibTeX::Entry.new(RAILS_ATTRIBUTES)

      assert_equal file.gsub(/\s+/, ''), bib.to_s.gsub(/\s+/, '')
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
