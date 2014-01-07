begin
  require 'simplecov'
rescue LoadError
  # ignore
end

begin
  if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
    require 'rubinius-debugger'

    # We currently need this for RBX to work
    # but can't specify Gemfile dependency
    # because of minitest 4/5 version mismatch!
    require 'test/unit'
  else
    require 'debugger'
  end
rescue LoadError
  # ignore
end

require 'bibtex'
require 'minitest'

module Cucumber
  module MinitestAssertions
    def self.extended(base)
      base.extend(Minitest::Assertions)
      base.assertions = 0
    end

    attr_accessor :assertions
  end
end

World(Cucumber::MinitestAssertions)
