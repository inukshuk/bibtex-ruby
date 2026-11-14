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
    # '@comment{BibDesk Static Groups{' (#138).
    BIBDESK_STATIC_GROUPS = <<~BIB.freeze
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

    describe 'given a BibDesk Static Groups comment (#138)' do
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
