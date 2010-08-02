#--
# BibTeX-Ruby
# Copyright (C) 2010  Sylvester Keil <sylvester.keil.or.at>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

module BibTeX

  #
  # The Bibliography class models a BibTeX bibliography;
  # typically, it corresponds to a `.bib' file.
  #
  class Bibliography

    attr_accessor :path
    attr_reader :data

    def initialize(data=[])
      raise(ArgumentError, "BibTeX data must be of type Array, was: #{data.class}") unless data.kind_of? Array
      @path = ''
      @data = data
    end

    def open
      @data = BibTeX::Parser.new.parse(File.open(path).read)
    end

    def strings
      find_by_type(BibTeX::String)
    end

    def apply_strings
    end

    def empty?
      @data.empty?
    end

    private

    def find_by_type(type)
      @data.find_all { |x| x.kind_of? type }
    end
  end
end
