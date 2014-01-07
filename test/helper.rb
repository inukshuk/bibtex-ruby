begin
  require 'simplecov'
rescue LoadError
  # ignore
end

begin
  if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
    require 'rubysl-test-unit'
    require 'rubinius-debugger'
  else
    require 'debugger'
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
