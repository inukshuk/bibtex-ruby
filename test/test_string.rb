require 'helper.rb'

class TestString < MiniTest::Unit::TestCase
  
  def setup
  end

  def teardown
  end

  def test_simple
    bib = BibTeX::Bibliography.open('test/bib/02_string.bib', :debug => true)
    refute_nil(bib)
    assert(bib.kind_of? BibTeX::Bibliography)
    refute(bib.empty?)
    assert_equal(bib.data.length,1)
    assert(bib.data.first.kind_of?(BibTeX::String))
    assert_equal(bib.data.first.key, :foo)
    assert_equal(bib.data.first.value, ['bar'])
  end

  def test_assignment
    bib = BibTeX::Bibliography.open('test/bib/03_string.bib', :debug => true)
    refute_nil(bib)
    assert(bib.kind_of? BibTeX::Bibliography)
    refute(bib.empty?)
    assert_equal(bib.data.length,17)
    assert_equal(bib.data.map(&:class).uniq, [BibTeX::String]) 
    assert_equal(bib.data.map(&:key).uniq, [:foo]) 
    (0..10).each { |i| assert_equal(bib.data[i].value, ['bar']) }
    assert_equal(bib.data[11].value, ['\'bar\''])
    assert_equal(bib.data[12].value, ['{"}bar{"}'])
    assert_equal(bib.data[13].value, ['@bar@'])
    assert_equal(bib.data[14].value, ['\'bar\''])
    assert_equal(bib.data[15].value, ['{"}bar{"}'])
    assert_equal(bib.data[16].value, ['{bar}'])
  end

  def test_replacement
    bib = BibTeX::Bibliography.open('test/bib/04_string_replacement.bib', :debug => true)
    refute_nil(bib)
    assert(bib.kind_of?(BibTeX::Bibliography))
    refute(bib.empty?)
    assert_equal(7,bib.length)
    assert_equal([BibTeX::String,BibTeX::Preamble,BibTeX::Entry], bib.data.map(&:class).uniq) 
    assert_equal(bib.strings[:foo], ['foo'])
    assert_equal(bib.strings[:bar], ['bar'])
    assert_equal(bib.strings[:foobar], [:foo,'bar'])
    assert_equal(bib.strings[:foobarfoo], [:foobar,:foo])
    assert_equal(bib.strings[:barfoobar], [:bar,'foo',:bar])
    assert_equal(['foo',:foo,:foobarfoo,'bar'], bib.preamble[0].value)
    assert_equal(['foo',:barfoobar], bib.entries['manual:1'][:title])

    bib.replace_strings({ :include => [BibTeX::Preamble]})
    assert_equal(bib.strings[:foo], ['foo'])
    assert_equal(bib.strings[:bar], ['bar'])
    assert_equal(bib.strings[:foobar], [:foo,'bar'])
    assert_equal(bib.strings[:foobarfoo], [:foobar,:foo])
    assert_equal(bib.strings[:barfoobar], [:bar,'foo',:bar])
    assert_equal(['foo','foo',:foobar,:foo,'bar'], bib.preamble[0].value)
    assert_equal(['foo',:barfoobar], bib.entries['manual:1'][:title])
    
    bib.replace_strings({ :include => [BibTeX::String]})
    assert_equal(bib.strings[:foobar], ['foo','bar'])
    assert_equal(bib.strings[:foobarfoo], ['foo', 'bar','foo'])
    assert_equal(bib.strings[:barfoobar], ['bar','foo','bar'])
    assert_equal(['foo','foo',:foobar,:foo,'bar'], bib.preamble[0].value)
    assert_equal(['foo',:barfoobar], bib.entries['manual:1'][:title])

    bib.replace_strings({ :include => [BibTeX::Preamble,BibTeX::Entry]})
    assert_equal(['foo','foo','foo','bar','foo','bar'], bib.preamble[0].value)
    assert_equal(['foo','bar','foo','bar'], bib.entries['manual:1'][:title])
  end
end
