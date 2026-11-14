require 'latex/decode'

module BibTeX
  module Filters
    # Decodes LaTeX markup (e.g. accents and special characters) to Unicode.
    class LaTeX < Filter
      def apply(value)
        ::LaTeX.decode(value)
      end
    end
  end
end
