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

  # This module contains functions to manipulate BibTeX string literals.
  # It is intended to be injected in an Array that represents either the
  # content of a BibTeX @string or an rvalue of a field in a BibTeX entry.
	module Extensions
		
		def self.string_replacement(obj)
		  raise(ArgumentError, "StringReplacement should only be injected into instances of Array, not #{obj.class}.") unless obj.is_a?(::Array)
		  class << obj; include ::BibTeX::Extensions::StringReplacement end
		  obj
		end
		
		module StringReplacement
      # Returns a string representation of the literal.
      def to_s(options = {})
        return '' if self.empty?
        
        options[:quotes] ||= [nil,nil]
        
        if self.length == 1 && !self[0].is_a?(::Symbol)
          [options[:quotes][0], self[0], options[:quotes][1]].join
        else
          self.map { |s| s.is_a?(::Symbol) ? s.to_s : %Q("#{ s }") }.join(' # ')
        end
      end

      # Replaces all string constants which are defined in +hash+.
      def replace_strings(hash)
        Extensions.string_replacement(self.map { |s| s.is_a?(::Symbol) && hash.has_key?(s) ? hash[s] : s }.flatten)
      end
      
      # Joins consecutive strings separated by '#'.
      def join_strings
        Extensions.string_replacement(self.inject([]) { |a,b|
          a << (a.last.is_a?(::String) && b.is_a?(::String) ? (a.pop + b) : b )         
        })
      end
    end
	end
	
end