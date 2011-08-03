
require 'mini_shoulda'
require 'minitest/autorun'
require 'redgreen'
require 'tempfile'

require 'bibtex'

module BibTeX
  module Test
    
    class << self
      def fixtures(name)
        File.expand_path("../fixtures/#{name}.bib", __FILE__)
      end
    end
    
  end
end