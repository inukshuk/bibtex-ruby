# frozen_string_literal: true

require 'helper'
require 'json'

module BibTeX
  # R2 (REQUIREMENTS.md) guard: widening the identifier characters must not
  # change how the fixtures in test/fixtures are lexed or parsed.
  #
  # test/fixtures/lexer_tokens.json was recorded from the lexer as it was
  # before R2 was implemented. It holds the full token stream (Array#inspect
  # of every token) for each fixture and for each section of errors.bib, for
  # every lexer configuration listed in VARIANTS. Do not regenerate it to make
  # a failing test pass: a difference means the lexer behaves differently.
  class FixtureLexingTest < Minitest::Spec
    SNAPSHOT = JSON.parse(File.read(File.expand_path('../fixtures/lexer_tokens.json', __dir__), encoding: 'utf-8'))

    META = %i[errors meta_content].freeze

    VARIANTS = {
      'default' => {},
      'meta_content' => { include: META },
      'non-strict' => { strict: false, include: META },
      'strip_comments' => { strip_comments: true, include: META },
      'non-strict strip_comments' => { strict: false, strip_comments: true, include: META },
      'allow_missing_keys' => { allow_missing_keys: true, include: META }
    }.freeze

    PARSE_OPTIONS = [{}, { strict: false }, { strip_comments: true }, { strict: false, strip_comments: true },
                     { allow_missing_keys: true }].freeze

    # errors.bib, split before each line that describes the next case.
    ERROR_SECTIONS = File.read(Test.fixtures(:errors), encoding: 'utf-8').split(/\n(?=[A-Z][^\n]*:\n)/).freeze

    def self.inputs
      inputs = Dir[File.expand_path('../fixtures/*.bib', __dir__)].to_h do |path|
        [File.basename(path), File.read(path, encoding: 'utf-8')]
      end
      ERROR_SECTIONS.each_with_index { |section, index| inputs["errors.bib section #{index}"] = section }
      inputs
    end

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

    describe 'R2 guard: fixtures are lexed and parsed exactly as before' do
      before { BibTeX.log.level = Logger::FATAL }
      after { BibTeX.log.level = Logger::WARN }

      it 'has a recorded token stream for every fixture and errors.bib section' do
        assert_equal FixtureLexingTest.inputs.keys.sort, SNAPSHOT.keys.sort
        assert_equal 12, ERROR_SECTIONS.length
      end

      inputs.each do |name, source|
        VARIANTS.each do |variant, options|
          it "lexes #{name} (#{variant}) into the recorded tokens" do
            expected = SNAPSHOT.fetch(name).fetch(variant)

            assert_equal expected, Lexer.new(options).analyse(source).stack.map(&:inspect)
          end
        end
      end

      describe 'parsed fixtures' do
        PARSE_OPTIONS.each do |options|
          describe "with #{options.inspect}" do
            it 'parses bibdesk.bib' do
              bib = BibTeX.open(Test.fixtures(:bibdesk), options)

              assert_equal %w[rails dragon pickaxe], bib.entries.keys
              assert_empty bib.errors
              assert_equal %i[address author booktitle date-added date-modified edition isbn keywords publisher series title year],
                           bib['rails'].fields.keys
            end

            it 'parses entry.bib' do
              bib = BibTeX.open(Test.fixtures(:entry), options)

              assert_equal [['Entry', :book, 'key:0', %i[author title publisher year]],
                            ['Entry', :article, 'key:1', %i[author title publisher year]],
                            ['Entry', :article, 'foo', []],
                            ['Entry', :commentary, 'staudinger', [:editor]]], summary(bib)
            end

            it 'parses decoret.bib' do
              bib = BibTeX.open(Test.fixtures(:decoret), options)

              assert_equal 15, bib.length
              assert_equal %w[py03 key03 key01 key02 steward03 sweig42], bib.entries.keys
              assert_equal %i[mar firstname lastname email maintainer], bib.strings.keys
              assert_equal({ 'Entry' => 6, 'Comment' => 2, 'String' => 5, 'Preamble' => 2 },
                           bib.map { |e| e.class.name.split('::').last }.tally)
              assert_empty bib.errors
            end

            it 'parses preamble.bib' do
              bib = BibTeX.open(Test.fixtures(:preamble), options)

              assert_equal [['Preamble'], ['Preamble'], ['String', :maintainer], ['Preamble']], summary(bib)
            end

            it 'parses comment.bib' do
              bib = BibTeX.open(Test.fixtures(:comment), options.merge(include: [:meta_content]))

              assert_equal [['MetaContent'], ['Comment'], ['MetaContent'], ['Comment'], ['MetaContent']], summary(bib)
            end

            it 'parses roundtrip.bib' do
              bib = BibTeX.open(Test.fixtures(:roundtrip), options)

              assert_equal [['Entry', :book, 'rails', %i[address author booktitle edition keywords publisher series title year]]],
                           summary(bib)
            end

            it 'parses empty.bib and no_bibtex.bib to empty bibliographies' do
              assert_empty BibTeX.open(Test.fixtures(:empty), options)
              assert_empty BibTeX.open(Test.fixtures(:no_bibtex), options)
              assert_equal [['MetaContent']], summary(BibTeX.open(Test.fixtures(:no_bibtex), options.merge(include: [:meta_content])))
            end

            it 'fails on errors.bib as a whole with the same ParseError' do
              error = assert_raises(ParseError) { BibTeX.open(Test.fixtures(:errors), options) }

              assert_match(/\AFailed to parse BibTeX on value "\$end" \(\$end\) \[#<BibTeX::Bibliography data=\[2\]>, "@", "string", "\{", \[:foo, /,
                           error.message)
            end
          end
        end
      end

      describe 'errors.bib error recovery, section by section' do
        unbalanced = %i[AT STRING LBRACE NAME EQ STRING_LITERAL E_UNBALANCED]
        unterminated = %i[AT STRING LBRACE NAME EQ STRING_LITERAL E_UNTERMINATED_STRING]

        expected = [
          [],
          [['Error', unbalanced]],
          [['Error', unbalanced]],
          [['Error', unterminated]],
          [['String', :foo]],
          [['Error', %i[AT PREAMBLE LBRACE STRING_LITERAL E_UNTERMINATED_STRING]]],
          [['Preamble']],
          ParseError,
          [['Error', %i[AT NAME LBRACE KEY NAME EQ STRING_LITERAL NAME NAME STRING_LITERAL E_UNBALANCED]]],
          [['Entry', :book, 'key', %i[author title]]],
          ParseError,
          [['String', :bar]]
        ]

        PARSE_OPTIONS.each do |options|
          expected.each_with_index do |result, index|
            it "parses section #{index} (#{ERROR_SECTIONS[index].lines.first.strip}) as before with #{options.inspect}" do
              if result == ParseError
                assert_raises(ParseError) { BibTeX.parse(ERROR_SECTIONS[index], options) }
              else
                assert_equal result, summary(BibTeX.parse(ERROR_SECTIONS[index], options))
              end
            end
          end

          it "still rejects the bad-syntax entries of errors.bib with #{options.inspect}" do
            missing_comma = "@book{key\n\tauthor = \"An Author\"\n}"
            missing_field_comma = "@book{key,\n\tauthor = \"An Author\"\n\ttitle = \"The Title\"\n}"

            assert_raises(ParseError) { BibTeX.parse(missing_comma, options) }
            assert_raises(ParseError) { BibTeX.parse(missing_field_comma, options) }
          end
        end

        it 'still rejects an entry without key unless allow_missing_keys is set' do
          input = "@book{\n\tauthor = \"An Author\"\n}"

          assert_raises(ParseError) { BibTeX.parse(input) }
          assert_raises(ParseError) { BibTeX.parse(input, strict: false) }
          assert_equal [['Entry', :book, 'an-a', [:author]]], summary(BibTeX.parse(input, allow_missing_keys: true))
        end
      end
    end
  end
end
