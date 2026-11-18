# frozen_string_literal: true

module BibTeX
  #
  # The Replaceable module provides methods that expose a Value attribute
  # and the ability to join or replace the contained BibTeX symbols.
  #
  module Replaceable
    extend Forwardable

    attr_reader :value

    def value=(value)
      @value = Value.new(value)
    end

    def replace(*)
      @value.replace(*)
      self
    end

    def join
      @value.join
      self
    end

    def <<(value)
      @value << value
      self
    end

    alias v value
  end
end
