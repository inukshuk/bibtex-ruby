#--
# BibTeX-Ruby
# Copyright (C) 2010-2011  Sylvester Keil <sylvester.keil.or.at>
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

require 'forwardable'

module BibTeX

  class Name
    extend Forwardable
    include Comparable
    
    attr_accessor :first, :last, :prefix, :suffix
    
    def_delegators :to_s, :empty?, :=~, :match, :length, :intern, :to_sym, :end_with?, :start_with?, :include?, :upcase, :downcase, :reverse, :chop, :chomp, :rstrip, :gsub, :sub, :size, :strip, :succ, :to_str
    
    PATTERNS = {
      :sort => /^(?:((?:[[:alpha:]\s])*[[:lower:]][[:alpha:]])\s)*([[:alpha:]]+),(?:\s*([^,]*?)\s*,)?\s*([[:alpha:]\s]+)?$/,
      :display => /^((?:(?:[\d\\\{\}]*[[:upper:]][[:alnum:]\\\{\}]*)\s)*)?(?:([\d\\\{\}]*[[:lower:]][[:alnum:]\\\{\}\s]*)\s)?(.+)$/      
    }.freeze
    
    def self.parse(string)
      NameParser.new.parse(string)[0]
      # case string = string.strip
      # when PATTERNS[:sort]
      #   new(:prefix => $1, :last => $2, :suffix => $3, :first => $4)
      # when PATTERNS[:display]
      #   new(:first => $1 && $1.strip, :prefix => $2, :last => $3)
      # else
      #   new(:last => string)
      # end
    end
    
    def initialize(attributes = {})
      attributes.each do |key,value|
        send("#{key}=", value) if respond_to?(key)
      end
    end
    
    def blank?
      [prefix, first, last, suffix].join.empty?
    end
    
    def to_s
      [[prefix,last].compact.join(' '), suffix, first].compact.join(', ')
    end
    
    def <=>(other)
      to_s <=> other.to_s
    end
    
    def to_hash
      { :first => first, :last => last, :prefix => prefix, :suffix => suffix }
    end
    
    def to_citeproc
      {
        'family' => [prefix, last].compact.join(' '),
        'given' =>  [first, suffix].compact.join(', '),
        'parse-names' => true
      }
    end
    
    alias :family :last
    alias :family= :last=    
    alias :given :first
    alias :given= :first=
    alias :jr :suffix
    alias :jr= :suffix=
    alias :von :prefix
    alias :von= :prefix=    
    
  end
end