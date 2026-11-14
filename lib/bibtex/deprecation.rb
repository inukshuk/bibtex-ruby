# frozen_string_literal: true

module BibTeX
  # Emits BibTeX-Ruby's deprecation warnings.
  #
  # Warnings use Ruby's +:deprecated+ category, so they are only shown when
  # deprecation warnings are enabled (e.g. via <tt>Warning[:deprecated] = true</tt>
  # or <tt>ruby -W:deprecated</tt>), and each one is shown at most once per process.
  #
  # @api private
  module Deprecation
    SELECTOR_MESSAGE = 'BibTeX-Ruby string selectors such as "@book[year=2009]" are deprecated; ' \
                       'use a Hash of conditions (bib.query(type: :book, year: "2009")) ' \
                       'or pattern matching instead'

    LIBRARY_PATH = File.expand_path('..', __dir__)

    @warned = {}

    class << self
      # Warns once that the string selector language is deprecated,
      # pointing at the first caller outside of BibTeX-Ruby.
      def selector_warning
        warn_once(:selector, SELECTOR_MESSAGE)
      end

      # Forgets which warnings were already shown.
      def reset!
        @warned.clear
      end

      # Marks the selector warning as already shown, so it stays silent.
      def silence!
        @warned[:selector] = true
      end

      private

      def warn_once(id, message)
        return if @warned[id] || !Warning[:deprecated]

        @warned[id] = true
        Kernel.warn(message, category: :deprecated, uplevel: caller_uplevel)
      end

      # The number of frames between Kernel#warn's caller (this module) and
      # the first frame outside of the library.
      def caller_uplevel
        locations = caller_locations(1) || []
        index = locations.index { |location| !location.absolute_path.to_s.start_with?(LIBRARY_PATH) }
        index.nil? ? 0 : index
      end
    end
  end
end
