module BibTeX
  module Filters
    class LaTeX < Filter
      def apply (value)
        require 'latex/decode'
        LaTeX.decode(value)
      end
    end
  end
end