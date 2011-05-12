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

  class Names < Value
    
    def self.parse(string)
      Names.new(NameParser.new.parse(string))
    end
    
    def initialize(*arguments)
      @tokens = []
      arguments.flatten.compact.each do |argument|
        add(argument)
      end
    end

    def replace(*arguments); self; end
    
    def join; self; end
    
    def to_s
      @tokens.join(' and ')
    end
    
    alias :value :to_s
    
    def name?; true; end
    def numeric?; false; end
    
    alias :names? :name?
    alias :symbol? :numeric?
    
    def add(name)
      case
      when name.is_a?(Name)
        @tokens << name
      when name.respond_to?(:to_s)
        @tokens += Names.parse(name.to_s)
      else
        raise ArgumentError, "failed to add #{name.inspect}: not a name."
      end
      self
    end
    
    alias :<< :add
    alias :push :add
    
  end

  class Name < Struct.new(:first, :last, :prefix, :suffix)
    extend Forwardable
    include Comparable
    
    def_delegators :to_s, :empty?, :=~, :match, :length, :intern, :to_sym, :end_with?, :start_with?, :include?, :upcase, :downcase, :reverse, :chop, :chomp, :rstrip, :gsub, :sub, :size, :strip, :succ, :to_str
    
    class << self    
      def parse(string)
        [NameParser.new.parse(string)].flatten[0]
      end
      
      # Returns true if thing looks like a name.
      # Actually converts thing to a string and tries to parse it.
      def looks_like?(thing)
        thing.respond_to?(:to_s) && [Name.new.parse(string)].flatten.compact.empty?
      end
    end
    
    def initialize(attributes = {})
      attributes.each do |key,value|
        send("#{key}=", value) if respond_to?(key)
      end
    end
    
    def initalize_copy(other)
      each_pair { |k,v| self[k] = v }
    end
    
    def blank?
      to_a.compact.empty?
    end
    
    def display_order
      [prefix, last, first, suffix].compact.join(' ')
    end
        
    def sort_order
      [[prefix,last].compact.join(' '), suffix, first].compact.join(', ')
    end
    
    alias :to_s :sort_order
    
    def <=>(other)
      to_s <=> other.to_s
    end

    def ===(other)
      to_s === other.to_s
    end
    
    def to_hash
      Hash[each_pair.to_a]
    end

    [:strip!, :upcase!, :downcase!, :sub!, :gsub!, :chop!, :chomp!, :rstrip!].each do |method_id|
      define_method(method_id) do |*arguments, &block|
        each do |part|
          part.send(method_id, *arguments, &block)
        end
      end
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