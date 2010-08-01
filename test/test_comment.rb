require 'bibtex'
require 'minitest/unit'
require 'minitest/autorun'

class TestComment < MiniTest::Unit::TestCase
  
  def setup
    @parser = BibTeX::Parser.new
  end

  def teardown
    @parser.clear_state
  end

  def test_simple
    bib = @parser.parse(File.open('test/bib/05_comment.bib').read)
    refute_nil(bib)
    assert_equal(BibTeX::Bibliography, bib.class)
    assert_equal(2, bib.data.length)
    assert_equal([BibTeX::Comment], bib.data.map(&:class).uniq)
    assert_equal(' A comment can contain pretty much anything ', bib.data[0].content)
    assert_equal("\n@string{ foo = \"bar\" }\n\n@string{ bar = \"foo\" }\n", bib.data[1].content)
  end
end
