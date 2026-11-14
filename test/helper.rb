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

# Ruby 3.4+ warns when code mutates a "chilled" string (a string literal
# in a file without the frozen_string_literal comment, or the String
# returned by Symbol#to_s); a future Ruby will raise FrozenError instead.
# Turn those warnings into errors for bibtex-ruby's own code, so any test
# that reaches such a mutation fails. Older Rubies and JRuby never emit them.
module BibTeX
  module Test
    module ChilledStringWarnings
      LIB = File.expand_path('../lib/bibtex', __dir__)

      def warn(message, *, **)
        raise FrozenError, message if message.include?('will be frozen') && message.start_with?(LIB)

        super
      end
    end
  end
end

Warning.singleton_class.prepend(BibTeX::Test::ChilledStringWarnings)
Warning[:deprecated] = true

module BibTeX
  module Test
    class << self
      def fixtures(name)
        File.expand_path("../fixtures/#{name}.bib", __FILE__)
      end
    end
  end
end
