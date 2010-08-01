#
# = BibTeX
#
# This module encompasses a parser for BibTeX files and
# auxiliary classes and structs to model the individual
# BibTeX objects: +String+, +Preamble+, +Comment+, and
# +Entry+.
#
# Author:: {Sylvester Keil}[http://sylvester.keil.or.at]
# Copyright:: Copyright (c) 2010 Sylvester Keil
# License:: GNU GPL 3.0
#
module BibTeX
  require 'logger'

  # The current library version.
  VERSION = '1.0.1'

  #
  # An instance of the Ruby core class +Logger+.
  # Used for logging by BibTeX-Ruby.
  #
  Log = Logger.new(STDERR)
  Log.level = Logger::DEBUG
  Log.datetime_format = "%Y-%m-%d %H:%M:%S"

end

require 'bibtex/elements'
require 'bibtex/entry'
require 'bibtex/parser'
require 'bibtex/bibliography'
