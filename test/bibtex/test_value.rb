# frozen_string_literal: true

require 'helper'

class Upcase < BibTeX::Filter
  def apply(value)
    value.is_a?(::String) ? value.upcase : value
  end
end

class SuffixA < BibTeX::Filter
  def apply(value)
    value.is_a?(::String) ? "#{value}a" : value
  end
end

module BibTeX
  class ValueTest < Minitest::Spec
    describe '::create' do
      it 'should return a duplicate when called with a Value subclass' do
        val   = Value.new('value')
        names = Names.new(Name.new(first: 'first_name'))

        assert_equal val.dup,   Value.create(val)
        assert_equal names.dup, Value.create(names)
      end

      it 'should return a new Value object when called with other arguments' do
        assert_equal Value.new('value'), Value.create('value')
      end
    end

    describe 'when empty' do
      it 'should be equal to an empty string' do
        assert_equal '', Value.new
        assert_equal '', Value.new('')
      end
      it 'should be empty' do
        assert_empty Value.new
        assert_empty Value.new('')
      end
      it 'should match an empty pattern' do
        assert_match(//, Value.new)
        assert_match(//, Value.new(''))
      end
    end

    describe '#join' do
      it 'should return empty string when empty' do
        assert_equal '', Value.new.join.to_s
        assert_equal '', Value.new('').join.to_s
      end
      it 'should return the string if atomic' do
        assert_equal 'foo', Value.new('foo').join.to_s
      end
      it 'should return a string concatenation of all strings when containing only strings' do
        assert_equal 'foobar', Value.new('foo', 'bar').join.to_s
        assert_equal 'foobar', Value.new(%w[foo bar]).join.to_s
      end
      it 'should should be atomic after join when containing only strings' do
        refute_predicate Value.new('foo', 'bar'), :atomic?
        assert_predicate Value.new('foo', 'bar').join, :atomic?
      end
      it 'should do nothing when containing only symbols' do
        value = Value.new(:foo)

        assert_equal value, value.join
        value = Value.new(:foo, :bar)

        assert_equal value, value.join
      end
      it 'should do nothing when containing only symbols and a single string' do
        value = Value.new(:foo, 'bar')

        assert_equal value, value.join
        value = Value.new('foo', :bar)

        assert_equal value, value.join
      end
    end

    describe '#replace' do
      it 'returns the receiver unchanged when it has no symbols' do
        value = Value.new('foo')

        assert_same value, value.replace(String.new(:foo, 'bar'))
        assert_equal 'foo', value.to_s
      end

      it 'returns the receiver itself when it has symbols' do
        value = Value.new(:foo)

        assert_same value, value.replace(String.new(:foo, 'bar'))
      end

      it 'replaces all tokens with a plain Ruby string' do
        assert_equal 'baz', Value.new(:foo, 'bar').replace('baz').to_s
      end

      it 'replaces a matching symbol with the value of a BibTeX string' do
        assert_equal 'bar', Value.new(:foo).replace(String.new(:foo, 'bar')).to_s
      end

      it 'splices the tokens of a multi-token BibTeX string in place' do
        string = String.new(:foo, Value.new('a', :b))

        assert_equal '"x" # "a" # b # "y"', Value.new('x', :foo, 'y').replace(string).to_s
      end

      it 'leaves non-matching symbols and strings alone' do
        assert_equal 'other # "bar"', Value.new(:other, 'bar').replace(String.new(:foo, 'x')).to_s
      end

      it 'replaces every occurrence of the symbol' do
        assert_equal '"x" # "x"', Value.new(:foo, :foo).replace(String.new(:foo, 'x')).to_s
      end

      it 'replaces symbols using a hash' do
        assert_equal '"1" # "2"', Value.new(:a, :b).replace(a: '1', b: '2').to_s
      end

      it 'keeps tokens without a hash entry' do
        assert_equal '"1" # b # "lit"', Value.new(:a, :b, 'lit').replace(a: '1').to_s
      end

      it 'accepts several arguments and applies them in order' do
        value = Value.new(:a, :b).replace(String.new(:a, 'x'), { b: 'y' })

        assert_equal '"x" # "y"', value.to_s
      end

      it 'flattens array arguments' do
        value = Value.new(:a, :b).replace([String.new(:a, 'x'), String.new(:b, 'y')])

        assert_equal '"x" # "y"', value.to_s
      end

      it 'ignores unsupported argument types' do
        value = Value.new(:a)

        assert_equal 'a', value.replace(42, nil).to_s
      end

      it 'does nothing when called without arguments' do
        assert_equal 'a', Value.new(:a).replace.to_s
      end

      it 'stops replacing once a plain string has removed all symbols' do
        assert_equal 'abc', Value.new(:a).replace('abc', String.new(:a, 'x')).to_s
      end
    end

    describe '#merge!' do
      it 'merges two strings by combining them' do
        assert_equal '"foo" # "bar"', Value.new('foo').merge!(Value.new('bar')).to_s
      end

      it 'does not duplicate existing tokens' do
        assert_equal 'foo', Value.new('foo').merge!(Value.new('foo')).to_s
      end
    end

    describe '#to_s' do
      it 'should return the string if atomic' do
        assert_equal 'foo bar', Value.new('foo bar').to_s
      end
      it 'should return the symbol as string when containing only a single symbol' do
        assert_equal 'foo', Value.new(:foo).to_s
      end
      it 'should return all string tokens concatenated by #' do
        assert_equal '"foo" # "bar"', Value.new('foo', 'bar').to_s
      end
      it 'should return all symbol tokens concatenated by #' do
        assert_equal 'foo # bar', Value.new(:foo, :bar).to_s
      end
      it 'should return all symbol and string tokens concatenated by #' do
        assert_equal 'foo # "bar"', Value.new(:foo, 'bar').to_s
        assert_equal '"foo" # bar', Value.new('foo', :bar).to_s
      end
    end

    describe 'conversions' do
      before do
        @values = [Value.new('foo'), Value.new('foo', :bar)]
      end

      describe '#convert' do
        it 'converts the value when given a filter instance' do
          assert_equal(['FOO', '"FOO" # bar'], @values.map { |v| v.convert(Upcase.instance).to_s })
        end

        it 'converts the value when given a filter class' do
          assert_equal(['FOO', '"FOO" # bar'], @values.map { |v| v.convert(Upcase).to_s })
        end

        it 'converts the value when given the name of a filter' do
          assert_equal(['FOO', '"FOO" # bar'], @values.map { |v| v.convert(:upcase).to_s })
          assert_equal(['FOO', '"FOO" # bar'], @values.map { |v| v.convert('upcase').to_s })
          assert_equal(['fooa', '"fooa" # bar'], @values.map { |v| v.convert('suffixa').to_s })
        end

        it 'applies multiple filters in the order passed' do
          _(@values.map { |v| v.convert(:upcase, :suffixa).to_s }).must_equal ['FOOa', '"FOOa" # bar']
          _(@values.map { |v| v.convert(:suffixa, :upcase).to_s }).must_equal ['FOOA', '"FOOA" # bar']
        end

        it 'converts the value when using a ghost method' do
          assert_equal(['FOO', '"FOO" # bar'], @values.map { |v| v.convert_upcase.to_s })
        end

        it 'does not alter the value when using a filter name' do
          @values.each { |v| v.convert(:upcase) }

          assert_equal ['foo', '"foo" # bar'], @values.map(&:to_s)
        end

        it 'does not alter the value when using a ghost method' do
          @values.each(&:convert_upcase)

          assert_equal ['foo', '"foo" # bar'], @values.map(&:to_s)
        end

        it 'raises argument error when a filter cannot be resolved' do
          assert_raises ArgumentError do
            @values[0].convert(:foo)
          end

          assert_raises ArgumentError do
            @values[0].convert(:upcase, :foo)
          end
        end
      end

      describe '#convert!' do
        it 'converts the value when given the name of a filter' do
          assert_equal(['FOO', '"FOO" # bar'], @values.map { |v| v.convert!(:upcase).to_s })
        end

        it 'alters the value when given the name of a filter' do
          @values.each { |v| v.convert!(:upcase) }

          assert_equal ['FOO', '"FOO" # bar'], @values.map(&:to_s)
        end

        it 'alters the value when using a ghost method' do
          @values.each(&:convert_upcase!)

          assert_equal ['FOO', '"FOO" # bar'], @values.map(&:to_s)
        end
      end

      describe 'value' do
        it 'returns numbers as strings' do
          assert_kind_of ::String, Value.new(42).v
          assert_kind_of ::String, Value.new(-42).v
          assert_kind_of ::String, Value.new('a42').v
        end
      end

      describe '#to_s' do
        it 'accepts a :filter option and convert the values accordingly without changing the value' do
          assert_equal '"FOO" # bar', @values[1].to_s(filter: :upcase)
          assert_equal '"foo" # bar', @values[1].to_s
        end
      end
    end
  end
end
