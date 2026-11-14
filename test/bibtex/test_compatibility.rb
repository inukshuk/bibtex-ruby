# frozen_string_literal: true

require 'helper'

module BibTeX
  class TestCompatibility < Minitest::Test
    def test_transliterate_ascii_is_unchanged
      assert_equal 'Poe, Edgar Allen', BibTeX.transliterate('Poe, Edgar Allen')
    end

    def test_transliterate_strips_diacritics
      assert_equal 'Muller', BibTeX.transliterate('Müller')
    end

    def test_transliterate_drops_characters_without_ascii_form
      assert_equal 'ab', BibTeX.transliterate('a中b')
    end

    def test_transliterate_falls_back_when_normalization_fails
      str = +'café ok'
      str.define_singleton_method(:unicode_normalize) { |*| raise ArgumentError, 'boom' }

      assert_equal 'caf ok', BibTeX.transliterate(str)
    end
  end
end
