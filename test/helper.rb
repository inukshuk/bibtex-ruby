begin
  if RUBY_VERSION >= '1.9'
    require 'debugger'
    require 'simplecov'
  else
    # require 'debug'
  end  
rescue LoadError
  # ignore
end

require 'minitest/autorun'
require 'minitest/colorize'
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
