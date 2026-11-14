# frozen_string_literal: true

require 'helper'

module BibTeX
  # Identifier characters accepted by BibTeX::Lexer in
  # field names, @string names, macro references and keys.
  class IdentifiersTest < Minitest::Spec
    # Characters BibTeX allows in identifiers, most of which the lexer used
    # to reject.
    EXAMPLES = %w[a/b x;y p[1] a|b a^b a~b a<b> a@b].freeze

    MODES = {
      'strict' => {},
      'non-strict' => { strict: false },
      'strict with :strip_comments' => { strip_comments: true },
      'non-strict with :strip_comments' => { strict: false, strip_comments: true }
    }.freeze

    SLASH_KEY = 'DBLP:journals/dq/RossinK99'

    # Characters BibTeX excludes from identifiers that the lexer rejects today.
    REJECTED = %w[' ( )].freeze

    # Keys accepted before the identifier characters were widened, mapped to the key they are parsed into.
    EXISTING_KEYS = {
      'key:0' => 'key:0', 'a+b' => 'a+b', 'a;b' => 'a;b', %(a'b"c) => %(a'b"c),
      'fo{o' => 'fo{o', 'löwe' => 'löwe', '  spaced  ' => 'spaced', 'a.b-c_d!e$f?g&h*i' => 'a.b-c_d!e$f?g&h*i'
    }.freeze

    # Unterminated entries followed by the next object.
    UNTERMINATED = [
      "@misc{a, title = {t},\n@book{b, title={t}}",
      "@misc{a, title = {t}\n@book{b, title={t}}",
      "@misc{a, title = t\n@book {b, title={t}}"
    ].freeze

    # Long runs of '@a' that made lexing quadratic while a word starting
    # with '@' could extend over later '@'s (about 16 s for n = 50_000).
    RUN = 50_000
    ADVERSARIAL = {
      "'@' + 'a@' * n + ' {'" => "@#{'a@' * RUN} {",
      "an entry with '@a' * n + ' {'" => "@misc{k, #{'@a' * RUN} {",
      "an entry ending in '@a' * n" => "@misc{k, #{'@a' * RUN}",
      "a value of '@a' * n + ' x'" => "@misc{k, title = #{'@a' * RUN} x"
    }.freeze

    def parse(input, options = {})
      BibTeX.parse(input, options)
    end

    def tokens(input, options = {})
      Lexer.new(options).analyse(input).stack
    end

    describe 'identifier characters' do
      before { BibTeX.log.level = Logger::FATAL }
      after { BibTeX.log.level = Logger::WARN }

      MODES.each do |mode, options|
        describe "in #{mode} mode" do
          EXAMPLES.each do |name|
            it "lexes #{name} as a single field NAME token" do
              assert_equal [[:AT, '@'], [:NAME, 'misc'], [:LBRACE, '{'], [:KEY, 'k'],
                            [:NAME, name], [:EQ, '='], [:LBRACE, '{'], [:CONTENT, 'v'],
                            [:RBRACE, '}'], [:RBRACE, '}'], [false, '$end']],
                           tokens("@misc{k, #{name} = {v}}", options)
            end

            it "accepts #{name} as a field name" do
              bib = parse("@misc{k, #{name} = {v}, title = {T}}", options)

              assert_empty bib.errors
              assert_equal [name.to_sym, :title], bib['k'].fields.keys
              assert_equal 'v', bib['k'][name].to_s
            end

            it "accepts #{name} as a field name without surrounding spaces" do
              bib = parse("@misc{k,#{name}={v},title={T}}", options)

              assert_empty bib.errors
              assert_equal 'v', bib['k'][name].to_s
            end

            it "accepts #{name} as an @string name" do
              bib = parse("@string{ #{name} = {v} }", options)

              assert_empty bib.errors
              assert_equal [name.to_sym], bib.strings.keys
              assert_equal 'v', bib.strings[name.to_sym].value.to_s
            end

            it "accepts #{name} as a macro reference" do
              bib = parse("@string{ #{name} = {v} }\n@misc{k, title = #{name}}", options)

              assert_empty bib.errors
              assert_equal name.to_sym, bib['k'][:title].to_sym
              assert_equal 'v', bib.replace_strings['k'][:title].to_s
            end

            it "accepts #{name} as a macro reference in a concatenation" do
              bib = parse("@string{ #{name} = {v} }\n@misc{k, title = {a} # #{name} # \"b\"}", options)

              assert_empty bib.errors
              assert_equal 'avb', bib.replace_strings.join_strings['k'][:title].to_s
            end

            it "does not let #{name} swallow the next object" do
              bib = parse("@misc{k, #{name} = {v}}\n@misc{k2, title = {T}}", options)

              assert_empty bib.errors
              assert_equal %w[k k2], bib.entries.keys
            end

            it "writes #{name} out so that it parses again" do
              entry = parse("@misc{k, #{name} = {v}}", options)['k']
              reparsed = parse(entry.to_s, options)['k']

              assert_equal entry.fields, reparsed.fields
            end
          end

          it 'keeps non-ASCII letters in field names, @string names and references' do
            bib = parse("@string{ ä = {v} }\n@misc{k, ü = ä}", options)

            assert_empty bib.errors
            assert_equal %i[ü], bib['k'].fields.keys
            assert_equal :ä, bib['k'][:ü].to_sym
          end

          it 'combines non-ASCII letters with the new characters' do
            bib = parse("@string{ ä/b = {v} }\n@misc{k, ü<1> = ä/b}", options)

            assert_empty bib.errors
            assert_equal %i[ü<1>], bib['k'].fields.keys
            assert_equal :'ä/b', bib['k'][:'ü<1>'].to_sym
          end

          it 'still rejects 1a as a field name' do
            assert_raises(ParseError) { parse('@misc{k, 1a = {v}}', options) }
          end

          it 'still rejects 1a as an @string name' do
            assert_raises(ParseError) { parse('@string{ 1a = {v} }', options) }
          end

          it 'still rejects 1a as a macro reference' do
            assert_raises(ParseError) { parse('@misc{k, title = 1a}', options) }
          end

          it 'still lexes a number that follows = as a NUMBER' do
            assert_equal [:NUMBER, '1999'], tokens('@misc{k, year = 1999}', options)[-3]
          end

          it 'still splits names at the characters BibTeX excludes' do
            assert_equal [[:NAME, 'title'], [:EQ, '='], [:NAME, 'a'], [:SHARP, '#'], [:NAME, 'b'], [:COMMA, ','],
                          [:NAME, 'year'], [:EQ, '='], [:STRING_LITERAL, 'x'], [:RBRACE, '}']],
                         tokens('@misc{k,title=a#b,year="x"}', options)[4..-2]
          end

          REJECTED.each do |char|
            it "still does not accept #{char} inside a field name" do
              bib = parse("@misc{k, a#{char}b = {v}}", options)

              assert_nil bib['k']
              refute_empty bib.errors
            end
          end

          it "accepts the key #{SLASH_KEY}" do
            bib = parse("@article{#{SLASH_KEY}, title = {T}}", options)

            assert_empty bib.errors
            assert_equal [SLASH_KEY], bib.entries.keys
            assert_equal 'T', bib[SLASH_KEY].title.to_s
          end

          it 'accepts keys with / and allow_missing_keys' do
            bib = parse("@article{#{SLASH_KEY}, title = {T}}", options.merge(allow_missing_keys: true))

            assert_empty bib.errors
            assert_equal [SLASH_KEY], bib.entries.keys
          end

          it 'still accepts a missing key with allow_missing_keys' do
            bib = parse('@article{, title = {T}}', options.merge(allow_missing_keys: true))

            assert_empty bib.errors
            assert_equal 'T', bib.data[0].title.to_s
          end

          EXISTING_KEYS.each do |source, key|
            it "still accepts the key #{source.inspect}" do
              bib = parse("@misc{#{source}, title = {T}}", options)

              assert_empty bib.errors
              assert_equal [key], bib.entries.keys
            end
          end
        end
      end

      describe '% in names' do
        it 'is part of a field name, @string name and reference without :strip_comments' do
          bib = parse("@string{ a/b%c = {v} }\n@misc{k, x%y = a/b%c}")

          assert_empty bib.errors
          assert_equal [:'x%y'], bib['k'].fields.keys
          assert_equal :'a/b%c', bib['k'][:'x%y'].to_sym
        end

        it 'is part of a field name in non-strict mode without :strip_comments' do
          bib = parse('@misc{k, a/b%c = {v}}', strict: false)

          assert_equal [:'a/b%c'], bib['k'].fields.keys
        end

        it 'starts a comment after a new-style name with :strip_comments' do
          bib = parse("@string{ a/b = {v} }\n@misc{k, x;y% comment\n = a/b% comment\n}", strip_comments: true)

          assert_empty bib.errors
          assert_equal [:'x;y'], bib['k'].fields.keys
          assert_equal :'a/b', bib['k'][:'x;y'].to_sym
        end

        it 'starts a comment after a key with / and :strip_comments' do
          bib = parse("@article{% before\n#{SLASH_KEY}, % after\n title = {T} % end\n}", strip_comments: true)

          assert_empty bib.errors
          assert_equal [SLASH_KEY], bib.entries.keys
        end

        it 'stays inside the key without :strip_comments' do
          bib = parse('@misc{a%b, title = {T}}')

          assert_equal ['a%b'], bib.entries.keys
        end
      end

      describe '@ inside a name' do
        it 'does not start a new object in strict mode' do
          bib = parse("@misc{k, a@b = {v}, title = {T}}\n@misc{k2, title = {T2}}")

          assert_equal %w[k k2], bib.entries.keys
          assert_equal %i[a@b title], bib['k'].fields.keys
        end

        it 'does not start a new object in non-strict mode' do
          bib = parse("@misc{k,\n  a@b = {v},\n  title = c@d\n}\n@misc{k2, title = {T2}}", strict: false)

          assert_equal %w[k k2], bib.entries.keys
          assert_equal :'c@d', bib['k'][:title].to_sym
        end

        it 'still starts a new object at @ between objects in strict mode' do
          bib = parse('@misc{k, title = {T}} junk @misc{k2, title = {T2}}')

          assert_equal %w[k k2], bib.entries.keys
        end
      end

      describe '@ at the start of a name' do
        MODES.each do |mode, options|
          describe "in #{mode} mode" do
            it 'lexes @foo before = as a field NAME' do
              assert_equal [[:AT, '@'], [:NAME, 'misc'], [:LBRACE, '{'], [:KEY, 'k'],
                            [:NAME, '@foo'], [:EQ, '='], [:LBRACE, '{'], [:CONTENT, 'x'],
                            [:RBRACE, '}'], [:RBRACE, '}'], [false, '$end']],
                           tokens('@misc{k, @foo = {x}}', options)
            end

            it 'accepts @foo as a field name' do
              bib = parse("@misc{k, @foo = {x}, title = {T}}\n@misc{k2, title = {T2}}", options)

              assert_empty bib.errors
              assert_equal %w[k k2], bib.entries.keys
              assert_equal %i[@foo title], bib['k'].fields.keys
            end

            it 'accepts @m as an @string name and as a macro reference before , } and #' do
              bib = parse("@string{@m = {x}}\n@misc{k, a = @m, b = @m # {y}, c = {y} # @m}", options)

              assert_empty bib.errors
              assert_equal %i[@m], bib.strings.keys
              assert_equal :@m, bib['k'][:a].to_sym
              resolved = bib.replace_strings.join_strings['k']

              assert_equal 'x', resolved[:a].to_s
              assert_equal 'xy', resolved[:b].to_s
              assert_equal 'yx', resolved[:c].to_s
            end

            it 'still splits two entries separated by a trailing comma' do
              bib = parse("@misc{a, title={t}},\n@book{b, title={t}}", options)

              assert_empty bib.errors
              assert_equal %w[a b], bib.entries.keys
            end

            it 'still accepts a trailing comma inside an entry before the next one' do
              bib = parse("@misc{a, title={t},\n}\n@book{b, title={t}}", options)

              assert_empty bib.errors
              assert_equal %w[a b], bib.entries.keys
            end

            ADVERSARIAL.each do |label, input|
              it "lexes #{label} in linear time" do
                started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
                Lexer.new(options).analyse(input)
                elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

                # About 0.1 s when linear; generous for slow CI machines.
                assert_operator elapsed, :<, 5, "took #{elapsed.round(2)} s"
              end
            end

            it "ends a name that starts with '@' before the next '@'" do
              assert_equal [[:NAME, '@a'], [:EQ, '=']], tokens('@misc{k, @a = {x}}', options)[4, 2]
              refute_includes tokens('@misc{k, @a@b = {x}}', options), [:NAME, '@a@b']
              assert_equal [:NAME, 'a@b@c'], tokens('@misc{k, a@b@c = {x}}', options)[4]
            end

            UNTERMINATED.each do |input|
              it "still starts a new object after an unterminated entry: #{input.inspect}" do
                stack = tokens(input, options)
                start = stack.rindex([:AT, '@'])

                assert_equal [[:AT, '@'], [:NAME, 'book'], [:LBRACE, '{'], [:KEY, 'b']], stack[start, 4]
                refute(stack.any? { |type, value| type == :NAME && value.start_with?('@') })
              end
            end
          end
        end

        it 'skips TeX comments between @foo and = with :strip_comments' do
          bib = parse("@misc{k, @foo % comment\n = {x}}", strip_comments: true)

          assert_empty bib.errors
          assert_equal %i[@foo], bib['k'].fields.keys
        end

        it 'allows @ at the start of the last word of a non-strict multi-word name' do
          bib = parse('@misc{k, early @date = {v}}', strict: false)

          assert_equal %i[early_@date], bib['k'].fields.keys
        end
      end

      describe 'non-strict field names made of several words' do
        it 'uses the new characters in every word' do
          bib = parse('@misc{k, a/b x;y p[1] = {v}, title = {T}}', strict: false)

          assert_empty bib.errors
          assert_equal %i[a/b_x;y_p[1] title], bib['k'].fields.keys
        end

        EXAMPLES.each do |name|
          it "joins words containing #{name}" do
            bib = parse("@misc{k, early #{name}\tdate = {v}}", strict: false)

            assert_equal [:"early_#{name}_date"], bib['k'].fields.keys
          end
        end

        it 'combines with :strip_comments' do
          bib = parse("@misc{k, % a<b> c = {commented out}\n a|b c~d = {v} % comment\n}", strict: false, strip_comments: true)

          assert_equal [:'a|b_c~d'], bib['k'].fields.keys
        end

        it 'keeps % in the words without :strip_comments' do
          bib = parse('@misc{k, a%b c^d = {v}}', strict: false)

          assert_equal [:'a%b_c^d'], bib['k'].fields.keys
        end

        it 'still raises for several words in strict mode' do
          assert_raises(ParseError) { parse('@misc{k, a/b x;y = {v}}') }
        end
      end
    end
  end
end
