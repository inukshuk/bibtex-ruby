#--
# BibTeX-Ruby
# Copyright (C) 2011  Sylvester Keil <sylvester.keil.or.at>
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

  class << self
    # Opens a BibTeX file and returns a corresponding +Bibliography+ object.
    def open(file, options = {})
      Bibliography.open(file, options)
    end
  
    # Parses the given string and returns a corresponding +Bibliography+ object.
    def parse(string, options = {})
      BibTeX::Parser.new(options).parse(string)
    end
  
    # Returns true if the given file is a valid BibTeX bibliography.
    def valid?(file)
      Bibliography.open(file).valid?
    end
  end

end