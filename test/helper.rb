begin
  require 'simplecov'
  require 'debugger'
rescue LoadError
  # ignore
end

require 'minitest/autorun'
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