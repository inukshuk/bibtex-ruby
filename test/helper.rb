begin
  if RUBY_VERSION > '1.8'
    require 'debugger'
    require 'simplecov'
  else
    require 'ruby-debug'
    Debugger.start
  end
rescue LoadError
  # ignore
end

require 'minitest/autorun'
require 'tempfile'

begin
  require 'minitest/colorize'
rescue LoadError
  # ignore
end

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
