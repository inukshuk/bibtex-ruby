require 'helper.rb'

module BibTeX
  class LexerTest < Minitest::Spec
    it 'correctly scans a string literal' do
      assert_equal Lexer.new.analyse('@string{ x = "foo" }').symbols, [:AT, :STRING, :LBRACE, :NAME, :EQ, :STRING_LITERAL, :RBRACE, false]
    end

    it 'strips line breaks by default' do
      _(Lexer.new.analyse(%(@string{ x = "foo\nbar" })).stack[-3]).must_be :==,
                                                                        [:STRING_LITERAL, 'foo bar']
    end

    it 'strips whitespace after line breaks by default' do
      _(Lexer.new.analyse(%(@string{ x = "foo\n    bar" })).stack[-3]).must_be :==,
                                                                            [:STRING_LITERAL, 'foo bar']
    end

    it 'matches KEY tokens' do
      _(Lexer.new.analyse('@misc{foo, }').symbols).must_be :==, [:AT, :NAME, :LBRACE, :KEY, :RBRACE, false]
    end

    it 'matches KEY tokens with non-ascii characters' do
      _(Lexer.new.analyse('@misc{löwe, }').symbols).must_be :==, [:AT, :NAME, :LBRACE, :KEY, :RBRACE, false]
    end

    it 'matches KEY tokens after whitespace' do
      _(Lexer.new.analyse('@misc{  foo, }').symbols).must_be :==, [:AT, :NAME, :LBRACE, :KEY, :RBRACE, false]
    end

    it 'matches KEY tokens with braces' do
      _(Lexer.new.analyse('@misc{foo:{123}, }').symbols).must_be :==, [:AT, :NAME, :LBRACE, :KEY, :RBRACE, false]
    end

    it "doesn't start a comment for types starting with but not equal @comment" do
      _(Lexer.new.analyse('@commentary{staudinger, }').symbols).must_be :==, [:AT, :NAME, :LBRACE, :KEY, :RBRACE, false]
    end

    it "doesn't start a preamble for types starting with but not equal @preamble" do
      _(Lexer.new.analyse('@preamblestring{ preamble }').symbols).must_be :==, [:AT, :NAME, :LBRACE, :NAME, :RBRACE, false]
    end
  end
end
