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

  VERSION = '0.0.1'

  #
  # +Struct+ to model BibTeX +string+ objects.
  # The +Struct+ has two attributes: +key+ and +value+.
  # 
  String = Struct.new(:key,:value)

  #
  # +Struct+ to model BibTeX +comment+ objects.
  # The +Struct+ has a single attribute: +content+.
  #
  Comment = Struct.new(:content)

  #
  # +Struct+ to model BibTeX +preamble+ objects.
  # The +Struct+ has a single attribute: +content+.
  #
  Preamble = Struct.new(:content)
end

require 'bibtex/entry'
require 'bibtex/parser'
require 'bibtex/bibliography'
