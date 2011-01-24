require File.expand_path('../../lib/bibtex.rb', __FILE__)
require 'minitest/unit'
require 'minitest/autorun'

class TestString < MiniTest::Unit::TestCase
  
  def setup
    @bib = BibTeX::Bibliography.open('test/bib/10_bibdesk.bib', :debug => true)
  end

  def teardown
  end

  def test_yaml
    yaml = @bib.to_yaml
    refute_nil(yaml)
    assert_equal(3, yaml.length)
    ['rails', 'dragon', 'pickaxe'].each do |k|
      refute_nil(yaml[k])
    end
    assert_equal('The Facets of Ruby', yaml['rails']['series'])
  end
end