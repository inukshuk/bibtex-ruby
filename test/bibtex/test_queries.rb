# frozen_string_literal: true

require 'helper'

module BibTeX
  class QueriesTest < Minitest::Spec
    before do
      @bib = BibTeX.parse <<~'BIB'
        @string{ pragprog = "The Pragmatic Bookshelf" }
        @preamble{ "This bibliography was created \today" }
        @comment{ a comment }
        @article{maksimovic,
          author = {Maksimovi\'{c}, Petar},
          title = {Regular expressions with commas, really},
          year = 2012
        }
        @book{ruby,
          author = {Thomas, Dave and Fowler, Chad and Hunt, Andy},
          title = {Programming Ruby},
          publisher = pragprog,
          year = 2009,
          url = {https://pragprog.com}
        }
        @book{rails,
          author = {Thomas, Dave and Hansson, David Heinemeier},
          title = {Agile Web Development with Rails},
          year = 2008
        }
        @proceedings{proc,
          title = {Proceedings of Something},
          year = 2011
        }
        @inproceedings{talk,
          crossref = {proc},
          author = {Poe, Edgar},
          title = {A Talk},
          year = 2011
        }
      BIB
    end

    def keys(elements)
      elements.map { |e| e.key.to_s }
    end

    describe 'Entry#deconstruct_keys' do
      it 'returns type, key and all fields as strings' do
        values = @bib['maksimovic'].deconstruct_keys(nil)

        assert_equal({ type: :article, key: 'maksimovic', author: "Maksimovi\\'{c}, Petar",
                       title: 'Regular expressions with commas, really', year: '2012' }, values)
      end

      it 'returns only the requested keys' do
        assert_equal({ type: :book, year: '2009' }, @bib['ruby'].deconstruct_keys(%i[type year]))
        assert_equal({ key: 'ruby' }, @bib['ruby'].deconstruct_keys([:key]))
      end

      it 'omits requested fields the entry does not have' do
        assert_equal({ year: '2008' }, @bib['rails'].deconstruct_keys(%i[year url]))
      end

      it 'converts names to strings' do
        author = @bib['ruby'].deconstruct_keys([:author])[:author]

        assert_instance_of ::String, author
        assert_equal 'Thomas, Dave and Fowler, Chad and Hunt, Andy', author
      end

      it 'includes fields inherited via crossref' do
        assert_equal 'Proceedings of Something', @bib['talk'].deconstruct_keys([:booktitle])[:booktitle]
        assert_includes @bib['talk'].deconstruct_keys(nil).keys, :booktitle
      end

      it 'keeps the BibTeX type and key when the entry has type or key fields' do
        entry = BibTeX.parse('@phdthesis{t, type = {Habilitation}, key = {sortkey}}')['t']

        assert_equal({ type: :phdthesis, key: 't' }, entry.deconstruct_keys(%i[type key]))
      end
    end

    describe 'Element#deconstruct_keys' do
      it 'exposes the type of other elements' do
        assert_equal({ type: :preamble }, @bib.preambles[0].deconstruct_keys(nil))
        assert_equal({ type: :comment }, @bib.comments[0].deconstruct_keys(nil))
      end

      it 'exposes key and value of @string elements' do
        assert_equal({ type: :string, key: 'pragprog', value: 'The Pragmatic Bookshelf' },
                     @bib.strings[:pragprog].deconstruct_keys(nil))
        assert_equal({ key: 'pragprog' }, @bib.strings[:pragprog].deconstruct_keys([:key]))
      end
    end

    describe 'pattern matching' do
      it 'matches strings' do
        assert_equal %w[ruby], keys(@bib.select { |e| e in { year: '2009' } })
      end

      it 'matches regular expressions' do
        assert_equal %w[ruby rails], keys(@bib.select { |e| e in { author: /Thomas/ } })
      end

      it 'matches string ranges' do
        assert_equal %w[maksimovic proc talk], keys(@bib.select { |e| e in { year: '2010'.. } })
      end

      it 'matches alternatives' do
        found = @bib.select { |e| e in { type: :article | :inproceedings, year: '2010'.. } }

        assert_equal %w[maksimovic talk], keys(found)
      end

      it 'works in case/in' do
        result = case @bib['ruby']
                 in { type: :book, title: /Ruby/ => title } then title
                 end

        assert_equal 'Programming Ruby', result
      end
    end

    describe 'hash queries' do
      it 'selects by type given as a String' do
        assert_equal %w[ruby rails], keys(@bib.query(type: 'book'))
      end

      it 'selects all entries with type :entry' do
        assert_equal %w[maksimovic ruby rails proc talk], keys(@bib.query(type: :entry))
      end

      it 'ignores conditions with keys that are not names' do
        assert_empty @bib.query(1 => 'x')
      end

      it 'selects by type' do
        assert_equal %w[ruby rails], keys(@bib.query(type: :book))
        assert_equal %w[ruby rails], keys(@bib.q(type: :book))
      end

      it 'combines conditions' do
        assert_equal %w[ruby], keys(@bib.query(type: :book, author: /Fowler/))
      end

      it 'accepts the :all, :first and :none selectors' do
        assert_equal %w[ruby rails], keys(@bib.query(:all, type: :book))
        assert_equal 'maksimovic', @bib.query(:first, year: '2010'..'2015').key
        assert_nil @bib.query(:first, year: '1999')

        rest = @bib.query(:none, type: :book)

        assert_equal @bib.length - 2, rest.length
        refute(rest.any? { |e| e.has_type?(:book) })
      end

      it 'replaces numeric comparisons with string ranges' do
        assert_equal %w[ruby rails], keys(@bib.query(type: :book, year: ..'2009'))
      end

      it 'treats an array as any of its patterns' do
        assert_equal %w[maksimovic ruby rails], keys(@bib.query(type: %i[book article]))
        assert_equal %w[ruby talk], keys(@bib.query(author: [/Fowler/, /Poe/]))
      end

      it 'never matches a missing field' do
        assert_equal %w[ruby], keys(@bib.query(url: //))
        assert_empty @bib.query(isbn: /./)
      end

      it 'matches a missing field with an explicit nil pattern' do
        assert_equal %w[rails], keys(@bib.query(type: :book, url: nil))
      end

      it 'matches a present field with a class pattern' do
        assert_equal %w[talk], keys(@bib.query(type: :inproceedings, booktitle: ::String))
      end

      it 'accepts string keys' do
        assert_equal %w[ruby], keys(@bib.query('type' => :book, 'year' => '2009'))
      end

      it 'can be refined with a block' do
        assert_equal %w[ruby], keys(@bib.query(type: :book) { |e| e.year.to_i > 2008 })
      end

      it 'selects non-entry elements by type' do
        assert_equal [@bib.strings[:pragprog]], @bib.query(type: :string)
        assert_equal @bib.comments, @bib.query(type: :comment)
      end

      it 'returns everything for an empty hash' do
        assert_equal @bib.data, @bib.query({})
      end

      it 'is supported by Bibliography#[]' do
        assert_equal %w[ruby rails], keys(@bib[type: :book])
        assert_equal 'ruby', @bib[:first, { type: :book }].key
      end

      it 'is supported by Bibliography#delete' do
        @bib.delete(type: :book, year: '2008')

        assert_nil @bib['rails']
        refute_nil @bib['ruby']
      end

      it 'is supported by Element#matches? and ===' do
        assert @bib['ruby'].matches?(type: :book, year: '2009')
        refute @bib['ruby'].matches?(type: :article)
        assert_operator @bib['ruby'], :===, { type: :book }
      end

      describe 'with a comma and escapes in the value (#126)' do
        it 'finds the entry via a regular expression' do
          assert_equal %w[maksimovic], keys(@bib.query(author: /Maksimovi\\'\{c\}/))
        end

        it 'finds the entry via the exact string' do
          assert_equal %w[maksimovic], keys(@bib.query(author: %q(Maksimovi\'{c}, Petar)))
        end

        it 'finds values containing commas' do
          assert_equal %w[maksimovic], keys(@bib.query(title: 'Regular expressions with commas, really'))
        end
      end
    end

    describe 'key and regexp lookups' do
      it 'keep working as before' do
        assert_equal 'ruby', @bib['ruby'].key
        assert_equal 'ruby', @bib[:ruby].key
        assert_equal %w[ruby rails], keys(@bib[/Thomas/])
        assert_nil @bib['missing']
      end
    end

    describe 'string selector deprecation' do
      before do
        @deprecated = Warning[:deprecated]
        Deprecation.reset!
      end

      after do
        Warning[:deprecated] = @deprecated
        Deprecation.silence!
      end

      it 'does not warn when deprecation warnings are disabled' do
        Warning[:deprecated] = false

        assert_silent { @bib.query('@book') }
      end

      it 'warns once, pointing at the caller' do
        Warning[:deprecated] = true
        line = __LINE__ + 1
        _, err = capture_io { @bib.query('@book[year=2009]') }

        assert_match(/string selectors .* are deprecated/, err)
        assert_includes err, 'will be removed in BibTeX-Ruby 7.0'
        assert_includes err, "#{__FILE__}:#{line}: warning:"

        _, err = capture_io { @bib['@article'] }

        assert_empty err
      end

      it 'points at the caller of Bibliography#[] and Element#matches?' do
        Warning[:deprecated] = true
        line = __LINE__ + 1
        _, err = capture_io { @bib['@article'] }

        assert_includes err, "#{__FILE__}:#{line}: warning:"

        Deprecation.reset!
        line = __LINE__ + 1
        _, err = capture_io { @bib['ruby'].matches?('@book') }

        assert_includes err, "#{__FILE__}:#{line}: warning:"
      end

      it 'does not warn for hash queries, keys or regular expressions' do
        Warning[:deprecated] = true

        assert_silent do
          @bib.query(type: :book)
          @bib['ruby']
          @bib[/Thomas/]
          @bib.each_entry.to_a
          @bib.find_by_type(:book)
          @bib['proc'].children
          @bib.to_citeproc
          @bib.replace
        end
      end
    end
  end
end
