require 'helper'

module BibTeX
  class ParserTest < Minitest::Spec
    describe 'given a set of valid @entries' do
      before do
        @bib = Parser.new(debug: false).parse(File.read(Test.fixtures(:entry)))
      end

      it 'returns a Bibliography instance' do
        assert @bib
        refute_empty @bib
      end

      it 'parses all entries' do
        assert_equal 4, @bib.length
      end

      it 'parses the key values' do
        assert_equal %w[key:0 key:1 foo staudinger], @bib.map(&:key)
      end

      it 'should parse the entry types' do
        assert_equal %i[book article article commentary], @bib.map(&:type)
      end

      it 'should parse all values correctly' do
        assert_equal 'Poe, Edgar A.', @bib[:'key:0'].author.to_s
        assert_equal 'Hawthorne, Nathaniel', @bib[:'key:1'].author.to_s

        assert_equal '2003', @bib[:'key:0'].year
        assert_equal '2001', @bib[:'key:1'].year

        assert_equal 'American Library', @bib[:'key:0'].publisher
        assert_equal 'American Library', @bib[:'key:1'].publisher

        assert_equal %q(Selected \emph{Poetry} and `Tales'), @bib[:'key:0'].title
        assert_equal 'Tales and Sketches', @bib[:'key:1'].title
      end
    end

    describe 'key parsing' do
      it 'handles whitespace in keys' do
        input = '@Misc{George Martin06,title = {FEAST FOR CROWS}}'
        bib = Parser.new(debug: false, strict: false).parse(input)

        assert_equal 'George Martin06', bib.first.key
        assert bib[:'George Martin06']
      end

      it 'handles plus symbols in keys' do
        input = '@Misc{foo+bar,title = {Foobar}}'
        bib = Parser.new(debug: false, strict: false).parse(input)

        assert_equal 'foo+bar', bib.first.key
        assert bib[:'foo+bar']
      end

      it 'allows semicolons in keys' do
        input = '@Misc{Gomez;,title = {Foobar}}'
        bib = Parser.new(debug: false, strict: false).parse(input)

        assert_equal 'Gomez;', bib.first.key
        assert bib[:'Gomez;']
      end

      it 'allows quotes in keys' do
        input = %(@Misc{Gomez'1",title = {Foobar}})
        bib = Parser.new(debug: false, strict: false).parse(input)

        assert_equal %(Gomez'1"), bib.first.key
        assert bib[:"Gomez'1\""]
      end

      it 'fails when there is no cite-key' do
        input = '@misc{title = {Crime and Punishment}}'
        assert_raises ParseError do
          Parser.new(debug: false, strict: false).parse(input)
        end
      end

      it 'tolerates missing key with :allow_missing_keys set' do
        input = '@misc{title = {Crime and Punishment}}'

        assert_equal :misc, Parser.new(
          debug: false, strict: false, allow_missing_keys: true
        ).parse(input)[0].type
      end
    end

    describe 'field names containing spaces (#131)' do
      before do
        @input = '@article{a, title = {T}, Early Access Date = {{NOV}}, ' \
                 'Early Access Year = {{2017}}, year = 2017}'
      end

      it 'joins the words with underscores in non-strict mode' do
        entry = Parser.new(debug: false, strict: false).parse(@input)[0]

        assert_equal %i[title early_access_date early_access_year year], entry.fields.keys
        assert_equal '{NOV}', entry[:early_access_date].to_s
        assert_equal '{2017}', entry[:early_access_year].to_s
        assert_equal '2017', entry.year.to_s
      end

      it 'handles tabs and several spaces between the words' do
        input = "@article{a, Early  \tAccess Date = {NOV}}"
        entry = Parser.new(debug: false, strict: false).parse(input)[0]

        assert_equal [:early_access_date], entry.fields.keys
      end

      it 'does not join words across line breaks' do
        input = "@article{a, month = jan\n note = {x}}"
        assert_raises ParseError do
          Parser.new(debug: false, strict: false).parse(input)
        end
      end

      it 'produces BibTeX output that parses again' do
        entry = Parser.new(debug: false, strict: false).parse(@input)[0]
        reparsed = Parser.new(debug: false).parse(entry.to_s)[0]

        assert_equal entry.fields.keys, reparsed.fields.keys
        assert_equal '{NOV}', reparsed[:early_access_date].to_s
      end

      it 'still raises in strict mode' do
        assert_raises ParseError do
          Parser.new(debug: false).parse(@input)
        end
      end

      it 'still raises in strict mode via BibTeX.parse' do
        assert_raises ParseError do
          BibTeX.parse(@input)
        end
      end

      it 'is available via BibTeX.parse with strict: false' do
        entry = BibTeX.parse(@input, strict: false)[0]

        assert_equal '{NOV}', entry[:early_access_date].to_s
      end

      it 'leaves single-word field names and values unaffected' do
        input = '@article{a, title = {T}, month = jan, journal = foo # bar}'
        strict = Parser.new(debug: false).parse(input)[0]
        lenient = Parser.new(debug: false, strict: false).parse(input)[0]

        assert_equal strict.fields.keys, lenient.fields.keys
        assert_equal strict.to_s, lenient.to_s
      end
    end

    describe 'backslashes and escape sequences' do
      it 'leaves backslashes intact' do
        _(Parser.new.parse(%q(@misc{key, title = "a backslash: \"}))[0].title).must_be :==, 'a backslash: \\'
      end

      it 'parses LaTeX escaped quotes {"}' do
        _(Parser.new.parse('@misc{key, title = "{"}"}')[0].title).must_be :==, '{"}'
      end

      it 'parses complex LaTeX markup' do
        b = Parser.new.parse(<<-END)[0]
          @book{proust_1996,
            address = {Paris},
            author = {Proust, Jo\\"{e}lle},
            booktitle = {Perception et Intermodalit\\'{e}: Approches Actuelles De La Question De Molyneux},
            editor = {Proust, Jo\\"{e}lle},
            keywords = {Perception; Molyneux's Problem},
            publisher = {Presses Universitaires de France},
            title = {Perception et Intermodalit\\'{e}: Approches Actuelles De La Question De Molyneux},
            year = {1996}
          }
        END
        _(b.booktitle).must_be :==, "Perception et Intermodalit\\'{e}: Approches Actuelles De La Question De Molyneux"
        _(b.editor.to_s).must_be :==, 'Proust, Jo\"{e}lle'
      end
    end

    describe 'given a set of explicit and implicit comments' do
      before do
        @bib = Parser.new(debug: false, include: [:meta_content]).parse(File.read(Test.fixtures(:comment)))
      end

      it 'should parses all @comments' do
        assert_equal 2, @bib.comments.length
      end

      it 'should parses all meta content' do
        assert_equal 3, @bib.meta_contents.length
      end

      it 'should parse @comment content as string' do
        assert_equal ' A comment can contain pretty much anything ', @bib.comments[0].content
        assert_equal %(\n@string{ foo = "bar" }\n\n@string{ bar = "foo" }\n), @bib.comments[1].content
      end
    end

    describe 'given a set of @preambles' do
      before do
        @bib = Parser.new(debug: false).parse(File.read(Test.fixtures(:preamble)))
      end

      it 'should parse all @preambles' do
        assert_equal 3, @bib.preambles.length
      end

      it 'should parse all contents' do
        assert_equal 'This bibliography was created \\today', @bib.preambles[0].value.to_s
        assert_equal 'Bib\\TeX', @bib.preambles[1].value.to_s
        assert_equal '"Maintained by " # maintainer', @bib.preambles[2].value.to_s
      end
    end

    describe 'given an entry containing a multi-line literals' do
      before do
        @braces = %(@TechReport{key,\n  author = {Donald,\n     Duck}\n})
        @string = %(@TechReport{key,\n  author = "Donald,\n     Duck"\n})
      end

      it 'should parse string literals' do
        refute_nil Parser.new.parse(@string)[:key]
      end

      it 'should parse braced literals' do
        refute_nil Parser.new.parse(@braces)[:key]
      end
    end

    describe 'year values' do
      it 'parses non-numeric year literals' do
        assert_equal 'to appear',
                     Parser.new.parse('@article{x,  year = {to appear}}')['x'].year.to_s
      end

      it 'parses numeric year literals' do
        assert_equal 1993,
                     Parser.new.parse('@article{x,  year = { 1993 }}')['x'].year.to_i
      end
    end

    describe 'given an entry with missing commas between fields' do
      before do
        @level = BibTeX.log.level
        BibTeX.log.level = Logger::FATAL
      end

      after do
        BibTeX.log.level = @level
      end

      it 'raises a parser error' do
        _ do
          Parser.new.parse <<-END
            @book{book1,
             title = "Parse error because"
             author = "comma missing between title and author"
            }
          END
        end.must_raise(ParseError)
      end
    end

    describe 'given an entry with empty values' do
      it 'does not raise an error' do
        bib = BibTeX.parse <<-END
          @Incollection{test,
            author = {author},
            title = {title},
            editor = {},
          }
        END

        assert_equal 'author', bib[:test][:author]
        assert_equal 'title', bib[:test][:title]
        assert_equal '', bib[:test][:editor]
      end
    end

    describe 'anotations' do
      it 'handles annotation in fields' do
        bib = BibTeX.parse <<-END
          @article{foo,
            title={Some Title},
            author={SureName1, GivenName 1 and SureName2, GivenName 2},
            author+an={1=highlight}
          }
        END
        assert_equal '1=highlight', bib[:foo][:'author+an']
      end
    end
  end
end
