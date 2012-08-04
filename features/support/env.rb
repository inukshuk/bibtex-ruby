begin
  require 'simplecov'
  require 'debugger'
rescue LoadError
  # ignore
end

require 'bibtex'
require 'minitest/unit'

World do
  extend MiniTest::Assertions
end