require 'bibtex'
require 'minitest/unit'
require 'minitest/autorun'

class TestString < MiniTest::Unit::TestCase
  
  def setup
    @parser = BibTeX::Parser.new(:debug => true)
  end

  def teardown
    @parser.clear_state
  end

  def test_simple
    result = @parser.parse(File.open('test/bib/02_string.bib').read)
    refute_nil(result)
    assert(result.kind_of? BibTeX::Bibliography)
    refute(result.empty?)
    assert_equal(result.data.length,1)
    assert(result.data.first.kind_of?(BibTeX::String))
    assert_equal(result.data.first.key, :foo)
    assert_equal(result.data.first.value.value, ['bar'])
  end

  def test_assignment
    result = @parser.parse(File.open('test/bib/03_string.bib').read)
    refute_nil(result)
    assert(result.kind_of? BibTeX::Bibliography)
    refute(result.empty?)
    assert_equal(result.data.length,17)
    assert_equal(result.data.map(&:class).uniq, [BibTeX::String]) 
    assert_equal(result.data.map(&:key).uniq, [:foo]) 
    (0..10).each { |i| assert_equal(result.data[i].value.value, ['bar']) }
    assert_equal(result.data[11].value.value, ['\\\'bar\\\''])
    assert_equal(result.data[12].value.value, ['"bar"'])
    assert_equal(result.data[13].value.value, ['@bar@'])
    assert_equal(result.data[14].value.value, ['\'bar\''])
    assert_equal(result.data[15].value.value, ['\\"bar\\"'])
    assert_equal(result.data[16].value.value, ['{bar}'])
  end

  def test_replacement
    result = @parser.parse(File.open('test/bib/04_string_replacement.bib').read)
    refute_nil(result)
    assert(result.kind_of? BibTeX::Bibliography)
    refute(result.empty?)
    assert_equal(result.data.length,5)
    assert_equal(result.data.map(&:class).uniq, [BibTeX::String]) 
    assert_equal(result.data[0].key, :foo)
    assert_equal(result.data[0].value.value, ['foo'])
    assert_equal(result.data[1].key, :bar)
    assert_equal(result.data[1].value.value, ['bar'])
    assert_equal(result.data[2].key, :foobar)
    assert_equal(result.data[2].value.value, [:foo,'bar'])
    assert_equal(result.data[3].key, :foobarfoo)
    assert_equal(result.data[3].value.value, [:foobar,:foo])
    assert_equal(result.data[4].key, :barfoobar)
    assert_equal(result.data[4].value.value, [:bar,'foo',:bar])
  end
end
