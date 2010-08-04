require 'rubygems'
require 'bibtex'
require 'minitest/unit'
require 'minitest/autorun'

class TestPreamble < MiniTest::Unit::TestCase
  
  def setup
  end

  def teardown
  end

  def test_simple
    bib = BibTeX::Bibliography.open('test/bib/06_preamble.bib', :debug => true, :strict => false)
    refute_nil(bib)
    assert_equal(BibTeX::Bibliography, bib.class)
    assert_equal(4, bib.data.length)
    assert_equal([BibTeX::Preamble,BibTeX::String], bib.data.map(&:class).uniq)
    assert_equal(["This bibliography was created \\today"], bib.data[0].value)
    assert_equal(["Bib\\TeX"], bib.data[1].value)
    assert_equal(["Maintained by ",:maintainer], bib.data[3].value)
  end
end
