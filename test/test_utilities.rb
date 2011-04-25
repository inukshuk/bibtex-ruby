require 'helper.rb'

module BibTeX
  
  class TestBibtex < MiniTest::Unit::TestCase
  
    def test_empty?
      bib = BibTeX.open(Test.fixtures(:empty), :debug => false)
      refute_nil(bib)
      assert_equal(BibTeX::Bibliography, bib.class)
      assert(bib.empty?)
    end
  
    def test_parse
      bib = BibTeX.parse %q[ @book{ id, author = {Poe, Edgar Allen}, title = "Ligeia" } ]
      refute_nil(bib)
      assert_equal(BibTeX::Bibliography, bib.class)
      [
        [1, bib.length],
        ['Ligeia', bib[:id].title],
        ['Poe, Edgar Allen', bib[:id].author]
      ].each { |a| assert_equal(a[0], a[1]) }
    end
  
    def test_validate
      refute BibTeX.parse(%q[ @book{ id, author = {Poe, Edgar Allen}, title = "Ligeia" } ]).valid?
      assert BibTeX.parse(%q[ @book{ id, author = {Poe, Edgar Allen}, title = "Ligeia", publisher = "Penguin", year = 1996 } ]).valid?
      refute BibTeX.parse(%q[ @book{ id, author = {Poe, Edgar Allen}, title = "Lig"eia", publisher = "Penguin", year = 1996 } ]).valid?
      assert BibTeX.valid?(Test.fixtures(:bibdesk))
    end
  
  end
  
end