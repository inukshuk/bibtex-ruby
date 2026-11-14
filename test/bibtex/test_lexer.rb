require 'helper.rb'

module BibTeX
  class LexerTest < Minitest::Spec
    it 'correctly scans a string literal' do
      assert_equal [:AT, :STRING, :LBRACE, :NAME, :EQ, :STRING_LITERAL, :RBRACE, false], Lexer.new.analyse('@string{ x = "foo" }').symbols
    end

    it 'strips line breaks by default' do
      assert_equal [:STRING_LITERAL, 'foo bar'],
                   Lexer.new.analyse(%(@string{ x = "foo\nbar" })).stack[-3]
    end

    it 'strips whitespace after line breaks by default' do
      assert_equal [:STRING_LITERAL, 'foo bar'],
                   Lexer.new.analyse(%(@string{ x = "foo\n    bar" })).stack[-3]
    end

    it 'matches KEY tokens' do
      assert_equal [:AT, :NAME, :LBRACE, :KEY, :RBRACE, false],
                   Lexer.new.analyse('@misc{foo, }').symbols
    end

    it 'matches KEY tokens with non-ascii characters' do
      assert_equal [:AT, :NAME, :LBRACE, :KEY, :RBRACE, false],
                   Lexer.new.analyse('@misc{löwe, }').symbols
    end

    it 'matches KEY tokens after whitespace' do
      assert_equal [:AT, :NAME, :LBRACE, :KEY, :RBRACE, false],
                   Lexer.new.analyse('@misc{  foo, }').symbols
    end

    it 'matches KEY token with braces' do
      assert_equal [:AT, :NAME, :LBRACE, :KEY, :RBRACE, false],
                   Lexer.new.analyse('@misc{fo{o, }').symbols
      assert_equal [:AT, :NAME, :LBRACE, :KEY, :RBRACE, false],
                   Lexer.new.analyse('@misc{fo}o, }').symbols
      assert_equal [:AT, :NAME, :LBRACE, :KEY, :RBRACE, false],
                   Lexer.new.analyse('@misc{foo:{bar}, }').symbols
    end

    it "doesn't start a comment for types starting with but not equal @comment" do
      assert_equal [:AT, :NAME, :LBRACE, :KEY, :RBRACE, false],
                   Lexer.new.analyse('@commentary{staudinger, }').symbols
    end

    it "doesn't start a preamble for types starting with but not equal @preamble" do
      assert_equal [:AT, :NAME, :LBRACE, :NAME, :RBRACE, false],
                   Lexer.new.analyse('@preamblestring{ preamble }').symbols
    end
  end
end
