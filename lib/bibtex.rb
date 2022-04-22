require 'digest/md5'
require 'forwardable'
require 'logger'
require 'open-uri'

require 'json'

require 'bibtex/version'

# = BibTeX
#
# This module encompasses a parser for BibTeX files and
# an API to the individual BibTeX objects: +String+,
# +Preamble+, +Comment+, and +Entry+.
#
# Copyright:: Copyright (c) 2010-2022 The BibTeX-Ruby Contributors
# License:: GNU GPL 3.0 and BSD-2-Clause
#
module BibTeX
  #
  # An instance of the Ruby core class +Logger+.
  # Used for logging by BibTeX-Ruby.
  #
  @log = Logger.new(STDERR)
  @log.level = ENV.key?('DEBUG') ? Logger::DEBUG : Logger::WARN
  @log.datetime_format = '%Y-%m-%d %H:%M:%S'

  class << self
    attr_accessor :log
  end
end

# Load debugger
# require 'ruby-debug'
# Debugger.start

require 'bibtex/extensions'

require 'bibtex/value'
require 'bibtex/filters'
require 'bibtex/name_parser'

require 'bibtex/compatibility'

require 'bibtex/names'
require 'bibtex/replaceable'
require 'bibtex/elements'
require 'bibtex/entry'
require 'bibtex/entry/citeproc_converter'
require 'bibtex/error'
require 'bibtex/parser'
require 'bibtex/bibliography'
require 'bibtex/utilities'

begin
  require 'bibtex/entry/bibtexml_converter'
rescue LoadError
  # ignored
end

begin
  require 'rdf'
  require 'bibtex/entry/rdf_converter'
  require 'bibtex/bibliography/rdf_converter'
rescue LoadError
  # ignored
end
