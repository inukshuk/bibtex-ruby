require 'helper.rb'

class TestBibtex < MiniTest::Unit::TestCase
  
  def setup
  end

  def teardown
  end

  def test_empty
    bib = BibTeX::Bibliography.open('test/bib/00_empty.bib', :debug => true)
    refute_nil(bib)
    assert_equal(BibTeX::Bibliography, bib.class)
    assert(bib.empty?)
  end

  def test_no_bibtex
    bib = BibTeX::Bibliography.open('test/bib/01_no_bibtex.bib', :debug => true)
    refute_nil(bib)
    assert_equal(BibTeX::Bibliography, bib.class)
    assert(bib.empty?)
  end

  def test_decoret
    bib = BibTeX::Bibliography.open('test/bib/08_decoret.bib', :debug => true)
    refute_nil(bib)
    assert_equal(BibTeX::Bibliography, bib.class)
    assert_equal(15, bib.length)
    assert_equal([BibTeX::Entry,BibTeX::Comment,BibTeX::String,BibTeX::Preamble], bib.data.map(&:class).uniq)
    assert_equal('py03', bib.data[0].key)
    assert_equal(:article, bib['py03'].type)
    assert_equal("Xavier D\\'ecoret", bib['py03'][:author])
    assert_equal('PyBiTex', bib['py03'][:title])
    assert_equal('2003', bib['py03'][:year])
    assert_equal(:article, bib['key03'].type)
    assert_equal('A {bunch {of} braces {in}} title', bib['key03'][:title])
    #TODO missing assertions
  end
  
  def test_errors
    bib = BibTeX.open('test/bib/09_errors.bib', :debug => true)
    #refute_nil(bib)
  end
  
  def test_bibdesk
    bib = BibTeX::Bibliography.open('test/bib/10_bibdesk.bib', :debug => true)
    refute_nil(bib)
    assert_equal(BibTeX::Bibliography, bib.class)
    assert_equal(3, bib.length)
    assert_equal('rails', bib.data[0].key)
    assert_equal('2010-08-05 10:06:32 +0200', bib[:dragon]['date-modified'])
  end
  
  def test_roundtrip
    file = File.read('test/bib/11_roundtrip.bib')
    bib = BibTeX.parse(file, :debug => true)
    refute_nil(bib)
    assert_equal(BibTeX::Bibliography, bib.class)
    assert_equal(1, bib.length)
    assert_equal(file.gsub(/[\s]+/, ''), bib.to_s.gsub(/[\s]+/, ''))
  end
  
  def test_construct
    file = File.read('test/bib/11_roundtrip.bib')
    bib = BibTeX::Bibliography.new
    bib << BibTeX::Entry.new({
      :type => :book,
      :key => 'rails',
      :address => 'Raleigh, North Carolina',
      :author => 'Ruby, Sam, and Thomas, Dave, and Hansson, David Heinemeier',
      :booktitle => 'Agile Web Development with Rails',
      :edition => 'third',
      :keywords => 'ruby, rails',
      :publisher => 'The Pragmatic Bookshelf',
      :series => 'The Facets of Ruby',
      :title => 'Agile Web Development with Rails',
      :year => '2009'
    })
    assert_equal(file.gsub(/[\s]+/, ''), bib.to_s.gsub(/[\s]+/, ''))    
  end
  
  def test_parse
    file = File.read('test/bib/11_roundtrip.bib')
    bib = BibTeX::Bibliography.new
    bib.add(BibTeX::Element.parse(%q( @string{ pragprog = "The Pragmatic Booksehlf" } )))
    bib.add(BibTeX::Element.parse(<<-END
    @book{rails,
      address = {Raleigh, North Carolina},
      author = {Ruby, Sam, and Thomas, Dave, and Hansson, David Heinemeier},
      booktitle = {Agile Web Development with Rails},
      edition = {third},
      keywords = {ruby, rails},
      publisher = {The Pragmatic Bookshelf},
      series = {The Facets of Ruby},
      title = {Agile Web Development with Rails},
      year = {2009}
    }    
    END
    ))
    
    assert_equal(2, bib.length)
    refute_nil(bib[:rails])
    bib.replace_strings
    assert_equal(file.gsub(/[\s]+/, ''), bib[:rails].to_s.gsub(/[\s]+/, ''))
  end
end

