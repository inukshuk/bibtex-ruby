$LOAD_PATH << File.expand_path('../../../lib', __FILE__)
require 'bibtex'
require 'minitest/unit'

World do
  include MiniTest::Assertions
end