# -*- coding: utf-8 -*-

#--
# BibTeX-Ruby
# Copyright (C) 2010-2012  Sylvester Keil <sylvester.keil.or.at>
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

  class Symbol < ::String
    alias_method :inspect, :to_s
  end

  #
  # A BibTeX Value is something very much like a string. In BibTeX files it
  # can appear on the right hand side of @string or @entry field assignments
  # or as @preamble contents. In the example below [VALUE] indicates possible
  # occurences of values in BibTeX:
  #
  #     @preamble{ "foo" [VALUE] }
  #     @string{ foo = "foo" [VALUE] }
  #     @book{id,
  #       author = {John Doe} [VALUE],
  #       title = foo # "bar" [VALUE]
  #     }
  #
  # All Values have in common that they can be simple strings in curly braces
  # or double quotes or complex BibTeX string-concatenations (using the '#'
  # symbol).
  #
  # Generally, Values try to behave as much as normal Ruby strings as possible;
  # If you do not require any of the advanced BibTeX functionality (string
  # replacement or concatentaion) you can simply convert them to strings using
  # +to_s+. Note that BibTeX Names are special instances of Values which
  # currently do not support string concatenation or replacement.
  #
  class Value
    extend Forwardable
    include Comparable

    attr_reader :tokens
    alias_method :to_a, :tokens

    def_delegators :to_s, :=~, :===, *String.instance_methods(false).reject { |m| m =~ /^\W|^length$|^dup$|!$/ }
    def_delegators :@tokens, :[], :length
    def_delegator :@tokens, :each, :each_token

    # call-seq:
    #   create(other) => other.dup
    #   create(*args) => Value.new(args)
    #
    # Duplicates a +Value+ object (or an object of any subclass of +Value+),
    # or initializes a new one.
    def self.create(*args)
      args[0].class < Value && args.size == 1 ? args[0].dup : Value.new(args)
    end

    def initialize(*arguments)
      @tokens = []
      arguments.flatten.compact.each do |argument|
        add(argument)
      end
    end

    def initialize_copy(other)
      @tokens = other.tokens.dup
    end

    def merge(other)
      dup.merge!(other)
    end

    def merge!(other)
      other.tokens.each do |token|
        add token unless include_token?(token)
      end

      self
    end

    def include_token?(token)
      tokens.include?(token)
    end

    def add(argument)
      case argument
      when Value
        @tokens += argument.tokens.dup
      when ::Symbol
        @tokens << Symbol.new(argument.to_s)
      when ::String, Symbol
        @tokens << argument
      else
        @tokens << argument.to_s
      end
      self
    end

    alias_method :<<, :add
    alias_method :push, :add

    [:strip!, :upcase!, :downcase!, :sub!, :gsub!, :chop!, :chomp!, :rstrip!].each do |method_id|
      define_method(method_id) do |*arguments, &block|
        tokens.each do |part|
          part.send(method_id, *arguments, &block) unless part.nil?
        end
        self
      end
    end

    def replace(*arguments)
      return self unless has_symbol?
      arguments.flatten.each do |argument|
        case argument
        when ::String # simulates Ruby's String#replace
          @tokens = [argument]
        when String
          @tokens = @tokens.map { |v| argument.key == v.to_s ? argument.value.tokens : v }.flatten
        when Hash
          @tokens = @tokens.map { |v| argument[v] || v }
        end
      end
      self
    end


    # call-seq:
    #   Value.new('foo', 'bar').join #=> <'foobar'>
    #   Value.new(:foo, 'bar').join  #=> <:foo, 'bar'>
    #
    # @param {String} separator
    #
    # @return {Value} the instance with all consecutive String tokens joined
    def join(separator = '')
      @tokens = @tokens.inject([]) do |a,b|
        if a[-1].is_a?(::String) && b.is_a?(::String)
          a[-1] = [a[-1], b].join(separator)
        else
          a << b
        end
        a
      end
      self
    end

    # call-seq:
    #   Value.new('foo').to_s                       #=> "foo"
    #   Value.new(:foo).to_s                        #=> "foo"
    #   Value.new('foo').to_s(:quotes => '"')       #=> "\"foo\""
    #   Value.new('foo').to_s(:quotes => ['"','"']) #=> "\"foo\""
    #   Value.new('foo').to_s(:quotes => ['{','}']) #=> "{foo}"
    #   Value.new(:foo, 'bar').to_s                 #=> "foo # \"bar\""
    #   Value.new('foo', 'bar').to_s                #=> "\"foo\" # \"bar\""
    #   Value.new('\"u').to_s(:filter => :latex)    #=> "ü"
    #
    # Returns a the Value as a string. @see #value; the only difference is
    # that single symbols are returned as String, too.
    # If the Value is atomic and the option :quotes is given, the string
    # will be quoted using the quote symbols specified.
    #
    # If the option :filter is given, the Value will be converted using
    # the filter(s) specified.
    def to_s(options = {})
      return convert(options.delete(:filter)).to_s(options) if options.has_key?(:filter)
      return value.to_s unless options.has_key?(:quotes) && atomic?
      q = [options[:quotes]].flatten
      [q[0], value, q[-1]].compact.join
    end

    # Returns the Value as a string or, if it consists of a single symbol, as
    # a Symbol instance. If the Value contains multiple tokens, they will be
    # joined by a '#', additionally, all string tokens will be turned into
    # string literals (i.e., delimitted by quotes).
    def value
      atomic? ? @tokens[0] : @tokens.map(&:inspect).join(' # ')
    end

    alias_method :v, :value

    def inspect
      "#<#{self.class} #{tokens.map(&:inspect).join(', ')}>"
    end

    # Returns true if the Value is empty or consists of a single token.
    def atomic?
      @tokens.length < 2
    end

    # Returns true if the value is a BibTeX name value.
    def name?; false; end

    alias_method :names?, :name?

    def to_name
      Names.parse(to_s)
    end

    alias_method :to_names, :to_name

    # Returns true if the Value's content is a date.
    def date?
      !to_date.nil?
    end

    # Returns the string as a date.
    def to_date
      require 'date'
      Date.parse(to_s)
    rescue
      nil
    end

    # Returns true if the Value's content is numeric.
    def numeric?
      to_s =~ /^\s*[+-]?\d+[\/\.]?\d*\s*$/
    end

    def to_citeproc (options = {})
      to_s(options)
    end

    # Returns true if the Value contains at least one symbol.
    def symbol?
      tokens.detect { |v| v.is_a?(Symbol) }
    end
    alias_method :has_symbol?, :symbol?

    # Returns all symbols contained in the Value.
    def symbols
      tokens.select { |v| v.is_a?(Symbol) }
    end

    # Returns a new Value with all string values converted according to the given filter(s).
    def convert (*filters)
      dup.convert!(*filters)
    end

    # Converts all string values according to the given filter(s).
    def convert! (*filters)
      filters.flatten.each do |filter|
        f = Filters.resolve!(filter)
        tokens.map! { |t| f.apply(t) }
      end

      self
    end

    def method_missing (name, *args)
      case
      when name.to_s =~ /^(?:convert|from)_([a-z]+)(!)?$/
        $2 ? convert!($1) : convert($1)
      else
        super
      end
    end

    def respond_to? (method)
      method =~ /^(?:convert|from)_([a-z]+)(!)?$/ || super
    end

    def <=> (other)
      to_s <=> other.to_s
    end

  end

end
