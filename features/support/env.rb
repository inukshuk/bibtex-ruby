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

require 'minitest/unit'
require 'bibtex'

World(MiniTest::Assertions)
