module BibTeX
  module Filters
    # Replaces line breaks (and the whitespace that follows) with a single space.
    class LineBreaks < Filter
      def apply(value)
        value.to_s.gsub(/\n\s*/, ' ')
      end
    end
  end
end
