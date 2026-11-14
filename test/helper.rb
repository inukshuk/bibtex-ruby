# frozen_string_literal: true

begin
  require 'simplecov'
rescue LoadError
  # ignore
end

begin
  require 'debug' unless RUBY_PLATFORM == 'java'
rescue LoadError
  # ignore
end

require 'minitest/autorun'

require 'tempfile'

require 'bibtex'

# The existing tests exercise the deprecated string selectors on purpose;
# keep them quiet even when the suite runs with Warning[:deprecated] = true.
# test_queries.rb resets this to assert on the warning itself.
BibTeX::Deprecation.silence!

module BibTeX
  module Test
    class << self
      def fixtures(name)
        File.expand_path("../fixtures/#{name}.bib", __FILE__)
      end
    end
  end
end
