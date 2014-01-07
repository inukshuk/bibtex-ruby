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

require 'bibtex'
require 'minitest'

module Cucumber
  module MiniTestAssertions
    def self.extended(base)
      base.extend(MiniTest::Assertions)
      base.assertions = 0
    end

    attr_accessor :assertions
  end
end

World(Cucumber::MiniTestAssertions)
