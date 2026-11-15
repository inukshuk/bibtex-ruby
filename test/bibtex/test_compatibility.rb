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
      binary = 'café ok'.b

      assert_equal 'caf ok', BibTeX.transliterate(binary)
    end
  end
end
