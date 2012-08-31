#--
# BibTeX-Ruby
# Copyright (C) 2010-2011	Sylvester Keil <sylvester.keil.or.at>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.	If not, see <http://www.gnu.org/licenses/>.
#++

require 'digest/md5'
require 'forwardable'
require 'logger'
require 'open-uri'

require 'multi_json'

require 'bibtex/version'

# = BibTeX
#
# This module encompasses a parser for BibTeX files and
# an API to the individual BibTeX objects: +String+,
# +Preamble+, +Comment+, and +Entry+.
#
# Author:: {Sylvester Keil}[http://sylvester.keil.or.at]
# Copyright:: Copyright (c) 2010-2011 Sylvester Keil
# License:: GNU GPL 3.0
#
module BibTeX

	#
	# An instance of the Ruby core class +Logger+.
	# Used for logging by BibTeX-Ruby.
	#
	@log = Logger.new(STDERR)
	@log.level = ENV.has_key?('DEBUG') ? Logger::DEBUG : Logger::WARN
	@log.datetime_format = '%Y-%m-%d %H:%M:%S'

  class << self
    attr_reader :log
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
require 'bibtex/error'
require 'bibtex/parser'
require 'bibtex/bibliography'
require 'bibtex/utilities'