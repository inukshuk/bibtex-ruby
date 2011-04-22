require 'helper.rb'

module BibTeX
  class TestPreamble < MiniTest::Unit::TestCase
  
    def setup
      @bib = BibTeX::Bibliography.open(Test.fixtures(:preamble), :debug => true, :strict => false)
    end

    def teardown
    end

    def test_simple
      refute_nil(@bib)
      assert_equal(BibTeX::Bibliography, @bib.class)
      assert_equal(4, @bib.data.length)
      assert_equal([BibTeX::Preamble,BibTeX::String], @bib.data.map(&:class).uniq)
      assert_equal('"This bibliography was created \\today"', @bib.data[0].content)
      assert_equal('"Bib\\TeX"', @bib.data[1].content)
      assert_equal('"Maintained by " # maintainer', @bib.data[3].content)
    end
  
    def test_roundtrip
      assert_equal(%q[@preamble{ "This bibliography was created \today" }], @bib.data[0].to_s)
      assert_equal(%q[@preamble{ "Bib\TeX" }], @bib.data[1].to_s)
      assert_equal(%q[@string{ maintainer = "Myself" }], @bib.data[2].to_s)
      assert_equal(%q[@preamble{ "Maintained by " # maintainer }], @bib.data[3].to_s)
    end
  
    def test_replacement
      bib = BibTeX::Bibliography.open(Test.fixtures(:preamble), :debug => true, :strict => false)
      refute_nil(bib)
      assert_equal(%q[@preamble{ "Maintained by " # maintainer }], bib.data[3].to_s)
      bib.replace_strings
      assert_equal('"Maintained by " # "Myself"', bib.data[3].content)
      assert_equal(%q[@preamble{ "Maintained by " # "Myself" }], bib.data[3].to_s)    
      bib.join_strings
      assert_equal(%q[@preamble{ "Maintained by Myself" }], bib.data[3].to_s)    
    end
  end
end