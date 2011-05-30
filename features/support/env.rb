$LOAD_PATH << File.expand_path('../../../lib', __FILE__)

require 'rubygems'
require 'bundler/setup'

require 'bibtex'
require 'minitest/unit'

World do
  extend MiniTest::Assertions
end