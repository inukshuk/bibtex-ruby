require 'bibtex'
require 'minitest/unit'
require 'minitest/autorun'

class TestBibtex < MiniTest::Unit::TestCase
  
  def setup
    @parser = BibTeX::Parser.new(:debug => true)
  end

  def teardown
    @parser.clear_state
  end

  def test_empty
    bib = @parser.parse(File.open('test/bib/00_empty.bib').read)
    refute_nil(bib)
    assert_equal(BibTeX::Bibliography, bib.class)
    assert(bib.empty?)
  end

  def test_decoret
    bib = @parser.parse(File.open('test/bib/08_decoret.bib').read)
    refute_nil(bib)
    assert_equal(BibTeX::Bibliography, bib.class)
    assert_equal(15, bib.data.length)
    assert_equal([BibTeX::Entry,BibTeX::Comment,BibTeX::String,BibTeX::Preamble], bib.data.map(&:class).uniq)
    assert_equal('py03', bib.data[0].key)
    assert_equal(:article, bib.data[0].type)
    assert_equal("{:author=>[\"Xavier D\\\\'ecoret\"], :title=>[\"PyBiTex\"], :year=>[\"2003\"]}", bib.data[0].fields.inspect)
    assert_equal('key03', bib.data[1].key)
    assert_equal(:article, bib.data[1].type)
    assert_equal("{:title=>[\"A {bunch {of} braces {in}} title\"]}", bib.data[1].fields.inspect)
    #TODO missing assertions
  end
end

