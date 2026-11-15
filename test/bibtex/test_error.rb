# frozen_string_literal: true

require 'helper'

module BibTeX
  class ErrorTest < Minitest::Spec
    before { BibTeX.log.level = Logger::FATAL }
    after { BibTeX.log.level = Logger::WARN }

    describe 'when parsing broken input without strict mode' do
      before do
        @bib = BibTeX.parse('@book{key, title = "Unterminated}', strict: false)
        @error = @bib.find { |e| e.is_a?(Error) }
      end

      it 'registers the error with the bibliography' do
        refute_nil @error
        assert_same @bib, @error.bibliography
        assert_includes @bib.errors, @error
        assert_predicate @bib, :errors?
      end

      it 'builds its content from the token trace' do
        assert_kind_of Array, @error.trace
        assert_equal @error.trace.map { |t| t[1] }.join, @error.content
      end

      it 'is removed from the bibliography errors when deleted' do
        @bib.delete(@error)

        refute_includes @bib.errors, @error
        refute_predicate @bib, :errors?
        assert_nil @error.bibliography
      end
    end

    describe 'when created directly' do
      it 'defaults to an empty trace' do
        assert_empty Error.new.trace
        assert_equal '', Error.new.content
      end

      it 'accepts a trace' do
        error = Error.new([[:NAME, 'foo'], [:EQ, '=']])

        assert_equal 'foo=', error.content
      end

      it 'replaces the trace with an array' do
        error = Error.new
        error.trace = [[:NAME, 'bar']]

        assert_equal 'bar', error.content
      end

      it 'rejects a trace which is not an array' do
        error = Error.new

        assert_raises(BibTeX::ArgumentError) { error.trace = 'nope' }
        assert_empty error.trace
      end
    end

    describe 'when added to and removed from a bibliography by hand' do
      it 'tracks itself in the bibliography errors' do
        bib = Bibliography.new
        error = Error.new([[:NAME, 'x']])

        bib << error

        assert_equal [error], bib.errors

        bib.delete(error)

        assert_empty bib.errors
      end
    end
  end
end
