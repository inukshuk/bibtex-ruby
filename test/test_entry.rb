require 'rubygems'
require 'bibtex'
require 'minitest/unit'
require 'minitest/autorun'

class TestEntry < MiniTest::Unit::TestCase
  
  def setup
  end

  def teardown
  end

  def test_simple
    bib = BibTeX::Bibliography.open('test/bib/07_entry.bib', :debug => true)
    refute_nil(bib)
    assert_equal(BibTeX::Bibliography, bib.class)
    assert_equal(3, bib.data.length)
    assert_equal([BibTeX::Entry], bib.data.map(&:class).uniq)
    assert_equal('key:0', bib.data[0].key)
    assert_equal('key:1', bib.data[1].key)
    assert_equal('foo', bib.data[2].key)
    assert_equal(:book, bib.data[0].type)
    assert_equal(:article, bib.data[1].type)
    assert_equal(:article, bib.data[2].type)
    assert_equal(['Poe, Edgar A.'], bib.data[0].fields[:author])
    assert_equal(['Hawthorne, Nathaniel'], bib.data[1].fields[:author])
    assert_equal(['2003'], bib.data[0].fields[:year])
    assert_equal(['2001'], bib.data[1].fields[:year])
    assert_equal(['American Library'], bib.data[0].fields[:publisher])
    assert_equal(['American Library'], bib.data[1].fields[:publisher])
    assert_equal(['Selected \\emph{Poetry} and `Tales\''], bib.data[0].fields[:title])
    assert_equal(['Tales and Sketches'], bib.data[1].fields[:title])
  end
end
