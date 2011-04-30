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

  class Value
    extend Forwardable
    include Comparable
    
    attr_reader :value
    
    def_delegators :to_s, :<=>, :empty?, :=~, :match, :length, :intern, :to_sym, :to_i, :to_f, :end_with?, :start_with?, :include?, :upcase, :downcase, :reverse, :chop, :chomp, :rstrip, :gsub, :sub, :size, :strip, :succ, :to_c, :to_r, :to_str
    def_delegators :@value, :push
    
    def initialize(*arguments)
      @value = arguments.flatten
    end
    
    def initialize_copy(other)
      @value = other.value.dup
    end
    
    def replace(*arguments)
      return self unless variable?
      
      arguments.flatten.each do |argument|
        case argument
        when ::String
          @value = [argument]
        when String
          @value = @value.map { |v| argument[v] || v }
        when Hash
          @value = @value.map { |v| argument[v] || v }
        end
      end
      # if string @values = [string]
      # variables.each do |string, replacement|
      #   
      # end
      self
    end

    def join
      @value = @value.inject([]) do |a,b|
        a[-1].is_a?(::String) && b.is_a?(::String) ? a[-1] += b : a << b; a
      end
      self
    end
    
    def to_s(apply_join = false)
      join if apply_join
      atomic? ? @value[0].to_s : @value.map { |v|  v.is_a?(::String) ? v.inspect : v }.join(" # ")
    end

    def atomic?
      @value.length < 2
    end
    
    def name?
    end
    
    alias :is_name? :name?
    
    def numeric?
      to_s =~ /^\s*[+-]?\d+[\/\.]?\d*\s*$/
    end
    
    alias :is_numeric? :numeric?
    
    def variable?
      @value.detect { |v| v.is_a?(Symbol) }
    end
    
    alias :is_variable? :variable?
    
    def variables
      @value.select { |v| v.is_a?(Symbol) }
    end
    
  end
  
end