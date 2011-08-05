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
    include Enumerable
    
    def_delegators :@tokens, :each, :sort
    
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
    
    def value
      @tokens.join(' and ')
    end
    
    def to_s(options = {})
      return value unless options.has_key?(:quotes)
      q = [options[:quotes]].flatten
      [q[0], value, q[-1]].compact.join
    end
    
    def name?; true; end
    def numeric?; false; end
    def atomic?; true; end
    
    alias :names? :name?
    alias :symbol? :numeric?
    
    def to_name; self; end
    
    def to_citeproc(options = {})
      map { |n| n.to_citeproc(options) }
    end
    
    def strip_braces
      gsub!(/\{|\}/,'')
    end
    
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
    
    def <=>(other)
      other.respond_to?(:to_a) ? to_a <=> other.to_a  : super
    end
    
  end

  class Name < Struct.new(:first, :last, :prefix, :suffix)
    extend Forwardable
    include Comparable
    
    def_delegators :to_s, :empty?, :=~, :casecmp, :match, :length, :intern, :to_sym, :end_with?, :start_with?, :include?, :upcase, :downcase, :reverse, :chop, :chomp, :rstrip, :gsub, :sub, :size, :strip, :succ, :to_str, :split, :each_byte, :each_char, :each_line
    
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
    
    alias display display_order
    
    def sort_order
      [[prefix,last].compact.join(' '), suffix, first].compact.join(', ')
    end
    
    alias to_s sort_order
    
    def <=>(other)
      other.is_a?(Name) ? [last, prefix, first, suffix].compact.join(' ') <=> [other.last, other.prefix, other.first, other.suffix].compact.join(' ') : super
    end
    
    def to_hash
      Hash[each_pair.to_a]
    end

    [:strip!, :upcase!, :downcase!, :sub!, :gsub!, :chop!, :chomp!, :rstrip!].each do |method_id|
      define_method(method_id) do |*arguments, &block|
        each do |part|
          part.send(method_id, *arguments, &block) unless part.nil?
        end
        self
      end
    end
    
    def to_citeproc(options = {})
      hash = {}
      hash['family'] = family unless family.nil?
      hash['given'] = given unless given.nil?
      hash['suffix'] = suffix unless suffix.nil?
      hash[options[:particle] || 'dropping-particle'] = prefix unless prefix.nil?
      hash
    end
    
    alias family last
    alias family= last=    
    alias given first
    alias given= first=
    alias jr suffix
    alias jr= suffix=
    alias von prefix
    alias von= prefix=    
    
  end
end