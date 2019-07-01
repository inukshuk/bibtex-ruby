begin
  require 'simplecov'
  require 'coveralls' if ENV['CI']
rescue LoadError
  # ignore
end

begin
  require 'debugger'
rescue LoadError
  # ignore
end

require 'minitest/unit'
require 'bibtex'

World(MiniTest::Assertions)
