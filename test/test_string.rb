require 'lib/bibtex'
require 'minitest/unit'
require 'minitest/autorun'

class TestString < MiniTest::Unit::TestCase
  
  def setup
    @parser = BibTeX::Parser.new
  end

  def teardown
    @parser.clear_state
  end

  def test_simple
    result = @parser.parse(File.open('test/bib/02_string.bib').read)
    refute_nil(result)
    assert_equal(result.length,1)
    assert(result.first.kind_of?(BibTeX::String))
    assert_equal(result.first.key, :foo)
    assert_equal(result.first.value, ['bar'])
  end

  def test_assignment
    result = @parser.parse(File.open('test/bib/03_string.bib').read)
    refute_nil(result)
    assert_equal(result.length,17)
    assert_equal(result.map(&:class).uniq, [BibTeX::String]) 
    assert_equal(result.map(&:key).uniq, [:foo]) 
    (0..10).each { |i| assert_equal(result[i].value, ['bar']) }
    assert_equal(result[11].value, ['\\\'bar\\\''])
    assert_equal(result[12].value, ['"bar"'])
    assert_equal(result[13].value, ['@bar@'])
    assert_equal(result[14].value, ['\'bar\''])
    assert_equal(result[15].value, ['\\"bar\\"'])
    assert_equal(result[16].value, ['{bar}'])
  end

  def test_replacement
    result = @parser.parse(File.open('test/bib/04_string_replacement.bib').read)
    refute_nil(result)
    assert_equal(result.length,5)
    assert_equal(result.map(&:class).uniq, [BibTeX::String]) 
    assert_equal(result[0].key, :foo)
    assert_equal(result[0].value, ['foo'])
    assert_equal(result[1].key, :bar)
    assert_equal(result[1].value, ['bar'])
    assert_equal(result[2].key, :foobar)
    assert_equal(result[2].value, [:foo,'bar'])
    assert_equal(result[3].key, :foobarfoo)
    assert_equal(result[3].value, [:foobar,:foo])
    assert_equal(result[4].key, :barfoobar)
    assert_equal(result[4].value, [:bar,:foo,:bar])
  end
end
