# frozen_string_literal: true

require 'helper'

module BibTeX
  class ReplaceableTest < Minitest::Spec
    describe 'a Preamble including Replaceable' do
      before do
        @bib = BibTeX.parse('@string{ foo = "foo" } @preamble{ foo # "bar" }')
        @preamble = @bib.q('@preamble').first
      end

      it 'wraps assigned values in a Value' do
        @preamble.value = 'baz'

        assert_instance_of Value, @preamble.value
        assert_equal 'baz', @preamble.value.to_s
      end

      it 'appends to the value and returns self' do
        assert_same @preamble, (@preamble << ' more')
        assert_equal 'foo # "bar" # " more"', @preamble.value.to_s(quotes: '"')
      end

      it 'replaces symbols and returns self' do
        assert_same @preamble, @preamble.replace(foo: 'foo')
        refute_predicate @preamble.value, :symbol?
      end

      it 'joins adjacent strings and returns self' do
        @preamble.replace(foo: 'foo')

        assert_same @preamble, @preamble.join
        assert_equal 'foobar', @preamble.value.to_s
      end
    end
  end
end
