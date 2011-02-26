require 'helper.rb'

class TestEntry < MiniTest::Unit::TestCase
  
  def setup
  end

  def teardown
  end

  def test_simple
    bib = BibTeX::Bibliography.open('test/bib/07_entry.bib', :debug => true)
    refute_nil(bib)
    assert_equal(BibTeX::Bibliography, bib.class)
    assert_equal(3, bib.data.length)
    assert_equal([BibTeX::Entry], bib.data.map(&:class).uniq)
    assert_equal('key:0', bib.data[0].key)
    assert_equal('key:1', bib.data[1].key)
    assert_equal('foo', bib.data[2].key)
    assert_equal(:book, bib.data[0].type)
    assert_equal(:article, bib.data[1].type)
    assert_equal(:article, bib.data[2].type)
    assert_equal('Poe, Edgar A.', bib.data[0][:author])
    assert_equal('Hawthorne, Nathaniel', bib.data[1][:author])
    assert_equal('2003', bib.data[0][:year])
    assert_equal('2001', bib.data[1][:year])
    assert_equal('American Library', bib.data[0][:publisher])
    assert_equal('American Library', bib.data[1][:publisher])
    assert_equal('Selected \\emph{Poetry} and `Tales\'', bib.data[0].title)
    assert_equal('Tales and Sketches', bib.data[1].title)
  end
  
  def test_ghost_methods
    bib = BibTeX::Bibliography.open('test/bib/07_entry.bib', :debug => true)
    refute_nil(bib)
    assert_equal(BibTeX::Bibliography, bib.class)
    assert_equal('Poe, Edgar A.', bib.data[0].author)
    
    expected = 'Poe, Edgar Allen'
    bib.data[0].author = expected
    
    assert_equal(expected, bib.data[0].author)
  end
  
  def test_creation_simple
    expected = "@book{raven,\n  author = {Poe, Edgar A.},\n  title = {The Raven}\n}\n"
    
    entry = BibTeX::Entry.new
    entry.type = :book
    entry.key = 'raven'
    entry.author = 'Poe, Edgar A.'
    entry.title = 'The Raven'
    
    assert_equal(expected, entry.to_s)
  end

  def test_creation_from_hash
    expected = "@book{raven,\n  author = {Poe, Edgar A.},\n  title = {The Raven}\n}\n"
    
    entry = BibTeX::Entry.new({
      :type => 'book',
      :key => 'raven',
      :author => 'Poe, Edgar A.',
      :title => 'The Raven'
    })
    
    assert_equal(expected, entry.to_s)
  end

  def test_creation_from_block
    expected = "@book{raven,\n  author = {Poe, Edgar A.},\n  title = {The Raven}\n}\n"
    
    entry = BibTeX::Entry.new do |e|
      e.type = :book
      e.key = 'raven'
      e.author = 'Poe, Edgar A.'
      e.title = 'The Raven'
    end
    
    assert_equal(expected, entry.to_s)
  end
  
end
