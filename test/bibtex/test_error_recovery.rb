# frozen_string_literal: true

require 'helper'

module BibTeX
  # How the parser recovers from broken input: which objects survive, which
  # become BibTeX::Error objects, and which inputs fail as a whole.
  class ErrorRecoveryTest < Minitest::Spec
    # errors.bib, split before each line that describes the next case.
    SECTIONS = File.read(Test.fixtures(:errors), encoding: 'utf-8').split(/\n(?=[A-Z][^\n]*:\n)/).freeze

    UNBALANCED = %i[AT STRING LBRACE NAME EQ STRING_LITERAL E_UNBALANCED].freeze
    UNTERMINATED = %i[AT STRING LBRACE NAME EQ STRING_LITERAL E_UNTERMINATED_STRING].freeze

    # The expected outcome for each section of errors.bib, in order.
    EXPECTED = [
      [],
      [['Error', UNBALANCED]],
      [['Error', UNBALANCED]],
      [['Error', UNTERMINATED]],
      [['String', :foo]],
      [['Error', %i[AT PREAMBLE LBRACE STRING_LITERAL E_UNTERMINATED_STRING]]],
      [['Preamble']],
      ParseError,
      [['Error', %i[AT NAME LBRACE KEY NAME EQ STRING_LITERAL NAME NAME STRING_LITERAL E_UNBALANCED]]],
      [['Entry', :book, 'key', %i[author title]]],
      ParseError,
      [['String', :bar]]
    ].freeze

    OPTIONS = [{}, { strict: false }].freeze

    def summary(bib)
      bib.map do |element|
        name = element.class.name.split('::').last
        case element
        when Entry then [name, element.type, element.key, element.fields.keys]
        when BibTeX::String then [name, element.key]
        when BibTeX::Error then [name, element.trace.map(&:first)]
        else [name]
        end
      end
    end

    before { BibTeX.log.level = Logger::FATAL }
    after { BibTeX.log.level = Logger::WARN }

    it 'splits errors.bib into one section per case' do
      assert_equal EXPECTED.length, SECTIONS.length
    end

    OPTIONS.each do |options|
      describe "with #{options.inspect}" do
        EXPECTED.each_with_index do |result, index|
          it "parses section #{index} of errors.bib (#{SECTIONS[index].lines.first.strip})" do
            if result == ParseError
              assert_raises(ParseError) { BibTeX.parse(SECTIONS[index], options) }
            else
              assert_equal result, summary(BibTeX.parse(SECTIONS[index], options))
            end
          end
        end

        it 'fails on errors.bib as a whole' do
          error = assert_raises(ParseError) { BibTeX.open(Test.fixtures(:errors), options) }

          assert_match(/\AFailed to parse BibTeX on value "\$end" \(\$end\) \[#<BibTeX::Bibliography data=\[2\]>, "@", "string", "\{", \[:foo, /,
                       error.message)
        end

        it 'rejects an entry without a comma after the key or between fields' do
          assert_raises(ParseError) { BibTeX.parse("@book{key\n\tauthor = \"An Author\"\n}", options) }
          assert_raises(ParseError) { BibTeX.parse("@book{key,\n\tauthor = \"An Author\"\n\ttitle = \"The Title\"\n}", options) }
        end

        it 'reports a braced value that is never closed as an unterminated-content error' do
          assert_equal [['Error', %i[AT NAME LBRACE KEY NAME EQ LBRACE CONTENT E_UNTERMINATED_CONTENT]]],
                       summary(BibTeX.parse('@book{a, title = {x', options))
        end
      end
    end

    it 'rejects an entry without key unless allow_missing_keys is set' do
      input = "@book{\n\tauthor = \"An Author\"\n}"

      assert_raises(ParseError) { BibTeX.parse(input) }
      assert_raises(ParseError) { BibTeX.parse(input, strict: false) }
      assert_equal [['Entry', :book, 'an-a', [:author]]], summary(BibTeX.parse(input, allow_missing_keys: true))
    end

    it 'finds an indented entry after free text in non-strict mode' do
      assert_equal [['Entry', :book, 'a', [:title]]],
                   summary(BibTeX.parse("text\n  @book{a, title = {x}}", strict: false))
    end
  end
end
