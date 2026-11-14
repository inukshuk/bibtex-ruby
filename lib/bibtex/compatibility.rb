# frozen_string_literal: true

module BibTeX
  def self.transliterate(str)
    str
      .unicode_normalize(:nfkd)
      .encode(Encoding::ASCII, invalid: :replace, undef: :replace, replace: '')
  rescue StandardError
    str.gsub(/[^\x20-\x7E]/, '')
  end
end
