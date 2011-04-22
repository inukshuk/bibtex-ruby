require 'helper.rb'

require 'yaml'
require 'json'

module BibTeX
  class TestString < MiniTest::Unit::TestCase
  
    def setup
    end

    def teardown
    end

    def test_yaml
      bib = BibTeX::Bibliography.open(Test.fixtures(:bibdesk), :debug => true)
      yaml = YAML.load(bib.to_yaml)
      refute_nil(yaml)
      assert_equal(3, yaml.length)
      assert_equal(['dragon', 'pickaxe', 'rails'], yaml.map { |y| y['key'] }.sort)
      assert_equal('{The Facets of Ruby}', yaml[0]['series'])
    end
  
    def test_json
      bib = BibTeX::Bibliography.open(Test.fixtures(:bibdesk), :debug => true)
      json = JSON.parse(bib.to_json)
      refute_nil(json)
      assert_equal(3, json.length)
      assert_equal(['dragon', 'pickaxe', 'rails'], json.map { |y| y['key'] }.sort)
      assert_equal('{The Facets of Ruby}', json[0]['series'])
    end
  end
end