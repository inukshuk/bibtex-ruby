require 'rubygems'
require 'bibtex'
require 'minitest/unit'
require 'minitest/autorun'

class TestBibtex < MiniTest::Unit::TestCase
  
  def setup
  end

  def teardown
  end

  def test_empty
    bib = BibTeX::Bibliography.open('test/bib/00_empty.bib', :debug => true)
    refute_nil(bib)
    assert_equal(BibTeX::Bibliography, bib.class)
    assert(bib.empty?)
  end

  def test_no_bibtex
    bib = BibTeX::Bibliography.open('test/bib/01_no_bibtex.bib', :debug => true)
    refute_nil(bib)
    assert_equal(BibTeX::Bibliography, bib.class)
    assert(bib.empty?)
  end

  def test_decoret
    bib = BibTeX::Bibliography.open('test/bib/08_decoret.bib', :debug => true)
    refute_nil(bib)
    assert_equal(BibTeX::Bibliography, bib.class)
    assert_equal(15, bib.length)
    assert_equal([BibTeX::Entry,BibTeX::Comment,BibTeX::String,BibTeX::Preamble], bib.data.map(&:class).uniq)
    assert_equal('py03', bib.data[0].key)
    assert_equal(:article, bib['py03'].type)
    assert_equal(['Xavier D\\\'ecoret'], bib['py03'][:author])
    assert_equal(['PyBiTex'], bib['py03'][:title])
    assert_equal(['2003'], bib['py03'][:year])
    assert_equal(:article, bib['key03'].type)
    assert_equal(['A {bunch {of} braces {in}} title'], bib['key03'][:title])
    #TODO missing assertions
  end
end

