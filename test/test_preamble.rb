require 'bibtex'
require 'minitest/unit'
require 'minitest/autorun'

class TestPreamble < MiniTest::Unit::TestCase
  
  def setup
    @parser = BibTeX::Parser.new(:debug => true)
  end

  def teardown
    @parser.clear_state
  end

  def test_simple
    bib = @parser.parse(File.open('test/bib/06_preamble.bib').read)
    refute_nil(bib)
    assert_equal(BibTeX::Bibliography, bib.class)
    assert_equal(4, bib.data.length)
    assert_equal([BibTeX::Preamble,BibTeX::String], bib.data.map(&:class).uniq)
    assert_equal(["This bibliography was created \\today"], bib.data[0].value.value)
    assert_equal(["Bib\\TeX"], bib.data[1].value.value)
    assert_equal(["Maintained by ",:maintainer], bib.data[3].value.value)
  end
end
