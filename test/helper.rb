begin
  require 'simplecov'
rescue LoadError
  # ignore
end

begin
  if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
    require 'rubinius-debugger'
  else
    require 'debugger'
  end
rescue LoadError
  # ignore
end

require 'minitest/autorun'
require 'minitest/ansi'

Minitest::ANSI.use!

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
