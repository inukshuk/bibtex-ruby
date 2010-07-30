#
# This module encompasses a parser for BibTeX files and
# auxiliary classes and structs to model the serparate
# BibTeX objects.
#
# Author:: Sylvester Keil (http://sylvester.keil.or.at)
# Copyright:: Copyright (c) 2010 Sylvester Keil
# License:: GNU GPL 3.0
#
module BibTeX

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

require 'lib/bibtex/entry'
require 'lib/bibtex/parser'
