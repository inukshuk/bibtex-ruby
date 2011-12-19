require 'helper.rb'

module BibTeX
  class LexerTest < MiniTest::Spec

    it 'correctly scans a string literal' do
      assert_equal Lexer.new.analyse(%q(@string{ x = "foo" })).symbols, [:AT,:STRING,:LBRACE,:NAME,:EQ,:STRING_LITERAL,:RBRACE,false]
    end

    it 'strips line breaks by default' do
      Lexer.new.analyse(%Q(@string{ x = "foo\nbar" })).stack[-3].must_be :==,
        [:STRING_LITERAL, 'foo bar']
    end

    it 'strips whitespace after line breaks by default' do
      Lexer.new.analyse(%Q(@string{ x = "foo\n    bar" })).stack[-3].must_be :==,
        [:STRING_LITERAL, 'foo bar']
    end
    
  end
end