require 'helper.rb'

module BibTeX
  class TestString < MiniTest::Unit::TestCase
  
    def setup
    end

    def teardown
    end

    def test_simple
      bib = BibTeX::Bibliography.open(Test.fixtures(:string), :debug => false)
      refute_nil(bib)
      assert(bib.kind_of? BibTeX::Bibliography)
      refute(bib.empty?)
      assert_equal(bib.data.length,1)
      assert(bib.data.first.is_a?(BibTeX::String))
      assert_equal(:foo, bib.data.first.key)
      assert_equal('"bar"', bib.data.first.value)
      assert_equal(["bar"], bib.strings[:foo])
    end

    def test_assignment
      bib = BibTeX::Bibliography.open(Test.fixtures(:strings), :debug => false)
      refute_nil(bib)
      assert(bib.kind_of? BibTeX::Bibliography)
      refute(bib.empty?)
      assert_equal(17, bib.data.length)
      assert_equal(bib.data.map(&:class).uniq, [BibTeX::String]) 
      assert_equal(bib.data.map(&:key).uniq, [:foo]) 
      (0..10).each { |i| assert_equal( '"bar"', bib.data[i].value) }
      assert_equal(bib.data[11].value, '"\'bar\'"')
      assert_equal(bib.data[12].value, '"{"}bar{"}"')
      assert_equal(bib.data[13].value, '"@bar@"')
      assert_equal(bib.data[14].value, '"\'bar\'"')
      assert_equal(bib.data[15].value, '"{"}bar{"}"')
      assert_equal(bib.data[16].value, '"{bar}"')
    end

    def test_replacement
      bib = BibTeX::Bibliography.open(Test.fixtures(:string_replacement), :debug => false)
      refute_nil(bib)
      assert(bib.kind_of?(BibTeX::Bibliography))
      refute(bib.empty?)
      assert_equal(7,bib.length)
      assert_equal([BibTeX::String,BibTeX::Preamble,BibTeX::Entry], bib.data.map(&:class).uniq) 
      assert_equal(["foo"], bib.strings[:foo])
      assert_equal(["bar"], bib.strings[:bar])
      assert_equal([:foo, "bar"], bib.strings[:foobar])
      assert_equal([:foobar, :foo], bib.strings[:foobarfoo])
      assert_equal([:bar, "foo", :bar], bib.strings[:barfoobar])
      assert_equal('"foo" # foo # foobarfoo # "bar"', bib.preambles[0].content)
      assert_equal('"foo" # barfoobar', bib['manual:1'].title)

      bib.replace_strings({ :filter => [:preamble]})
      assert_equal(["foo"], bib.strings[:foo])
      assert_equal(["bar"], bib.strings[:bar])
      assert_equal([:foo, "bar"], bib.strings[:foobar])
      assert_equal([:foobar, :foo], bib.strings[:foobarfoo])
      assert_equal([:bar, "foo", :bar], bib.strings[:barfoobar])
      assert_equal('"foo" # "foo" # foobar # foo # "bar"', bib.preambles[0].content)
      assert_equal('"foo" # barfoobar', bib['manual:1'].title)
    
      bib.replace_strings({ :filter => [:string]})
      assert_equal(['foo','bar'], bib.strings[:foobar])
      assert_equal(['foo', 'bar','foo'], bib.strings[:foobarfoo])
      assert_equal(['bar','foo','bar'], bib.strings[:barfoobar])
      assert_equal('"foo" # "foo" # foobar # foo # "bar"', bib.preambles[0].content)
      assert_equal('"foo" # barfoobar', bib['manual:1'].title)

      bib.replace_strings({ :filter => [:preamble,:entry]})
      assert_equal('"foo" # "foo" # "foo" # "bar" # "foo" # "bar"', bib.preambles[0].content)
      assert_equal('"foo" # "bar" # "foo" # "bar"', bib['manual:1'].title)
    end
  
    def test_roundtrip
      bib = BibTeX::Bibliography.open(Test.fixtures(:string_replacement), :debug => false)
      refute_nil(bib)
      assert_equal('@string{ foo = "foo" }', bib.data[0].to_s)
      assert_equal('@string{ bar = "bar" }', bib.data[1].to_s)
      assert_equal('@string{ foobar = foo # "bar" }', bib.data[2].to_s)
      assert_equal('@string{ foobarfoo = foobar # foo }', bib.data[3].to_s)
      assert_equal('@string{ barfoobar = bar # "foo" # bar }', bib.data[4].to_s)
      bib.replace_strings
      assert_equal('@string{ foo = "foo" }', bib.data[0].to_s)
      assert_equal('@string{ bar = "bar" }', bib.data[1].to_s)
      assert_equal('@string{ foobar = "foo" # "bar" }', bib.data[2].to_s)
      assert_equal('@string{ foobarfoo = "foo" # "bar" # "foo" }', bib.data[3].to_s)
      assert_equal('@string{ barfoobar = "bar" # "foo" # "bar" }', bib.data[4].to_s)
      bib.join_strings
      assert_equal('@string{ foo = "foo" }', bib.data[0].to_s)
      assert_equal('@string{ bar = "bar" }', bib.data[1].to_s)
      assert_equal('@string{ foobar = "foobar" }', bib.data[2].to_s)
      assert_equal('@string{ foobarfoo = "foobarfoo" }', bib.data[3].to_s)
      assert_equal('@string{ barfoobar = "barfoobar" }', bib.data[4].to_s)
    end
  end
end