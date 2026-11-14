# frozen_string_literal: true

require 'helper'

module BibTeX
  class ElementTest < Minitest::Spec
    describe '.parse' do
      it 'accepts a BibTeX string' do
        _(Element.parse('@misc{x,},@misc{y,}').length).must_be :==, 2
      end

      it 'accepts an Element' do
        _(Element.parse(Comment.new('blah')).length).must_be :==, 1
      end

      it 'accepts a Hash and returns an Entry' do
        _(Element.parse(bibtex_type: :book)[0].type).must_be :==, :book
      end

      it 'accepts an array of hashes' do
        _(Element.parse([{ bibtex_type: :book }, { bibtex_type: :misc }])[1].type).must_be :==, :misc
      end

      it 'raises an ArgumentError for unsupported input' do
        assert_raises(ArgumentError) { Element.parse(42) }
      end
    end

    describe 'generic behaviour' do
      before { @element = Comment.new('blah') }

      it 'has the default no-op implementations' do
        base = Element.new

        assert_equal '', base.content
        assert_equal [], base.values_at(:a)
        assert_equal [], base.names
        assert_same base, base.replace
        assert_same base, base.join
        assert_equal 'element|', base.digest
      end

      it 'derives its type from the class name' do
        assert_equal :comment, @element.type
        assert_equal :meta_content, MetaContent.new.type
      end

      it 'answers type queries' do
        assert_predicate @element, :comment?
        refute_predicate @element, :string?
        assert @element.type?(:comment)
      end

      it 'answers type queries for classes' do
        assert @element.type?(Comment)
        assert @element.type?(Element)
        refute @element.type?(String)
      end

      it 'has an id' do
        assert_kind_of ::String, @element.id
        refute_empty @element.id
      end

      it 'inspects itself' do
        assert_equal '#<BibTeX::Comment blah>', @element.inspect
        assert_equal '#<BibTeX::Comment a b>', Comment.new("a\nb").inspect
      end

      it 'compares equal elements as equal' do
        other = Comment.new('a')

        assert_equal 0, Comment.new('a').<=>(other)
      end

      it 'orders elements by string' do
        assert_equal(-1, Comment.new('a') <=> Comment.new('b'))
      end

      it 'does not compare with other types' do
        assert_nil Comment.new('a') <=> 5
      end

      it 'serialises to hash, yaml, json and xml' do
        assert_equal({ comment: 'blah' }, @element.to_hash)
        assert_equal({ comment: 'blah' }.to_yaml, @element.to_yaml)
        assert_equal '{"comment":"blah"}', @element.to_json
        assert_equal '{"comment":"blah"}', @element.to_json(:something)
        assert_equal 'blah', @element.to_xml.text
      end

      it 'names its xml element after its type' do
        assert_equal '<comment>blah</comment>', @element.to_xml.to_s
      end

      it 'tracks its bibliography' do
        bib = Bibliography.new

        assert_same @element, @element.added_to_bibliography(bib)
        assert_same bib, @element.bibliography
        assert_same @element, @element.removed_from_bibliography(bib)
        assert_nil @element.bibliography
      end
    end

    describe '#matches?' do
      before do
        @bib = BibTeX.parse('@book{a, title = {Foo}, year = {2001}} @article{b, title = {Bar}}')
        @a = @bib['a']
        @b = @bib['b']
      end

      it 'matches empty queries' do
        assert @a.matches?(nil)
        assert @a.matches?('')
      end

      it 'matches by symbol id, element, regexp and /regexp/ string' do
        assert @a.matches?(:a)
        refute @a.matches?(:b)
        assert @a.matches?(@a)
        assert @a.matches?(/Foo/)
        assert @a.matches?('/Foo/')
        refute @a.matches?('/Bar/')
      end

      it 'matches by plain id' do
        assert @a.matches?('a')
        refute @a.matches?('b')
      end

      it 'matches by type, wildcard and negation' do
        assert @a.matches?('@book')
        refute @a.matches?('@article')
        assert @a.matches?('@*')
        assert @a.matches?('!@article')
        refute @a.matches?('!@book')
        assert @a.matches?('@book[]')
      end

      it 'supports equality and alternatives' do
        assert @a.matches?('@book[year=2001]')
        assert @a.matches?('@book[year = 2001, title=Foo]')
        assert @a.matches?('@book[year=1999 || year=2001]')
        refute @a.matches?('@book[year=1999]')
      end

      it 'supports property existence' do
        assert @a.matches?('@book[title]')
        refute @a.matches?('@book[author]')
      end

      it 'supports inequality' do
        assert @a.matches?('@book[year!=1999]')
        assert @a.matches?('@book[year/=1999]')
        refute @a.matches?('@book[year!=2001]')
      end

      it 'supports prefix conditions' do
        assert @a.matches?('@book[title^=F]')
        refute @a.matches?('@book[author^=F]')
      end

      it 'supports regular expression conditions' do
        assert @a.matches?('@book[title~=o+]')
        refute @a.matches?('@book[author~=o]')
      end

      it 'supports =~ as an alias for ~=' do
        assert @a.matches?('@book[title=~o+]')
        assert @a.matches?('@book[title =~ ^F]')
        refute @a.matches?('@book[title=~Z]')
        refute @a.matches?('@book[author=~o]')
      end

      it 'supports negated regular expression conditions' do
        assert @a.matches?('@book[title!~Z]')
        assert @a.matches?('@book[author!~Z]')
        refute @a.matches?('@book[title!~Foo]')
      end

      it 'supports numeric comparisons' do
        assert @a.matches?('@book[year>2000]')
        assert @a.matches?('@book[year>=2001]')
        assert @a.matches?('@book[year<2002]')
        assert @a.matches?('@book[year<=2001]')
        refute @a.matches?('@book[year>2001]')
      end

      it 'supports string comparisons' do
        refute @a.matches?('@book[author>2001]')
        assert @a.matches?('@book[title>Fa]')
      end

      it 'handles the type property' do
        refute @a.matches?('@book[type=x]')
        assert @a.matches?('@book[type!=x]')
      end

      it 'supports meets_all?' do
        assert @a.meets_all?('year=2001', 'title=Foo')
        refute @a.meets_all?('year=2001', 'title=Bar')
      end

      it 'supports meets_any?' do
        assert @a.meets_any?('year=1999', 'title=Foo')
        refute @a.meets_any?('year=1999', 'title=Bar')
      end

      it 'supports the aliases of the meets methods' do
        assert @a.meet_all?('year=2001')
        assert @a.meet_any?('year=2001')
        assert @a.meets?(['year=2001'])
        assert @a.meet?(['year=2001'])
      end

      it 'treats an empty condition as met' do
        assert @a.meets_all?('')
      end

      it 'does not meet conditions on non-entries' do
        refute Comment.new('x').meets_all?('year')
      end
    end
  end

  class StringTest < Minitest::Spec
    describe 'a @string' do
      before { @string = String.new(:foo, 'bar') }

      it 'exposes its key and value' do
        assert_equal :foo, @string.key
        assert_equal :bar, @string[:foo].to_s.to_sym
        assert_nil @string[:other]
      end

      it 'serialises' do
        assert_equal 'foo = "bar"', @string.content
        assert_equal %(@string{ foo = "bar" }\n), @string.to_s
        assert_equal({ string: { foo: '"bar"' } }, @string.to_hash)
      end

      it 'serialises to xml' do
        xml = @string.to_xml

        assert_equal 'string', xml.name
        assert_equal 'foo', xml.elements['key'].text
        assert_equal '"bar"', xml.elements['value'].text
      end

      it 'yields itself on creation' do
        yielded = nil
        string = String.new(:a, 'b') { |s| yielded = s }

        assert_same string, yielded
      end

      it 'updates its bibliography when the key changes' do
        bib = Bibliography.new
        bib << @string
        @string.key = :baz

        assert_equal :baz, @string.key
        assert_same @string, bib.strings[:baz]
        refute bib.strings.key?(:foo)
      end

      it 'registers with and unregisters from a bibliography' do
        bib = Bibliography.new
        bib << @string

        assert_same @string, bib.strings[:foo]
        bib.delete(@string)

        assert_nil bib.strings[:foo]
      end
    end
  end

  class MetaContentTest < Minitest::Spec
    it 'returns its content verbatim' do
      meta = MetaContent.new('hello')

      assert_equal 'hello', meta.to_s
      assert_equal 'hello', meta.content
    end
  end

  class PreambleTest < Minitest::Spec
    describe 'a new preamble instance' do
      before do
        @preamble = Preamble.new
      end

      it 'should not be nil' do
        assert @preamble
      end
    end

    describe 'given a set of @preambles' do
      before do
        @bib = BibTeX.open(Test.fixtures(:preamble))
        @preambles = @bib.preambles
      end

      it 'should support round-trips of all parsed preambles' do
        assert_equal %(@preamble{ "This bibliography was created \\today" }\n), @preambles[0].to_s
        assert_equal %(@preamble{ "Bib\\TeX" }\n), @preambles[1].to_s
        assert_equal %(@preamble{ "Maintained by " # maintainer }\n), @preambles[2].to_s
      end

      it 'should support string replacement of preamble contents' do
        assert_equal '"Maintained by " # maintainer', @preambles[2].value.to_s
        @bib.replace_strings

        assert_equal '"Maintained by " # "Myself"', @preambles[2].value.to_s
        @bib.join_strings

        assert_equal 'Maintained by Myself', @preambles[2].value.to_s
      end
    end
  end
end

module BibTeX
  class CommentTest < Minitest::Spec
    # BibDesk stores library state in @comment blocks and expects to find
    # them again verbatim, e.g. by the literal prefix
    # '@comment{BibDesk Static Groups{'.
    BIBDESK_STATIC_GROUPS = <<~BIB
      @comment{BibDesk Static Groups{
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <array>
      \t<dict>
      \t\t<key>group name</key>
      \t\t<string>Reading List</string>
      \t\t<key>keys</key>
      \t\t<string>knuth1984,lamport1994</string>
      \t</dict>
      </array>
      </plist>
      }}
    BIB

    describe 'a new comment instance' do
      it 'serialises its content without padding' do
        assert_equal "@comment{ foo }\n", Comment.new(' foo ').to_s
        assert_equal "@comment{foo}\n", Comment.new('foo').to_s
      end
    end

    describe 'given a BibDesk Static Groups comment' do
      it 'round-trips a bibliography with LF line breaks byte-for-byte' do
        bib = BibTeX.parse(BIBDESK_STATIC_GROUPS)

        assert_equal 1, bib.comments.length
        assert_equal BIBDESK_STATIC_GROUPS, bib.to_s
        assert bib.to_s.start_with?('@comment{BibDesk Static Groups{')
      end

      it 'round-trips a comment with CRLF line breaks byte-for-byte' do
        input = BIBDESK_STATIC_GROUPS.chomp.gsub("\n", "\r\n")
        comment = BibTeX.parse(input).comments[0]

        assert_equal "#{input}\n", comment.to_s
        assert_includes comment.content, "\r\n\t\t<key>group name</key>\r\n"
      end

      it 'round-trips the comment content unchanged' do
        content = BIBDESK_STATIC_GROUPS.chomp.delete_prefix('@comment{').delete_suffix('}')

        assert_equal content, BibTeX.parse(BIBDESK_STATIC_GROUPS).comments[0].content
      end
    end
  end
end
